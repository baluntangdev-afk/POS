import dayjs from 'dayjs';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { MonthlySalesQueryDto } from '../dto/monthly-sales-query.dto';
import { STATUS_FILTER } from '../reports.constants';
import { MonthlySalesDataItemDto } from '../dto/monthly-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';
import { toMonthlySalesDataItemDto } from '../mapper/monthly-sales-report.mapper';
import { BaseReportService } from './base-report.service';

const MONTH_KEY_FORMAT = 'YYYY-MM';

/**
 * Service for the monthly sales report (one row per month, sorted by year and month: total, transactions, items, discount).
 */
@Injectable()
export class MonthlySalesReportService extends BaseReportService<
  MonthlySalesQueryDto,
  MonthlySalesDataItemDto[]
> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  /**
   * Returns monthly sales report for the given date range. Sorted by year and month ascending.
   */
  async getReport(query: MonthlySalesQueryDto): Promise<MonthlySalesDataItemDto[]> {
    const dateExpr = "date_trunc('month', so.so_date)";
    const soQb = this.salesOrderRepository
      .createQueryBuilder('so')
      .select(dateExpr, 'date')
      .addSelect('SUM(so.final_total_amount)', 'total')
      .addSelect('COUNT(so.id)', 'transactions')
      .addSelect('SUM(so.discount_amount)', 'discount')
      .where('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const soiQb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select(dateExpr, 'date')
      .addSelect('COUNT(soi.id)', 'items')
      .where('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .groupBy(dateExpr)
      .orderBy('date', 'ASC');

    const [soRows, soiRows] = await Promise.all([
      soQb.getRawMany<SalesByPeriodRawRow>(),
      soiQb.getRawMany<{ date: string | Date; items: string }>(),
    ]);

    const toMonthKey = (v: string | Date): string =>
      dayjs(v).isValid() ? dayjs(v).format(MONTH_KEY_FORMAT) : String(v);

    const itemsByMonth = new Map<string, string>();
    for (const row of soiRows) {
      itemsByMonth.set(toMonthKey(row.date), row.items ?? '0');
    }

    const sortedSoRows = [...soRows].sort(
      (a, b) => dayjs(a.date).valueOf() - dayjs(b.date).valueOf(),
    );

    return sortedSoRows.map((row) =>
      toMonthlySalesDataItemDto({
        ...row,
        items: itemsByMonth.get(toMonthKey(row.date)) ?? '0',
      }),
    );
  }
}
