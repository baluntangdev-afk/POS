import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesReportQueryDto } from '../dto/sales-report-query.dto';
import { STATUS_FILTER } from '../reports.constants';
import { ProductGroupSalesDataItemDto } from '../dto/product-group-sales-response.dto';
import type { IdNameTotalSalesRawRow } from '../reports.interface';
import { toProductGroupSalesItemDto } from '../mapper/product-group-sales-report.mapper';
import { BaseReportService } from './base-report.service';

/**
 * Service for the product group sales report (id, name, totalSales per group).
 * totalSales = SUM(soi.item_total_amount * soi.qty) per product group.
 */
@Injectable()
export class ProductGroupSalesReportService extends BaseReportService<
  SalesReportQueryDto,
  ProductGroupSalesDataItemDto[]
> {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  /**
   * Returns product groups sales report for the given date range.
   */
  async getReport(query: SalesReportQueryDto): Promise<ProductGroupSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .innerJoin('p.productGroup', 'pg')
      .select('pg.id', 'id')
      .addSelect('pg.name', 'name')
      .addSelect('SUM(soi.item_total_amount)', 'totalSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .groupBy('pg.id')
      .addGroupBy('pg.name')
      .orderBy('SUM(soi.item_total_amount)', query.sort ?? 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductGroupSalesItemDto(row));
  }
}
