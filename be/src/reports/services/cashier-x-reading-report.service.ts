import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../../sales-orders/entities/sales-order-discount.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { CashierXReading } from '../entities/cashier-x-reading.entity';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import {
  CashierXReadingHistoryItemDto,
  CashierXReadingResponseDto,
} from '../dto/cashier-x-reading-response.dto';
import {
  CashierXReadingReportMapper,
  CashierXReadingRawInputs,
} from '../mapper/cashier-x-reading-report.mapper';
import { BaseReportService } from './base-report.service';
import type { PaginatedQueryParams, PaginatedResult } from '../../utils/pagination/interfaces';
import type {
  CashierPaymentLedgerRawRow,
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  NameAmountRawRow,
} from '../reports.interface';
import { ReportClosedEvent, ReportEvents } from '../events/report-closed.event';

/**
 * X Reading: read-only snapshot of the current cashier's own unreported transactions (from
 * their first not-yet-reported transaction through now), on their assigned terminal. Never
 * resets counters, closes a shift, or mutates any data.
 */
@Injectable()
export class CashierXReadingReportService extends BaseReportService<
  User,
  CashierXReadingResponseDto
> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(CashierXReading)
    private readonly cashierXReadingRepository: Repository<CashierXReading>,
    private readonly eventEmitter: EventEmitter2,
  ) {
    super();
  }

  async getReport(causer: User): Promise<CashierXReadingResponseDto> {
    return this.computeReport(causer.id, new Date(), this.salesOrderRepository.manager);
  }

  /**
   * Closes the current unreported window: recomputes the report, persists it as a snapshot, and
   * marks every covered transaction `done_x_reading = true` with `x_reading_id` set to the new
   * report's id — all inside one transaction so the persisted snapshot and the marked rows
   * always agree.
   */
  async closeReport(causer: User): Promise<CashierXReadingResponseDto> {
    const result = await this.salesOrderRepository.manager.transaction(async (manager) => {
      const requestTime = new Date();
      const dto = await this.computeReport(causer.id, requestTime, manager);

      if (dto.periodStart == null) {
        throw new ConflictException('No unreported transactions to close for this cashier.');
      }

      const reportRepository = manager.getRepository(CashierXReading);
      const report = await reportRepository.save(
        reportRepository.create({
          cashier: { id: causer.id } as User,
          periodStart: new Date(dto.periodStart),
          periodEnd: dto.periodEnd ? new Date(dto.periodEnd) : null,
          generatedAt: requestTime,
          snapshot: dto as unknown as Record<string, unknown>,
        }),
      );

      await manager.query(
        `UPDATE sales_orders
         SET done_x_reading = true, x_reading_id = $1
         WHERE created_by = $2 AND done_x_reading = false AND so_date <= $3`,
        [report.id, causer.id, requestTime],
      );

      return { ...dto, id: report.id };
    });

    this.eventEmitter.emit(
      ReportEvents.REPORT_CLOSED,
      new ReportClosedEvent('x_reading', String(result.id), result as unknown as Record<string, unknown>),
    );
    return result;
  }

  async getHistory(
    causer: User,
    query: PaginatedQueryParams,
  ): Promise<PaginatedResult<CashierXReadingHistoryItemDto>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;

    const [rows, total] = await this.cashierXReadingRepository
      .createQueryBuilder('r')
      .where('r.cashier_id = :cashierId', { cashierId: causer.id })
      .orderBy('r.generated_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data: rows.map(toHistoryItemDto), total, page, limit };
  }

  async getHistoryDetail(causer: User, id: string): Promise<CashierXReadingResponseDto> {
    const report = await this.cashierXReadingRepository.findOne({
      where: { id, cashier: { id: causer.id } },
    });
    if (report == null) {
      throw new NotFoundException(`Cashier X-Reading ${id} not found.`);
    }
    return { ...(report.snapshot as unknown as CashierXReadingResponseDto), id: report.id };
  }

  private async computeReport(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierXReadingResponseDto> {
    const [
      currentUser,
      paymentRows,
      paymentLedgerRows,
      discountRows,
      salesTotals,
      voided,
      refunded,
      tax,
      vatExempt,
      quantity,
    ] = await Promise.all([
      manager.findOne(User, { where: { id: userId }, relations: ['posTerminal'] }),
      this.getPaymentBreakdown(userId, requestTime, manager),
      this.getPaymentLedgerEntries(userId, requestTime, manager),
      this.getDiscountBreakdown(userId, requestTime, manager),
      this.getSalesTotals(userId, requestTime, manager),
      this.getVoidedCount(userId, requestTime, manager),
      this.getRefundedCount(userId, requestTime, manager),
      this.getTax(userId, requestTime, manager),
      this.getVatExemptSales(userId, requestTime, manager),
      this.getQuantitySold(userId, requestTime, manager),
    ]);

    if (currentUser == null) {
      throw new Error(`User ${userId} not found while generating X Reading`);
    }

    const raw: CashierXReadingRawInputs = {
      currentUser,
      paymentRows,
      paymentLedgerRows,
      discountRows,
      salesTotals,
      voided,
      refunded,
      tax,
      vatExempt,
      quantity,
    };
    return CashierXReadingReportMapper.toDto(raw);
  }

  private getPaymentBreakdown(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<NameAmountRawRow[]> {
    return manager
      .createQueryBuilder(Payment, 'p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'amount',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy(`COALESCE(p.payment_method_name, p.payment_method::text)`)
      .getRawMany<NameAmountRawRow>();
  }

  private getPaymentLedgerEntries(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierPaymentLedgerRawRow[]> {
    return manager
      .createQueryBuilder(Payment, 'p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect('p.payment_date', 'paymentDate')
      .addSelect('p.transaction_reference', 'transactionReference')
      .addSelect('p.amount_paid - p.change', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .orderBy('p.payment_date', 'ASC')
      .getRawMany<CashierPaymentLedgerRawRow>();
  }

  private getDiscountBreakdown(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<NameAmountRawRow[]> {
    return manager
      .createQueryBuilder(SalesOrderDiscount, 'sod')
      .innerJoin('sod.discount', 'd')
      .innerJoin('sod.salesOrder', 'so')
      .select('d.name', 'name')
      .addSelect('SUM(sod.applied_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy('d.name')
      .getRawMany<NameAmountRawRow>();
  }

  private getSalesTotals(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierSalesTotalsRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .addSelect('SUM(so.discount_amount)', 'totalDiscounts')
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('MIN(so.so_date)', 'periodStart')
      .addSelect('MAX(so.so_date)', 'periodEnd')
      .addSelect('AVG(so.final_total_amount)', 'averageSale')
      .addSelect('MAX(so.final_total_amount)', 'highestSale')
      .addSelect('MIN(so.final_total_amount)', 'lowestSale')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierSalesTotalsRawRow>();
  }

  private getVoidedCount(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierVoidedRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('COUNT(so.id)', 'voidedTransactions')
      .where('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierVoidedRawRow>();
  }

  private getRefundedCount(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierRefundedRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('COUNT(so.id)', 'refundedTransactions')
      .where('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere('EXISTS (SELECT 1 FROM refunds r WHERE r.original_sales_order_id = so.id)')
      .getRawOne<CashierRefundedRawRow>();
  }

  private getTax(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierTaxRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.vat_exclusive_amount)', 'vatSales')
      .addSelect('SUM(soi.vat_amount)', 'vatAmount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere(
        `NOT EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierTaxRawRow>();
  }

  private getVatExemptSales(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierVatExemptRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('SUM(so.final_total_amount)', 'vatExemptSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere(
        `EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierVatExemptRawRow>();
  }

  private getQuantitySold(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierQuantityRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.qty)', 'totalQuantitySold')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_x_reading = :doneXReading', { doneXReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierQuantityRawRow>();
  }
}

function toHistoryItemDto(report: CashierXReading): CashierXReadingHistoryItemDto {
  const snapshot = report.snapshot as unknown as CashierXReadingResponseDto;
  return {
    id: report.id,
    periodStart: report.periodStart ? report.periodStart.toISOString() : null,
    periodEnd: report.periodEnd ? report.periodEnd.toISOString() : null,
    generatedAt: report.generatedAt.toISOString(),
    totalSales: snapshot.totalSales,
    completedTransactions: snapshot.completedTransactions,
  };
}
