import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../../sales-orders/entities/sales-order-discount.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { User } from '../../users/entities/user.entity';
import { UsersService } from '../../users/users.service';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { ZReading } from '../entities/z-reading.entity';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import { ZReadingHistoryItemDto, ZReadingResponseDto } from '../dto/z-reading-response.dto';
import { ZReadingReportMapper, ZReadingRawInputs } from '../mapper/z-reading-report.mapper';
import { BaseReportService } from './base-report.service';
import type { PaginatedQueryParams, PaginatedResult } from '../../utils/pagination/interfaces';
import type {
  CashierQuantityRawRow,
  CashierRefundedRawRow,
  CashierSalesTotalsRawRow,
  CashierTaxRawRow,
  CashierVatExemptRawRow,
  CashierVoidedRawRow,
  NameAmountRawRow,
  ZReadingCashierBreakdownRawRow,
} from '../reports.interface';

/**
 * Z-Reading: store-wide, supervisor-authorized close of all cashiers' unreported transactions,
 * with a never-resetting grand cumulative total and a sequential Z-counter. Unlike X-Reading and
 * the Cashier Daily Report, this is not scoped to a single cashier.
 */
@Injectable()
export class ZReadingReportService extends BaseReportService<User, ZReadingResponseDto> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(ZReading)
    private readonly zReadingRepository: Repository<ZReading>,
    private readonly usersService: UsersService,
  ) {
    super();
  }

  async getReport(causer: User): Promise<ZReadingResponseDto> {
    // Z-Reading is store-wide, not scoped to the requesting cashier; `causer` is accepted only
    // to satisfy BaseReportService's signature.
    void causer;
    return this.computeReport(new Date(), this.salesOrderRepository.manager);
  }

  /**
   * Closes the current store-wide unreported window: verifies the supervisor/admin PIN,
   * recomputes the report, persists it as a snapshot (with the next Z-counter and the grand
   * total's new ending balance), and marks every covered transaction `done_z_reading = true`
   * with `z_reading_id` set to the new report's id — all inside one transaction.
   */
  async closeReport(causer: User, authorizerId: string, pin: string): Promise<ZReadingResponseDto> {
    await this.usersService.verifyPin(authorizerId, pin);

    return this.salesOrderRepository.manager.transaction(async (manager) => {
      const requestTime = new Date();

      const authorizer = await manager.findOne(User, { where: { userId: authorizerId } });
      if (authorizer == null) {
        throw new NotFoundException('Authorizer user not found');
      }

      const dto = await this.computeReport(requestTime, manager);

      if (dto.periodStart == null) {
        throw new ConflictException('No unreported transactions to close store-wide.');
      }

      const [{ nextval }] = await manager.query<[{ nextval: string }]>(
        `SELECT nextval('z_readings_z_counter_seq') as nextval`,
      );
      const zCounter = parseInt(nextval, 10);

      const zReadingRepository = manager.getRepository(ZReading);
      const report = await zReadingRepository.save(
        zReadingRepository.create({
          zCounter,
          periodStart: new Date(dto.periodStart),
          periodEnd: dto.periodEnd ? new Date(dto.periodEnd) : null,
          generatedAt: requestTime,
          closedBy: { id: causer.id } as User,
          authorizedBy: { id: authorizer.id } as User,
          beginningBalance: dto.beginningBalance.toFixed(2),
          endingBalance: dto.endingBalance.toFixed(2),
          snapshot: dto as unknown as Record<string, unknown>,
        }),
      );

      await manager.query(
        `UPDATE sales_orders
         SET done_z_reading = true, z_reading_id = $1
         WHERE done_z_reading = false AND so_date <= $2`,
        [report.id, requestTime],
      );

      const closedByName = `${causer.firstName} ${causer.lastName}`.trim();
      const authorizedByName = `${authorizer.firstName} ${authorizer.lastName}`.trim();

      return { ...dto, id: report.id, zCounter, closedByName, authorizedByName };
    });
  }

  async getHistory(query: PaginatedQueryParams): Promise<PaginatedResult<ZReadingHistoryItemDto>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;

    const [rows, total] = await this.zReadingRepository
      .createQueryBuilder('z')
      .orderBy('z.generated_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data: rows.map(toHistoryItemDto), total, page, limit };
  }

  async getHistoryDetail(id: string): Promise<ZReadingResponseDto> {
    const report = await this.zReadingRepository.findOne({ where: { id } });
    if (report == null) {
      throw new NotFoundException(`Z-Reading ${id} not found.`);
    }
    return { ...(report.snapshot as unknown as ZReadingResponseDto), id: report.id };
  }

  private async computeReport(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<ZReadingResponseDto> {
    const [
      latestOrder,
      paymentRows,
      categoryRows,
      discountRows,
      salesTotals,
      voided,
      refunded,
      tax,
      vatExempt,
      quantity,
      cashierBreakdownRows,
      beginningBalance,
    ] = await Promise.all([
      manager
        .createQueryBuilder(SalesOrder, 'so')
        .leftJoinAndSelect('so.createdBy', 'createdBy')
        .leftJoinAndSelect('createdBy.posTerminal', 'posTerminal')
        .orderBy('so.created_at', 'DESC')
        .getOne(),
      this.getPaymentBreakdown(requestTime, manager),
      this.getSalesByCategory(requestTime, manager),
      this.getDiscountBreakdown(requestTime, manager),
      this.getSalesTotals(requestTime, manager),
      this.getVoidedCount(requestTime, manager),
      this.getRefundedCount(requestTime, manager),
      this.getTax(requestTime, manager),
      this.getVatExemptSales(requestTime, manager),
      this.getQuantitySold(requestTime, manager),
      this.getSalesByCashier(requestTime, manager),
      this.getPreviousEndingBalance(manager),
    ]);

    const terminalName =
      latestOrder?.createdBy.posTerminal?.legalName ??
      latestOrder?.createdBy.posTerminal?.kioskId ??
      'Unassigned';

    const raw: ZReadingRawInputs = {
      terminalName,
      paymentRows,
      categoryRows,
      discountRows,
      salesTotals,
      voided,
      refunded,
      tax,
      vatExempt,
      quantity,
      cashierBreakdownRows,
      beginningBalance,
    };
    return ZReadingReportMapper.toDto(raw);
  }

  private async getPreviousEndingBalance(manager: EntityManager): Promise<number> {
    const latest = await manager
      .getRepository(ZReading)
      .createQueryBuilder('z')
      .orderBy('z.generated_at', 'DESC')
      .getOne();
    return latest ? parseFloat(latest.endingBalance) : 0;
  }

  private getPaymentBreakdown(
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
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy(`COALESCE(p.payment_method_name, p.payment_method::text)`)
      .getRawMany<NameAmountRawRow>();
  }

  private getSalesByCategory(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<NameAmountRawRow[]> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .leftJoin('soi.productVariant', 'pv')
      .leftJoin('pv.product', 'p')
      .leftJoin('p.productGroup', 'pg')
      .select(`COALESCE(pg.name, 'Uncategorized')`, 'name')
      .addSelect('SUM(soi.item_total_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy(`COALESCE(pg.name, 'Uncategorized')`)
      .getRawMany<NameAmountRawRow>();
  }

  private getDiscountBreakdown(
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
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy('d.name')
      .getRawMany<NameAmountRawRow>();
  }

  private getSalesTotals(
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
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierSalesTotalsRawRow>();
  }

  private getVoidedCount(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierVoidedRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('COUNT(so.id)', 'voidedTransactions')
      .where('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierVoidedRawRow>();
  }

  private getRefundedCount(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierRefundedRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('COUNT(so.id)', 'refundedTransactions')
      .where('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere('EXISTS (SELECT 1 FROM refunds r WHERE r.original_sales_order_id = so.id)')
      .getRawOne<CashierRefundedRawRow>();
  }

  private getTax(requestTime: Date, manager: EntityManager): Promise<CashierTaxRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.vat_exclusive_amount)', 'vatSales')
      .addSelect('SUM(soi.vat_amount)', 'vatAmount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere(
        `NOT EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierTaxRawRow>();
  }

  private getVatExemptSales(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierVatExemptRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .select('SUM(so.final_total_amount)', 'vatExemptSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .andWhere(
        `EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierVatExemptRawRow>();
  }

  private getQuantitySold(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<CashierQuantityRawRow | undefined> {
    return manager
      .createQueryBuilder(SalesOrderItem, 'soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.qty)', 'totalQuantitySold')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .getRawOne<CashierQuantityRawRow>();
  }

  private getSalesByCashier(
    requestTime: Date,
    manager: EntityManager,
  ): Promise<ZReadingCashierBreakdownRawRow[]> {
    return manager
      .createQueryBuilder(SalesOrder, 'so')
      .innerJoin('so.createdBy', 'u')
      .select('u.id', 'cashierId')
      .addSelect(`u.first_name || ' ' || u.last_name`, 'cashierName')
      .addSelect('COUNT(so.id)', 'transactionCount')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'salesTotal',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_z_reading = :doneZReading', { doneZReading: false })
      .andWhere('so.so_date <= :requestTime', { requestTime })
      .groupBy('u.id')
      .addGroupBy('u.first_name')
      .addGroupBy('u.last_name')
      .getRawMany<ZReadingCashierBreakdownRawRow>();
  }
}

function toHistoryItemDto(report: ZReading): ZReadingHistoryItemDto {
  const snapshot = report.snapshot as unknown as ZReadingResponseDto;
  return {
    id: report.id,
    zCounter: report.zCounter,
    periodStart: report.periodStart ? report.periodStart.toISOString() : null,
    periodEnd: report.periodEnd ? report.periodEnd.toISOString() : null,
    generatedAt: report.generatedAt.toISOString(),
    totalSales: snapshot.totalSales,
    endingBalance: parseFloat(report.endingBalance),
    completedTransactions: snapshot.completedTransactions,
  };
}
