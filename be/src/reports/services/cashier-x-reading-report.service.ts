import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../../sales-orders/entities/sales-order-discount.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import { CashierXReadingResponseDto } from '../dto/cashier-x-reading-response.dto';
import { CashierXReadingReportMapper } from '../mapper/cashier-x-reading-report.mapper';
import { BaseReportService } from './base-report.service';
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

/**
 * X Reading: read-only snapshot of the current cashier's own transactions today, on their
 * assigned terminal. Never resets counters, closes a shift, or mutates any data.
 */
@Injectable()
export class CashierXReadingReportService extends BaseReportService<
  User,
  CashierXReadingResponseDto
> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(SalesOrderDiscount)
    private readonly salesOrderDiscountRepository: Repository<SalesOrderDiscount>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {
    super();
  }

  async getReport(causer: User): Promise<CashierXReadingResponseDto> {
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
      this.userRepository.findOne({ where: { id: causer.id }, relations: ['posTerminal'] }),
      this.getPaymentBreakdown(causer.id),
      this.getPaymentLedgerEntries(causer.id),
      this.getDiscountBreakdown(causer.id),
      this.getSalesTotals(causer.id),
      this.getVoidedCount(causer.id),
      this.getRefundedCount(causer.id),
      this.getTax(causer.id),
      this.getVatExemptSales(causer.id),
      this.getQuantitySold(causer.id),
    ]);

    if (currentUser == null) {
      throw new Error(`User ${causer.id} not found while generating X Reading`);
    }

    return CashierXReadingReportMapper.toDto({
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
    });
  }

  private getPaymentBreakdown(userId: number): Promise<NameAmountRawRow[]> {
    return this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'amount',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .groupBy(`COALESCE(p.payment_method_name, p.payment_method::text)`)
      .getRawMany<NameAmountRawRow>();
  }

  private getPaymentLedgerEntries(userId: number): Promise<CashierPaymentLedgerRawRow[]> {
    return this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect('p.payment_date', 'paymentDate')
      .addSelect('p.transaction_reference', 'transactionReference')
      .addSelect('p.amount_paid', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .orderBy('p.payment_date', 'ASC')
      .getRawMany<CashierPaymentLedgerRawRow>();
  }

  private getDiscountBreakdown(userId: number): Promise<NameAmountRawRow[]> {
    return this.salesOrderDiscountRepository
      .createQueryBuilder('sod')
      .innerJoin('sod.discount', 'd')
      .innerJoin('sod.salesOrder', 'so')
      .select('d.name', 'name')
      .addSelect('SUM(sod.applied_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .groupBy('d.name')
      .getRawMany<NameAmountRawRow>();
  }

  private getSalesTotals(userId: number): Promise<CashierSalesTotalsRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .addSelect('SUM(so.discount_amount)', 'totalDiscounts')
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .addSelect('AVG(so.final_total_amount)', 'averageSale')
      .addSelect('MAX(so.final_total_amount)', 'highestSale')
      .addSelect('MIN(so.final_total_amount)', 'lowestSale')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierSalesTotalsRawRow>();
  }

  private getVoidedCount(userId: number): Promise<CashierVoidedRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'voidedTransactions')
      .where('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierVoidedRawRow>();
  }

  private getRefundedCount(userId: number): Promise<CashierRefundedRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'refundedTransactions')
      .where('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere('EXISTS (SELECT 1 FROM refunds r WHERE r.original_sales_order_id = so.id)')
      .getRawOne<CashierRefundedRawRow>();
  }

  private getTax(userId: number): Promise<CashierTaxRawRow | undefined> {
    return this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.vat_exclusive_amount)', 'vatSales')
      .addSelect('SUM(soi.vat_amount)', 'vatAmount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere(
        `NOT EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierTaxRawRow>();
  }

  private getVatExemptSales(userId: number): Promise<CashierVatExemptRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'vatExemptSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere(
        `EXISTS (SELECT 1 FROM so_discounts sod INNER JOIN discounts d ON d.id = sod.discount_id WHERE sod.sales_order_id = so.id AND d.name = :vatExemptName)`,
        { vatExemptName: VAT_EXEMPT_DISCOUNT_NAME_PATTERNS },
      )
      .getRawOne<CashierVatExemptRawRow>();
  }

  private getQuantitySold(userId: number): Promise<CashierQuantityRawRow | undefined> {
    return this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('SUM(soi.qty)', 'totalQuantitySold')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierQuantityRawRow>();
  }
}
