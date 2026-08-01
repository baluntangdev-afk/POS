import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { FindDistinctVariantNamesService } from './find-distinct-variant-names.service';
import { ProductVariant } from '../entities/product-variant.entity';

describe('FindDistinctVariantNamesService', () => {
  let service: FindDistinctVariantNamesService;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    getRawMany: jest.fn(),
  };

  const mockVariantsRepo = {
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.orderBy.mockReturnThis();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FindDistinctVariantNamesService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
      ],
    }).compile();

    service = module.get<FindDistinctVariantNamesService>(FindDistinctVariantNamesService);
  });

  it('should return distinct variant names in ascending order', async () => {
    mockQueryBuilder.getRawMany.mockResolvedValue([{ name: 'Regular' }, { name: 'Venti' }]);

    const result = await service.execute();

    expect(result).toEqual(['Regular', 'Venti']);
  });
});
