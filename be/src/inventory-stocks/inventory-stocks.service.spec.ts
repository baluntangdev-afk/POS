import { Test, TestingModule } from '@nestjs/testing';
import { InventoryStocksService } from './inventory-stocks.service';

describe('InventoryStocksService', () => {
  let service: InventoryStocksService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [InventoryStocksService],
    }).compile();

    service = module.get<InventoryStocksService>(InventoryStocksService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
