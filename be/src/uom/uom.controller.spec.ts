import { Test, TestingModule } from '@nestjs/testing';
import { UomController } from './uom.controller';
import { UomService } from './uom.service';

describe('UomController', () => {
  let controller: UomController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UomController],
      providers: [UomService],
    }).compile();

    controller = module.get<UomController>(UomController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
