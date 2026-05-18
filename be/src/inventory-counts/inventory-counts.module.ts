import { Module } from '@nestjs/common';
import { InventoryCountsService } from './inventory-counts.service';
import { InventoryCountsController } from './inventory-counts.controller';
import { InventoryCount } from './entities/inventory-count.entity';
import { InventoryCountItem } from './entities/inventory-count-item.entity';
import { InventoryCountType } from './entities/inventory-count-type.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecipesModule } from '../recipes/recipes.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([InventoryCount, InventoryCountItem, InventoryCountType]),
    RecipesModule,
  ],
  controllers: [InventoryCountsController],
  providers: [InventoryCountsService],
})
export class InventoryCountsModule {}
