import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryStocksService } from './inventory-stocks.service';
import { InventoryStocksController } from './inventory-stocks.controller';
import { InventoryStock } from './entities/inventory-stock.entity';

@Module({
  imports: [TypeOrmModule.forFeature([InventoryStock])],
  controllers: [InventoryStocksController],
  providers: [InventoryStocksService],
  exports: [InventoryStocksService],
})
export class InventoryStocksModule {}
