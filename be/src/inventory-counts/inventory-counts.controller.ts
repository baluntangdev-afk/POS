import { Controller } from '@nestjs/common';
import { InventoryCountsService } from './inventory-counts.service';

@Controller('inventory-counts')
export class InventoryCountsController {
  constructor(private readonly inventoryCountsService: InventoryCountsService) {}
}
