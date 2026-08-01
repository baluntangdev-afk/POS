import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { Product } from '../entities/product.entity';

describe('RecomputeProductPriceService', () => {
  let service: RecomputeProductPriceService;

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getRawOne: jest.fn(),
  };

  const mockVariantsRepo = {
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
  };

  const mockProductsRepo = {
    update: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockQueryBuilder.select.mockReturnThis();
    mockQueryBuilder.where.mockReturnThis();
    mockQueryBuilder.andWhere.mockReturnThis();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RecomputeProductPriceService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
      ],
    }).compile();

    service = module.get<RecomputeProductPriceService>(RecomputeProductPriceService);
  });

  it('should set the product price to the minimum active variant price', async () => {
    mockQueryBuilder.getRawOne.mockResolvedValue({ min: '45.50' });

    await service.execute(7);

    expect(mockVariantsRepo.createQueryBuilder).toHaveBeenCalledWith('pv');
    expect(mockProductsRepo.update).toHaveBeenCalledWith(7, { price: '45.5' });
  });

  it('should set the product price to 0 when the product has no active variants', async () => {
    mockQueryBuilder.getRawOne.mockResolvedValue({ min: null });

    await service.execute(7);

    expect(mockProductsRepo.update).toHaveBeenCalledWith(7, { price: '0' });
  });
});
