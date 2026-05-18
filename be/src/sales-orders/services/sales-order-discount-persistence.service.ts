import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { SalesOrderDiscount } from '../entities/sales-order-discount.entity';

/**
 * Sales order discount persistence. Single responsibility: repository operations for discounts.
 */
@Injectable()
export class SalesOrderDiscountPersistenceService {
  constructor(
    @InjectRepository(SalesOrderDiscount)
    private readonly salesOrderDiscountRepository: Repository<SalesOrderDiscount>,
  ) {}

  /**
   * Loads sales order discounts for the given sales order id with discount relation.
   */
  async findSalesOrderDiscountsBySoId(soId: string): Promise<SalesOrderDiscount[]> {
    return this.salesOrderDiscountRepository.find({
      select: {
        id: true,
        discount: {
          id: true,
          name: true,
          value: true,
        },
      },
      where: { salesOrder: { id: soId } },
      relations: { discount: true },
    });
  }

  /**
   * Persists sales order discounts under the given sales order id within the provided transaction.
   */
  async saveSalesOrderDiscounts(
    salesOrderDiscounts: SalesOrderDiscount[],
    t: EntityManager,
  ): Promise<SalesOrderDiscount[]> {
    const persistedSalesOrderDiscounts =
      this.salesOrderDiscountRepository.create(salesOrderDiscounts);
    return t.save(persistedSalesOrderDiscounts);
  }
}
