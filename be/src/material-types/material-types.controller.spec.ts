import { Test, TestingModule } from '@nestjs/testing';
import { MaterialTypesController } from './material-types.controller';
import { MaterialTypesService } from './material-types.service';

describe('MaterialTypesController', () => {
  let controller: MaterialTypesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MaterialTypesController],
      providers: [MaterialTypesService],
    }).compile();

    controller = module.get<MaterialTypesController>(MaterialTypesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
