import { Test, TestingModule } from '@nestjs/testing';
import { TaxCategoriesController } from './tax-categories.controller';
import { TaxCategoriesService } from './tax-categories.service';

describe('TaxCategoriesController', () => {
  let controller: TaxCategoriesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TaxCategoriesController],
      providers: [TaxCategoriesService],
    }).compile();

    controller = module.get<TaxCategoriesController>(TaxCategoriesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
