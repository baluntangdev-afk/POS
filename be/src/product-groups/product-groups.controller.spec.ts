import { Test, TestingModule } from '@nestjs/testing';
import { ProductGroupsController } from './product-groups.controller';
import { ProductGroupsService } from './product-groups.service';

describe('ProductGroupsController', () => {
  let controller: ProductGroupsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProductGroupsController],
      providers: [ProductGroupsService],
    }).compile();

    controller = module.get<ProductGroupsController>(ProductGroupsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
