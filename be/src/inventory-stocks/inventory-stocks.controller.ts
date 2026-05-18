import { Controller } from '@nestjs/common';
import { InventoryStocksService } from './inventory-stocks.service';

@Controller('inventory-stocks')
export class InventoryStocksController {
  constructor(private readonly inventoryStocksService: InventoryStocksService) {}
}
