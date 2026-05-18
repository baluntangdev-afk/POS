import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, In, Not, Repository } from 'typeorm';
import { SalesOrderItem } from '../entities/sales-order-item.entity';

/**
 * Sales order item persistence and queries. Single responsibility: repository operations for items.
 */
@Injectable()
export class SalesOrderItemsPersistenceService {
  constructor(
    @InjectRepository(SalesOrderItem)
    private readonly salesOrderItemRepository: Repository<SalesOrderItem>,
  ) {}

  /**
   * Persists sales order items under the given sales order id within the provided transaction.
   */
  async saveSalesOrderItems(
    soId: string,
    salesOrderItems: SalesOrderItem[],
    t: EntityManager,
  ): Promise<SalesOrderItem[]> {
    const salesOrderItemsWithSalesOrder = salesOrderItems.map((soi) =>
      this.salesOrderItemRepository.create({
        ...soi,
        salesOrder: { id: soId },
      }),
    );
    return t.save(salesOrderItemsWithSalesOrder);
  }

  async saveSalesOrderItemsWithChild(
    soId: string,
    salesOrderItems: SalesOrderItem[],
    t: EntityManager,
  ): Promise<SalesOrderItem[]> {
    const savedItems: SalesOrderItem[] = [];
    for (const soi of salesOrderItems) {
      // only check if item and not an add on
      if (!soi.addOn) {
        // check if item sequence is already in use (not the same item)
        const existingSequence = await t
          .createQueryBuilder(SalesOrderItem, 'soi')
          .select('id')
          .where('soi.item_sequence = :itemSequence', { itemSequence: soi.itemSequence! })
          .andWhere('soi.so_id = :soId', { soId })
          .andWhere('soi.id != :id', { id: soi.id })
          .getOne();

        // if existing, increment sequences
        if (existingSequence) {
          await t
            .createQueryBuilder(SalesOrderItem, 'soi')
            .update()
            .set({ itemSequence: () => 'itemSequence + 1' })
            .where('soi.so_id = :soId', { soId })
            .andWhere('soi.item_sequence >= :itemSequence', { itemSequence: soi.itemSequence! })
            .execute();
        }
      }

      savedItems.push(await t.save(soi));
    }

    return savedItems;
  }

  /**
   * Finds all sales order items for a sales order, optionally excluding one item by id.
   */
  async findSalesOrderItemsBySoId(
    soId: string,
    excludeSoItemId?: string,
  ): Promise<SalesOrderItem[]> {
    return this.salesOrderItemRepository.find({
      where: { salesOrder: { id: soId }, ...(excludeSoItemId ? { id: Not(excludeSoItemId) } : {}) },
    });
  }

  /**
   * Find all sales order items by ids and map them to a map by id
   */
  async findSalesOrderItemsByIds(ids: string[]): Promise<Map<string, SalesOrderItem>> {
    const salesOrderItems = await this.salesOrderItemRepository.find({
      select: {
        id: true,
        itemSequence: true,
        qty: true,
        unitPrice: true,
        itemDiscountRate: true,
        itemDiscountedPrice: true,
        vatExclusiveAmount: true,
        vatAmount: true,
        itemSubtotal: true,
        itemTotalAmount: true,
        itemPaidAmount: true,
        status: true,
        addOn: true,
        description: true,
        salesOrder: { id: true },
        currency: { id: true },
        uom: { id: true },
        recipe: { id: true },
        recipeItem: { id: true },
        productVariant: { id: true },
      },
      where: { id: In(ids) },
      relations: {
        salesOrder: true,
        currency: true,
        uom: true,
        recipe: true,
        recipeItem: true,
        productVariant: true,
      },
    });

    return new Map(salesOrderItems.map((soi) => [soi.id, soi]));
  }

  /**
   * Returns the maximum item sequence for the given sales order, or 0 if none.
   */
  async getMaxItemSequence(soId: string): Promise<number> {
    const maxItemSequence = await this.salesOrderItemRepository.findOne({
      select: { id: true, itemSequence: true },
      where: { salesOrder: { id: soId } },
      order: { itemSequence: 'DESC' },
    });
    return maxItemSequence?.itemSequence ?? 0;
  }

  /**
   * Returns the item sequence for the given sales order item id.
   * @throws NotFoundException when the item does not exist
   */
  async getItemSequence(soItemId: string): Promise<number> {
    const soi = await this.salesOrderItemRepository.findOne({
      select: { id: true, itemSequence: true },
      where: { id: soItemId },
    });
    if (!soi) {
      throw new NotFoundException(`Sales order item not found: ${soItemId}`);
    }
    return soi.itemSequence!;
  }

  /**
   * Ensures the sales order item exists.
   * @throws NotFoundException when the item does not exist
   */
  async validateSalesOrderItemExists(soItemId: string): Promise<void> {
    const exists = await this.salesOrderItemRepository.exists({
      where: { id: soItemId },
    });
    if (!exists) {
      throw new NotFoundException(`Sales order item not found: ${soItemId}`);
    }
  }

  /**
   * Returns ids of all sales order items that share the same item sequence as the given item.
   */
  async getSoItemIdsOfTheSameSequence(soId: string, soItemId: string): Promise<string[]> {
    const itemSequence = await this.getItemSequence(soItemId);
    const soItems = await this.salesOrderItemRepository.find({
      select: { id: true },
      where: { salesOrder: { id: soId }, itemSequence },
    });
    return soItems.map((soi) => soi.id);
  }
}
