import dayjs from 'dayjs';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { HourlySalesQueryDto } from '../dto/hourly-sales-query.dto';
import { STATUS_FILTER } from '../reports.constants';
import { HourlySalesDataItemDto } from '../dto/hourly-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';
import { toHourlySalesDataItemDto } from '../mapper/hourly-sales-report.mapper';
import { BaseReportService } from './base-report.service';

const HOUR_KEY_FORMAT = 'YYYY-MM-DDTHH:mm';

/**
 * Service for the hourly sales report (one row per hour: date, hour, total, transactions, items, discount).
 */
@Injectable()
export class HourlySalesReportService extends BaseReportService<
  HourlySalesQueryDto,
  HourlySalesDataItemDto[]
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
   * Returns hourly sales report for the given date range.
   */
  async getReport(query: HourlySalesQueryDto): Promise<HourlySalesDataItemDto[]> {
    const dateExpr = "date_trunc('hour', so.so_date)";
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

    const toHourKey = (v: string | Date): string =>
      dayjs(v).isValid() ? dayjs(v).format(HOUR_KEY_FORMAT) : String(v);
    const itemsByHour = new Map<string, string>();
    for (const row of soiRows) {
      itemsByHour.set(toHourKey(row.date), row.items ?? '0');
    }

    const sortedSoRows = [...soRows].sort(
      (a, b) => dayjs(a.date).valueOf() - dayjs(b.date).valueOf(),
    );
    const hourly: HourlySalesDataItemDto[] = sortedSoRows.map((row) =>
      toHourlySalesDataItemDto({
        ...row,
        items: itemsByHour.get(toHourKey(row.date)) ?? '0',
      }),
    );

    return hourly;
  }
}
