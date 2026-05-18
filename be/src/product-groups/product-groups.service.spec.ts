import { Test, TestingModule } from '@nestjs/testing';
import { ProductGroupsService } from './product-groups.service';

describe('ProductGroupsService', () => {
  let service: ProductGroupsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ProductGroupsService],
    }).compile();

    service = module.get<ProductGroupsService>(ProductGroupsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
