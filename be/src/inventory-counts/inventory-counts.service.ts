import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { InventoryCount } from './entities/inventory-count.entity';
import { OnEvent } from '@nestjs/event-emitter';
import { InventoryCountItem } from './entities/inventory-count-item.entity';
import { InventoryCountType } from './entities/inventory-count-type.entity';
import { SalesOrderEvents } from '../sales-orders/events';
import { OrderCreatedEvent } from '../sales-orders/events/order-created.event';
import { CreateInventoryCountMapper } from './mappers/create-inventory-count.mapper';
import dayjs from 'dayjs';
import { RecipesService } from '../recipes/recipes.service';
import { OrderCreatedEventItemDto } from '../sales-orders/dto/order-created-event-item.dto';
import { EntityHelper } from '../utils/entity.helper';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { OrderAppendEvent } from '../sales-orders/events/order-append.event';
import { OrderUpdatedEvent } from '../sales-orders/events/order-update.event';
import { OrderItemRemovedEvent } from '../sales-orders/events/order-item-removed.event';
import { InventoryCountStatus } from './inventory-counts.enum';
import { OrderConfirmedEvent } from '../sales-orders/events/order-confirmed.event';

@Injectable()
export class InventoryCountsService {
  private readonly logger = new Logger(InventoryCountsService.name);
  constructor(
    @InjectRepository(InventoryCount)
    private readonly inventoryCountRepository: Repository<InventoryCount>,
    @InjectRepository(InventoryCountItem)
    private readonly inventoryCountItemRepository: Repository<InventoryCountItem>,
    @InjectRepository(InventoryCountType)
    private readonly inventoryCountTypeRepository: Repository<InventoryCountType>,
    private readonly recipesService: RecipesService,
  ) {}

  @OnEvent(SalesOrderEvents.ORDER_CREATED)
  async handleOrderCreatedEvent(event: OrderCreatedEvent) {
    this.logger.log(`Handling order created event: ${event.salesOrderId}`);
    const { items, causer } = event.payload;
    const type = await this.getTypeByName('Sales Order');

    // create inventory count
    const inventoryCountItems = await this.createInventoryCountItems(items);
    const inventoryCount = CreateInventoryCountMapper.toEntity({
      countDate: dayjs().toDate(),
      createdById: causer.id,
      updatedById: causer.id,
      salesOrderId: event.salesOrderId,
      typeId: type.id,
    });

    await this.inventoryCountRepository.manager.transaction(async (transactionalEntityManager) => {
      const savedInventoryCount = await transactionalEntityManager.save(inventoryCount);

      const itemsWithInventoryCount = inventoryCountItems.map((item) => ({
        ...item,
        inventoryCount: savedInventoryCount,
      }));

      const persistedItems = this.inventoryCountItemRepository.create(itemsWithInventoryCount);
      await transactionalEntityManager.save(persistedItems);
    });

    this.logger.log(`Inventory count created for order: ${event.salesOrderId}`);
  }

  @OnEvent(SalesOrderEvents.ORDER_APPEND)
  async handleOrderAppendEvent(event: OrderAppendEvent) {
    this.logger.log(`Handling order append event: ${event.salesOrderId}`);
    const { items } = event.payload;

    // get existing inventory count
    const inventoryCount = await this.findInventoryCountBySalesOrderId(event.salesOrderId);

    // append inventory count items
    const inventoryCountItems = await this.createInventoryCountItems(items);

    const itemsWithInventoryCount = inventoryCountItems.map((item) => ({
      ...item,
      inventoryCount: inventoryCount,
    }));

    const persistedItems = this.inventoryCountItemRepository.create(itemsWithInventoryCount);
    await this.inventoryCountItemRepository.save(persistedItems);

    this.logger.log(`Inventory count items appended for order: ${event.salesOrderId}`);
  }

  @OnEvent(SalesOrderEvents.ORDER_UPDATE)
  async handleOrderUpdateEvent(event: OrderUpdatedEvent) {
    this.logger.log(`Handling order update event: ${event.salesOrderId}`);
    const { items, oldSoItemIds } = event.payload;

    // get existing inventory count
    const inventoryCount = await this.findInventoryCountBySalesOrderId(event.salesOrderId);

    // update inventory count items
    const inventoryCountItems = await this.createInventoryCountItems(items);

    const itemsWithInventoryCount = inventoryCountItems.map((item) => ({
      ...item,
      inventoryCount: inventoryCount,
    }));

    const persistedItems = this.inventoryCountItemRepository.create(itemsWithInventoryCount);
    await this.inventoryCountItemRepository.manager.transaction(
      async (transactionalEntityManager) => {
        // delete existing inventory count items
        await transactionalEntityManager.delete(InventoryCountItem, {
          salesOrderItem: { id: In(oldSoItemIds) },
        });

        // save new inventory count items
        await transactionalEntityManager.save(persistedItems);
      },
    );

    this.logger.log(`Inventory count items updated for order: ${event.salesOrderId}`);
  }

