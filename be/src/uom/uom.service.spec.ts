import { Test, TestingModule } from '@nestjs/testing';
import { UomService } from './uom.service';

describe('UomService', () => {
  let service: UomService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UomService],
    }).compile();

    service = module.get<UomService>(UomService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
