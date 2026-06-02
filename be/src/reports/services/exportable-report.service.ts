// be/src/reports/services/exportable-report.service.ts
import dayjs from 'dayjs';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { STATUS_FILTER } from '../reports.constants';
import { SalesReportMapper } from '../mapper/sales-report.mapper';
import { toHourlySalesDataItemDto } from '../mapper/hourly-sales-report.mapper';
import { toProductSalesItemDto } from '../mapper/product-sales-report.mapper';
import { toProductGroupSalesItemDto } from '../mapper/product-group-sales-report.mapper';
import { toPaymentMethodSalesItemDto } from '../mapper/payment-sales-report.mapper';
import { toUserSalesItemDto } from '../mapper/user-sales-report.mapper';
import { ExportableReportResponseDto } from '../dto/exportable-report-response.dto';
import { SalesResponseDto } from '../dto/sales-response.dto';
import { HourlySalesDataItemDto } from '../dto/hourly-sales-response.dto';
import { ProductSalesDataItemDto } from '../dto/product-sales-response.dto';
import { ProductGroupSalesDataItemDto } from '../dto/product-group-sales-response.dto';
import { PaymentMethodSalesDataItemDto } from '../dto/payment-sales-response.dto';
import { UserSalesDataItemDto } from '../dto/user-sales-response.dto';
import type { SalesByPeriodRawRow, SalesReportRawRow, IdNameTotalSalesRawRow, PaymentMethodSalesRawRow } from '../reports.interface';

const HOUR_KEY_FORMAT = 'YYYY-MM-DDTHH:mm';

@Injectable()
export class ExportableReportService {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {}

  async getExportable(date: string): Promise<ExportableReportResponseDto> {
    const startDate = dayjs(date).startOf('day').toDate();
    const endDate = dayjs(date).endOf('day').toDate();

    const count = await this.salesOrderRepository
      .createQueryBuilder('so')
      .where('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .getCount();

    if (count === 0) {
      return {
        date,
        count: 0,
        summary: SalesReportMapper.toDto(null),
        hourlyBreakdown: [],
        byProduct: [],
        byProductGroup: [],
        byPayment: [],
        byCashier: [],
      };
    }

    const [summary, hourlyBreakdown, byProduct, byProductGroup, byPayment, byCashier] =
      await Promise.all([
        this._getSummary(startDate, endDate),
        this._getHourlyBreakdown(startDate, endDate),
        this._getByProduct(startDate, endDate),
        this._getByProductGroup(startDate, endDate),
        this._getByPayment(startDate, endDate),
        this._getByCashier(startDate, endDate),
      ]);

    return { date, count, summary, hourlyBreakdown, byProduct, byProductGroup, byPayment, byCashier };
  }

  async markExported(date: string): Promise<{ updatedCount: number }> {
    const startDate = dayjs(date).startOf('day').toDate();
    const endDate = dayjs(date).endOf('day').toDate();

    const result = await this.salesOrderRepository
      .createQueryBuilder()
      .update(SalesOrder)
      .set({ doneExport: true })
      .where('done_export = :doneExport', { doneExport: false })
      .andWhere('so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .execute();

    return { updatedCount: result.affected ?? 0 };
  }

  private async _getSummary(startDate: Date, endDate: Date): Promise<SalesResponseDto> {
    const soQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'totalSales')
      .addSelect('SUM(so.discount_amount)', 'totalDiscount')
      .addSelect(
        `SUM(COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalRefunds',
      )
      .addSelect('COUNT(so.id)', 'totalTransactions')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const soiQb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('COUNT(soi.id)', 'totalItems')
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const voidedQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'totalVoidedTransactions')
      .addSelect('SUM(so.final_total_amount)', 'totalVoidedAmount')
      .andWhere('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate });

    const [soResult, soiResult, voidedResult] = await Promise.all([
      soQb.getRawOne<SalesReportRawRow>(),
      soiQb.getRawOne<{ totalItems: string }>(),
      voidedQb.getRawOne(),
    ]);

    return SalesReportMapper.toDto({
      ...soResult,
      totalItems: soiResult?.totalItems ?? '0',
      totalVoidedTransactions: voidedResult?.totalVoidedTransactions ?? '0',
      totalVoidedAmount: voidedResult?.totalVoidedAmount ?? '0',
    });
  }

  private async _getHourlyBreakdown(startDate: Date, endDate: Date): Promise<HourlySalesDataItemDto[]> {
    const dateExpr = "date_trunc('hour', so.so_date)";

    const soQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select(dateExpr, 'date')
      .addSelect('SUM(so.final_total_amount)', 'total')
      .addSelect('COUNT(so.id)', 'transactions')
      .addSelect('SUM(so.discount_amount)', 'discount')
      .where('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const soiQb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select(dateExpr, 'date')
      .addSelect('COUNT(soi.id)', 'items')
      .where('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const [soRows, soiRows] = await Promise.all([
      soQb.getRawMany<SalesByPeriodRawRow>(),
      soiQb.getRawMany<{ date: string | Date; items: string }>(),
    ]);

    const toHourKey = (v: string | Date): string =>
      dayjs(v).isValid() ? dayjs(v).format(HOUR_KEY_FORMAT) : String(v);
    const itemsByHour = new Map<string, string>();
    for (const row of soiRows) {
      itemsByHour.set(toHourKey(row.date), row.items ?? '0');
    }

    return [...soRows]
      .sort((a, b) => dayjs(a.date).valueOf() - dayjs(b.date).valueOf())
      .map((row) =>
        toHourlySalesDataItemDto({ ...row, items: itemsByHour.get(toHourKey(row.date)) ?? '0' }),
      );
  }

  private async _getByProduct(startDate: Date, endDate: Date): Promise<ProductSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .select('p.id', 'id')
      .addSelect('p.name', 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('p.id')
      .addGroupBy('p.name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductSalesItemDto(row));
  }

  private async _getByProductGroup(startDate: Date, endDate: Date): Promise<ProductGroupSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .innerJoin('p.productGroup', 'pg')
      .select('pg.id', 'id')
      .addSelect('pg.name', 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('pg.id')
      .addGroupBy('pg.name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductGroupSalesItemDto(row));
  }

  private async _getByPayment(startDate: Date, endDate: Date): Promise<PaymentMethodSalesDataItemDto[]> {
    const qb = this.paymentRepository
      .createQueryBuilder('p')
      .innerJoin('p.salesOrder', 'so')
      .select('p.payment_method', 'name')
      .addSelect(
        `SUM(so.final_total_amount - COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('p.payment_method')
      .orderBy('SUM(so.final_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<PaymentMethodSalesRawRow>();
    return rawRows.map((row) => toPaymentMethodSalesItemDto(row));
  }

  private async _getByCashier(startDate: Date, endDate: Date): Promise<UserSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('so.createdBy', 'u')
      .select('u.id', 'id')
      .addSelect("u.first_name || ' ' || u.last_name", 'name')
      .addSelect(
        `SUM(soi.item_total_amount - COALESCE((SELECT SUM(ri.refund_amount) FROM refund_items ri WHERE ri.sales_order_item_id = soi.id), 0))`,
        'totalSales',
      )
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.done_export = :doneExport', { doneExport: false })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', { startDate, endDate })
      .groupBy('u.id')
      .addGroupBy('u.first_name')
      .addGroupBy('u.last_name')
      .orderBy('SUM(soi.item_total_amount)', 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toUserSalesItemDto(row));
  }
}
