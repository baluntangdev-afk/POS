import { Test, TestingModule } from '@nestjs/testing';
import { TaxCategoriesService } from './tax-categories.service';

describe('TaxCategoriesService', () => {
  let service: TaxCategoriesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TaxCategoriesService],
    }).compile();

    service = module.get<TaxCategoriesService>(TaxCategoriesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
