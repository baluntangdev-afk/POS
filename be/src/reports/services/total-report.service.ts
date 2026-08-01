import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder } from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { SalesOrderStatus } from '../../sales-orders/sales-orders.enum';
import { SalesQueryDto } from '../dto/sales-query.dto';
import { SalesResponseDto } from '../dto/sales-response.dto';
import { SalesReportMapper } from '../mapper/sales-report.mapper';
import { BaseReportService } from './base-report.service';
import { STATUS_FILTER } from '../reports.constants';

/**
 * Service for the total/sales report (totalSales, totalDiscount, totalRefunds, totalItems, totalTransactions).
 */
@Injectable()
export class TotalReportService extends BaseReportService<SalesQueryDto, SalesResponseDto> {
  constructor(
    @InjectRepository(SalesOrder)
    private readonly salesOrderRepository: Repository<SalesOrder>,
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {
    super();
  }

  /**
   * Returns sales report for the given date range.
   */
  async getReport(query: SalesQueryDto): Promise<SalesResponseDto> {
    const soQueryBuilder = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('SUM(so.final_total_amount)', 'totalSales')
      .addSelect('SUM(so.discount_amount)', 'totalDiscount')
      .addSelect(
        `SUM(COALESCE((SELECT SUM(r.total_refund_amount) FROM refunds r WHERE r.original_sales_order_id = so.id), 0))`,
        'totalRefunds',
      )
      .addSelect('COUNT(so.id)', 'totalTransactions');

    this.applyDateFilter(soQueryBuilder, query);

    const soiQueryBuilder = this.salesOrderItemRepository
      .createQueryBuilder('soi')
      .innerJoin('soi.salesOrder', 'so')
      .select('COUNT(soi.id)', 'totalItems');

    this.applyDateFilter(soiQueryBuilder, query);

    const voidedQueryBuilder = this.salesOrderRepository
      .createQueryBuilder('so')
      .select('COUNT(so.id)', 'totalVoidedTransactions')
      .addSelect('SUM(so.final_total_amount)', 'totalVoidedAmount')
      .andWhere('so.status = :voidedStatus', { voidedStatus: SalesOrderStatus.CANCELLED });

    this.applyVoidedDateFilter(voidedQueryBuilder, query);

    const [soQueryResult, soiQueryResult, voidedQueryResult] = await Promise.all([
      soQueryBuilder.getRawOne(),
      soiQueryBuilder.getRawOne<{ totalItems: string }>(),
      voidedQueryBuilder.getRawOne(),
    ]);

    return SalesReportMapper.toDto({
      ...soQueryResult,
      totalItems: soiQueryResult?.totalItems ?? '0',
      totalVoidedTransactions: voidedQueryResult?.totalVoidedTransactions ?? '0',
      totalVoidedAmount: voidedQueryResult?.totalVoidedAmount ?? '0',
    });
  }

  private applyDateFilter(
    qb: SelectQueryBuilder<SalesOrder | SalesOrderItem>,
    query: SalesQueryDto,
  ): void {
    qb.andWhere('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER });

    if (query.startDate && !query.endDate) {
      qb.andWhere('so.so_date >= :startDate', { startDate: query.startDate });
    } else if (query.endDate && !query.startDate) {
      qb.andWhere('so.so_date <= :endDate', { endDate: query.endDate });
    } else if (query.startDate && query.endDate) {
      qb.andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      });
    }
  }

  private applyVoidedDateFilter(
    qb: SelectQueryBuilder<SalesOrder>,
    query: SalesQueryDto,
  ): void {
    if (query.startDate && !query.endDate) {
      qb.andWhere('so.so_date >= :startDate', { startDate: query.startDate });
    } else if (query.endDate && !query.startDate) {
      qb.andWhere('so.so_date <= :endDate', { endDate: query.endDate });
    } else if (query.startDate && query.endDate) {
      qb.andWhere('so.so_date BETWEEN :startDate AND :endDate', {
        startDate: query.startDate,
        endDate: query.endDate,
      });
    }
  }
}
