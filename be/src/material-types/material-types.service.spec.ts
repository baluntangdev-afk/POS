import { Test, TestingModule } from '@nestjs/testing';
import { MaterialTypesService } from './material-types.service';

describe('MaterialTypesService', () => {
  let service: MaterialTypesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MaterialTypesService],
    }).compile();

    service = module.get<MaterialTypesService>(MaterialTypesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