  @OnEvent(SalesOrderEvents.ORDER_ITEM_REMOVED)
  async handleOrderItemRemovedEvent(event: OrderItemRemovedEvent) {
    this.logger.log(`Handling order item removed event: ${event.salesOrderId}`);
    const { soItemIds } = event.payload;

    const inventoryCount = await this.findInventoryCountBySalesOrderId(event.salesOrderId);

    await this.inventoryCountItemRepository.delete({
      salesOrderItem: { id: In(soItemIds) },
      inventoryCount: { id: inventoryCount.id },
    });

    this.logger.log(`Inventory count items removed for order: ${event.salesOrderId}`);
  }

  @OnEvent(SalesOrderEvents.ORDER_CONFIRMED)
  async handleOrderConfirmedEvent(event: OrderConfirmedEvent) {
    this.logger.log(`Handling order confirmed event: ${event.soId}`);

    await this.inventoryCountRepository.update(
      { salesOrder: { id: event.soId } },
      { status: InventoryCountStatus.IN_PROGRESS },
    );

    this.logger.log(`Inventory count status updated to in progress for order: ${event.soId}`);
  }

  private async findInventoryCountBySalesOrderId(salesOrderId: string) {
    const inventoryCount = await this.inventoryCountRepository.findOne({
      where: { salesOrder: { id: salesOrderId } },
    });

    if (!inventoryCount) {
      throw new Error(`Inventory count not found for order: ${salesOrderId}`);
    }

    return inventoryCount;
  }

  private async getTypeByName(name: string) {
    const type = await this.inventoryCountTypeRepository.findOne({
      where: { name },
      select: { id: true },
    });

    if (!type) {
      throw Error('Inventory count type not found');
    }

    return type;
  }

  private async createInventoryCountItems(items: OrderCreatedEventItemDto[]) {
    // get recipes
    const recipes = await this.recipesService.findRecipesByIdsWithRecipeItems(
      items.map((item) => item.recipeId),
    );

    const recipeMap = new Map(recipes.map((recipe) => [recipe.id, recipe]));
    const recipeItemMap = new Map(
      recipes.flatMap((recipe) => recipe.recipeItems.map((item) => [item.id, item])),
    );

    const inventoryCountItems: InventoryCountItem[] = [];
    for (const item of items) {
      const recipe = recipeMap.get(item.recipeId);

      if (!recipe) {
        throw new Error(`Recipe not found for item ${item.recipeId}`);
      }

      if (item.isAddOn) {
        // if no recipe item, meaning not a material or recipe (HOT, COLD)
        if (!item.recipeItemId) continue;

        const recipeItem = recipeItemMap.get(item.recipeItemId);

        if (!recipeItem) continue;

        const inventoryCountItem = new InventoryCountItem();

        const calculatedQty = (item.quantity * parseFloat(recipeItem.quantity)).toFixed(2);
        const varianceQty = (0).toFixed(2); // since these are all calculated via system qty, variance is always 0
        inventoryCountItem.salesOrderItem = EntityHelper.toIdEntity<SalesOrderItem>(item.soItemId);
        inventoryCountItem.systemQty = calculatedQty;
        inventoryCountItem.countedQty = calculatedQty;
        inventoryCountItem.unit = recipeItem.unit;
        inventoryCountItem.material = recipeItem.material;
        inventoryCountItem.varianceQty = varianceQty;

        inventoryCountItems.push(inventoryCountItem);
      } else {
        for (const recipeItem of recipe.recipeItems) {
          // skip extra because it will be handled separately
          if (recipeItem.extra) continue;

          const inventoryCountItem = new InventoryCountItem();

          const calculatedQty = (item.quantity * parseFloat(recipeItem.quantity)).toFixed(2);
          const varianceQty = (0).toFixed(2); // since these are all calculated via system qty, variance is always 0
          inventoryCountItem.salesOrderItem = EntityHelper.toIdEntity<SalesOrderItem>(
            item.soItemId,
          );
          inventoryCountItem.systemQty = calculatedQty;
          inventoryCountItem.countedQty = calculatedQty;
          inventoryCountItem.unit = recipeItem.unit;
          inventoryCountItem.material = recipeItem.material;
          inventoryCountItem.varianceQty = varianceQty;

          inventoryCountItems.push(inventoryCountItem);
        }
      }
    }

    return inventoryCountItems;
  }
}
