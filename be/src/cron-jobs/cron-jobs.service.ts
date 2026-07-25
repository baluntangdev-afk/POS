import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Not, Repository } from 'typeorm';
import { InventoryCount } from '../inventory-counts/entities/inventory-count.entity';
import { InventoryCountItem } from '../inventory-counts/entities/inventory-count-item.entity';
import { InventoryStock } from '../inventory-stocks/entities/inventory-stock.entity';
import {
  InventoryCountStatus,
  InventoryCountItemStatus,
} from '../inventory-counts/inventory-counts.enum';

/** Cron expression: every 2 minutes. */
const CRON_SYNC_INVENTORY_STOCK = '*/2 * * * *';

/**
 * Service for scheduled jobs (e.g. sync inventory stock from counts).
 */
@Injectable()
export class CronJobsService {
  private readonly logger = new Logger(CronJobsService.name);

  
  constructor(
    @InjectRepository(InventoryCount)
    private readonly inventoryCountRepository: Repository<InventoryCount>,
    @InjectRepository(InventoryCountItem)
    private readonly inventoryCountItemRepository: Repository<InventoryCountItem>,
    @InjectRepository(InventoryStock)
    private readonly inventoryStockRepository: Repository<InventoryStock>,
  ) {}

  /**
   * Runs every 10 minutes. Syncs inventory stock from inventory counts: for counts In Progress,
   * applies each Synced item's counted_qty to the matching stock. When all items of a count are
   * synced, marks the count Completed.
   */
  @Cron(CRON_SYNC_INVENTORY_STOCK)
  async syncInventoryStockFromCounts(): Promise<void> {
    const counts = await this.inventoryCountRepository.find({
      where: { status: Not(In([InventoryCountStatus.DRAFT, InventoryCountStatus.CANCELLED])) },
      select: { id: true },
    });

    if (counts.length === 0) {
      this.logger.log('No inventory counts In Progress, skip sync');
      return;
    }

    for (const count of counts) {
      await this.processCount(count.id);
    }
  }

  private async processCount(countId: string): Promise<void> {
    const pendingItems = await this.inventoryCountItemRepository.find({
      where: {
        inventoryCount: { id: countId },
        status: InventoryCountItemStatus.PENDING,
      },
      select: {
        id: true,
        countedQty: true,
        material: { id: true },
        unit: { id: true },
      },
      relations: { material: true, unit: true },
    });

    if (pendingItems.length === 0) {
      this.logger.log(`No pending inventory count items for count: ${countId}`);
      return;
    }

    await this.inventoryStockRepository.manager.transaction(async (tx) => {
      for (const item of pendingItems) {
        if (item.material?.id == null) continue;

        const stock = await tx.getRepository(InventoryStock).findOne({
          where: {
            material: { id: item.material.id },
            unit: { id: item.unit.id },
          },
          select: { id: true, quantityOnHand: true },
        });

        if (stock) {
          const currentQty = parseFloat(stock.quantityOnHand);
          const toSubtract = parseFloat(item.countedQty);
          const newQty = (currentQty - toSubtract).toFixed(2);
          await tx.getRepository(InventoryStock).update(stock.id, {
            quantityOnHand: newQty,
          });
        }

        await tx.getRepository(InventoryCountItem).update(item.id, {
          status: InventoryCountItemStatus.SYNCED,
        });

        await tx.getRepository(InventoryCount).update(countId, {
          status: InventoryCountStatus.COMPLETED,
        });
      }
    });

    this.logger.log(`Inventory count items synced for count: ${countId}`);
  }
}
