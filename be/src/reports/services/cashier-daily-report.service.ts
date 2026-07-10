import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { PaymentMethod } from '../../payments/payments.enum';
import { User } from '../../users/entities/user.entity';
import { VAT_EXEMPT_DISCOUNT_NAME_PATTERNS } from '../../sales-orders/services/sales-order-calculation.service';
import { STATUS_FILTER } from '../reports.constants';
import { CashierDailyReportResponseDto } from '../dto/cashier-daily-report-response.dto';
import { CashierDailyReportMapper } from '../mapper/cashier-daily-report.mapper';
import { BaseReportService } from './base-report.service';
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
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {
    super();
  }

  async getReport(causer: User): Promise<CashierDailyReportResponseDto> {
    const [currentUser, salesTotals, tax, vatExempt, quantity, productRows, cashSales, cashLedgerRows] =
      await Promise.all([
        this.userRepository.findOne({ where: { id: causer.id }, relations: ['posTerminal'] }),
        this.getSalesTotals(causer.id),
        this.getTax(causer.id),
        this.getVatExemptSales(causer.id),
        this.getQuantitySold(causer.id),
        this.getSalesByProduct(causer.id),
        this.getCashSales(causer.id),
        this.getCashLedgerEntries(causer.id),
      ]);

    if (currentUser == null) {
      throw new Error(`User ${causer.id} not found while generating cashier daily report`);
    }

    return CashierDailyReportMapper.toDto({
      currentUser,
      salesTotals,
      tax,
      vatExempt,
      quantity,
      productRows,
      cashSales,
      cashLedgerRows,
    });
  }

  private getSalesTotals(userId: number): Promise<CashierSalesTotalsRawRow | undefined> {
    return this.salesOrderRepository
      .createQueryBuilder('so')
      .select(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .addSelect('COUNT(so.id)', 'completedTransactions')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .getRawOne<CashierSalesTotalsRawRow>();
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

  private getSalesByProduct(userId: number): Promise<CashierProductSalesRawRow[]> {
    return this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('soi.description', 'productName')
      .addSelect('SUM(soi.qty)', 'quantity')
      .addSelect('SUM(soi.item_total_amount)', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .groupBy('soi.description')
      .orderBy('LOWER(soi.description)', 'ASC')
      .getRawMany<CashierProductSalesRawRow>();
  }

  private getCashSales(userId: number): Promise<CashierCashSalesRawRow | undefined> {
    return this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select('SUM(p.amount_paid - p.change)', 'totalCashSales')
      .addSelect('COUNT(p.id)', 'cashSalesCount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere('p.payment_method = :cash', { cash: PaymentMethod.CASH })
      .getRawOne<CashierCashSalesRawRow>();
  }

  private getCashLedgerEntries(userId: number): Promise<CashierPaymentLedgerRawRow[]> {
    return this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect('p.payment_date', 'paymentDate')
      .addSelect('p.transaction_reference', 'transactionReference')
      .addSelect('p.amount_paid - p.change', 'amount')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.created_by = :userId', { userId })
      .andWhere('so.so_date::date = CURRENT_DATE')
      .andWhere('p.payment_method = :cash', { cash: PaymentMethod.CASH })
      .orderBy('p.payment_date', 'ASC')
      .getRawMany<CashierPaymentLedgerRawRow>();
  }
}
