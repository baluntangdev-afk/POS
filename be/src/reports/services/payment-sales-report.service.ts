import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment } from '../../payments/entities/payment.entity';
import { SalesReportQueryDto } from '../dto/sales-report-query.dto';
import { PaymentMethodSalesDataItemDto } from '../dto/payment-sales-response.dto';
import { STATUS_FILTER } from '../reports.constants';
import type { PaymentMethodSalesRawRow } from '../reports.interface';
import { toPaymentMethodSalesItemDto } from '../mapper/payment-sales-report.mapper';
import { BaseReportService } from './base-report.service';

/**
 * Service for the payment method sales report (id, name, totalSales per payment method).
 * totalSales = SUM(so.final_total_amount) per payment method (each SO counted per payment row).
 */
@Injectable()
export class PaymentSalesReportService extends BaseReportService<
  SalesReportQueryDto,
  PaymentMethodSalesDataItemDto[]
> {
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {
    super();
  }

  /**
   * Returns payment method sales report for the given date range.
   */
  async getReport(query: SalesReportQueryDto): Promise<PaymentMethodSalesDataItemDto[]> {
    const qb = this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select(`COALESCE(p.payment_method_name, p.payment_method::text)`, 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .groupBy(`COALESCE(p.payment_method_name, p.payment_method::text)`)
      .orderBy('SUM(so.final_total_amount)', query.sort ?? 'DESC');

    const rawRows = await qb.getRawMany<PaymentMethodSalesRawRow>();
    return rawRows.map((row) => toPaymentMethodSalesItemDto(row));
  }
}
