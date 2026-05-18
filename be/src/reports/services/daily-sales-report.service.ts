import dayjs from 'dayjs';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { HourlySalesQueryDto } from '../dto/hourly-sales-query.dto';
import { STATUS_FILTER } from '../reports.constants';
import { DailySalesDataItemDto } from '../dto/daily-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';
import { toDailySalesDataItemDto } from '../mapper/daily-sales-report.mapper';
import { BaseReportService } from './base-report.service';

const DATE_KEY_FORMAT = 'YYYY-MM-DD';

/**
 * Service for the daily sales report (one row per day: date, total, transactions, items, discount).
 */
@Injectable()
export class DailySalesReportService extends BaseReportService<
  HourlySalesQueryDto,
  DailySalesDataItemDto[]
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
   * Returns daily sales report for the given date range.
   */
  async getReport(query: HourlySalesQueryDto): Promise<DailySalesDataItemDto[]> {
    const dateExpr = "date_trunc('day', so.so_date)";
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

    const toDateKey = (v: string | Date): string =>
      dayjs(v).isValid() ? dayjs(v).format(DATE_KEY_FORMAT) : String(v);
    const itemsByDate = new Map<string, string>();
    for (const row of soiRows) {
      itemsByDate.set(toDateKey(row.date), row.items ?? '0');
    }

    const sortedSoRows = [...soRows].sort(
      (a, b) => dayjs(a.date).valueOf() - dayjs(b.date).valueOf(),
    );
    const daily: DailySalesDataItemDto[] = sortedSoRows.map((row) =>
      toDailySalesDataItemDto({
        ...row,
        items: itemsByDate.get(toDateKey(row.date)) ?? '0',
      }),
    );

    return daily;
  }
}
