import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesReportQueryDto } from '../dto/sales-report-query.dto';
import { UserSalesDataItemDto } from '../dto/user-sales-response.dto';
import { STATUS_FILTER } from '../reports.constants';
import type { IdNameTotalSalesRawRow } from '../reports.interface';
import { toUserSalesItemDto } from '../mapper/user-sales-report.mapper';
import { BaseReportService } from './base-report.service';

/**
 * Service for the user sales report (id, name, totalSales per user).
 * totalSales = SUM(soi.item_total_amount * soi.qty) per user (order created_by).
 */
@Injectable()
export class UserSalesReportService extends BaseReportService<
  SalesReportQueryDto,
  UserSalesDataItemDto[]
> {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  /**
   * Returns user sales report for the given date range.
   */
  async getReport(query: SalesReportQueryDto): Promise<UserSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('so.createdBy', 'u')
      .select('u.id', 'id')
      .addSelect("u.first_name || ' ' || u.last_name", 'name')
      .addSelect('SUM(soi.item_total_amount)', 'totalSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .groupBy('u.id')
      .addGroupBy('u.first_name')
      .addGroupBy('u.last_name')
      .orderBy('SUM(soi.item_total_amount)', query.sort ?? 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toUserSalesItemDto(row));
  }
}
