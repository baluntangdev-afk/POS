import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesReportQueryDto } from '../dto/sales-report-query.dto';
import { STATUS_FILTER } from '../reports.constants';
import { ProductSalesDataItemDto } from '../dto/product-sales-response.dto';
import type { IdNameTotalSalesRawRow } from '../reports.interface';
import { toProductSalesItemDto } from '../mapper/product-sales-report.mapper';
import { BaseReportService } from './base-report.service';

/**
 * Service for the product sales report (id, name, totalSales per product).
 * totalSales = SUM(soi.item_total_amount * soi.qty) per product.
 */
@Injectable()
export class ProductSalesReportService extends BaseReportService<
  SalesReportQueryDto,
  ProductSalesDataItemDto[]
> {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  /**
   * Returns product sales report for the given date range.
   */
  async getReport(query: SalesReportQueryDto): Promise<ProductSalesDataItemDto[]> {
    const qb = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .innerJoin('soi.productVariant', 'pv')
      .innerJoin('pv.product', 'p')
      .select('p.id', 'id')
      .addSelect('p.name', 'name')
      .addSelect('SUM(soi.item_total_amount)', 'totalSales')
      .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
      .andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      })
      .groupBy('p.id')
      .addGroupBy('p.name')
      .orderBy('SUM(soi.item_total_amount)', query.sort ?? 'DESC');

    const rawRows = await qb.getRawMany<IdNameTotalSalesRawRow>();
    return rawRows.map((row) => toProductSalesItemDto(row));
  }
}
