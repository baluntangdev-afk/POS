import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { PaymentMethod } from '../../payments/payments.enum';
import { User } from '../../users/entities/user.entity';
import { CashierDailyReport } from '../entities/cashier-daily-report.entity';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import {
  CashierDailyReportHistoryItemDto,
  CashierDailyReportResponseDto,
} from '../dto/cashier-daily-report-response.dto';
import {
  CashierDailyReportMapper,
  CashierDailyReportRawInputs,
} from '../mapper/cashier-daily-report.mapper';
import { BaseReportService } from './base-report.service';
import type { PaginatedQueryParams, PaginatedResult } from '../../utils/pagination/interfaces';
import type {
  CashierCashSalesRawRow,
  CashierPaymentLedgerRawRow,
  CashierProductSalesRawRow,
  CashierQuantityRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
} from '../reports.interface';

/**
 * Cashier daily report: the logged-in cashier's own completed transactions today, summarized
 * BIR-style with an itemized per-product sales breakdown and a cash ledger. Read-only.
 */
@Injectable()
export class CashierDailyReportService extends BaseReportService<
  User,
  CashierDailyReportResponseDto
> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(CashierDailyReport)
    private readonly cashierDailyReportRepository: Repository<CashierDailyReport>,
  ) {
    super();
  }

  async getReport(causer: User): Promise<CashierDailyReportResponseDto> {
    const dto = await this.computeReport(causer.id, new Date(), this.salesOrderRepository.manager);
    return dto;
  }

  /**
   * Closes the current unreported window: recomputes the report, persists it as a snapshot, and
   * marks every covered transaction `done_daily_report = true` with `daily_report_id` set to the
   * new report's id — all inside one transaction so the persisted snapshot and the marked rows
   * always agree.
   */
  async closeReport(causer: User): Promise<CashierDailyReportResponseDto> {
    return this.salesOrderRepository.manager.transaction(async (manager) => {
      const requestTime = new Date();
      const dto = await this.computeReport(causer.id, requestTime, manager);

      if (dto.periodStart == null) {
        throw new ConflictException('No unreported transactions to close for this cashier.');
      }

      const reportRepository = manager.getRepository(CashierDailyReport);
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
         SET done_daily_report = true, daily_report_id = $1
         WHERE created_by = $2 AND done_daily_report = false AND so_date <= $3`,
        [report.id, causer.id, requestTime],
      );

      return { ...dto, id: report.id };
    });
  }

  async getHistory(
    causer: User,
    query: PaginatedQueryParams,
  ): Promise<PaginatedResult<CashierDailyReportHistoryItemDto>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;

    const [rows, total] = await this.cashierDailyReportRepository
      .createQueryBuilder('r')
      .where('r.cashier_id = :cashierId', { cashierId: causer.id })
      .orderBy('r.generated_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data: rows.map(toHistoryItemDto), total, page, limit };
  }

  async getHistoryDetail(causer: User, id: string): Promise<CashierDailyReportResponseDto> {
    const report = await this.cashierDailyReportRepository.findOne({
      where: { id, cashier: { id: causer.id } },
    });
    if (report == null) {
      throw new NotFoundException(`Cashier daily report ${id} not found.`);
    }
    return { ...(report.snapshot as unknown as CashierDailyReportResponseDto), id: report.id };
  }

  private async computeReport(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierDailyReportResponseDto> {
    const [
      currentUser,
      salesTotals,
      tax,
      vatExempt,
      quantity,
      productRows,
      cashSales,
      cashLedgerRows,
    ] = await Promise.all([
      manager.findOne(User, { where: { id: userId }, relations: ['posTerminal'] }),
      this.getSalesTotals(userId, requestTime, manager),
      this.getTax(userId, requestTime, manager),
      this.getVatExemptSales(userId, requestTime, manager),
      this.getQuantitySold(userId, requestTime, manager),
      this.getSalesByProduct(userId, requestTime, manager),
      this.getCashSales(userId, requestTime, manager),
      this.getCashLedgerEntries(userId, requestTime, manager),
    ]);

    if (currentUser == null) {
      throw new Error(`User ${userId} not found while generating cashier daily report`);
    }

    const raw: CashierDailyReportRawInputs = {
      currentUser,
      salesTotals,
      tax,
      vatExempt,
      quantity,
      productRows,
      cashSales,
      cashLedgerRows,
    };
    return CashierDailyReportMapper.toDto(raw);
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
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('MIN(so.so_date)', 'periodStart')
      .addSelect('MAX(so.so_date)', 'periodEnd')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierSalesTotalsRawRow>();
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
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
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
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
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
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierQuantityRawRow>();
  }

  private getSalesByProduct(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierProductSalesRawRow[]> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('soi.description', 'productName')
      .addSelect('SUM(soi.qty)', 'quantity')
      .addSelect('SUM(soi.item_total_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy('soi.description')
      .orderBy('LOWER(soi.description)', 'ASC')
      .getRawMany<CashierProductSalesRawRow>();
  }

  private getCashSales(
    userId: number,
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierCashSalesRawRow | undefined> {
    return manager
      .createQueryBuilder(Payment, 'p')
      .innerJoin('p.salesOrder', 'so')
      .select('SUM(p.amount_paid - p.change)', 'totalCashSales')
      .addSelect('COUNT(p.id)', 'cashSalesCount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere('p.payment_method = :cash', { cash: PaymentMethod.CASH })
      .getRawOne<CashierCashSalesRawRow>();
  }

  private getCashLedgerEntries(
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
      .andWhere('so.done_daily_report = :doneDailyReport', { doneDailyReport: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere('p.payment_method = :cash', { cash: PaymentMethod.CASH })
      .orderBy('p.payment_date', 'ASC')
      .getRawMany<CashierPaymentLedgerRawRow>();
  }
}

function toHistoryItemDto(report: CashierDailyReport): CashierDailyReportHistoryItemDto {
  const snapshot = report.snapshot as unknown as CashierDailyReportResponseDto;
  return {
    id: report.id,
    periodStart: report.periodStart ? report.periodStart.toISOString() : null,
    periodEnd: report.periodEnd ? report.periodEnd.toISOString() : null,
    generatedAt: report.generatedAt.toISOString(),
    grossSales: snapshot.grossSales,
    transactionCount: snapshot.transactionCount,
  };
}
