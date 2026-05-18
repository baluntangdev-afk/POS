import { Test, TestingModule } from '@nestjs/testing';
import { InventoryStocksController } from './inventory-stocks.controller';
import { InventoryStocksService } from './inventory-stocks.service';

describe('InventoryStocksController', () => {
  let controller: InventoryStocksController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [InventoryStocksController],
      providers: [InventoryStocksService],
    }).compile();

    controller = module.get<InventoryStocksController>(InventoryStocksController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
