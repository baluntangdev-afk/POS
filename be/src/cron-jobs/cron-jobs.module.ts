import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CronJobsService } from './cron-jobs.service';
import { InventoryCount } from '../inventory-counts/entities/inventory-count.entity';
import { InventoryCountItem } from '../inventory-counts/entities/inventory-count-item.entity';
import { InventoryStock } from '../inventory-stocks/entities/inventory-stock.entity';

@Module({
  imports: [TypeOrmModule.forFeature([InventoryCount, InventoryCountItem, InventoryStock])],
  providers: [CronJobsService],
  exports: [CronJobsService],
})
export class CronJobsModule {}
