import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateProductVariantService } from './create-product-variant.service';
import { FindProductService } from './find-product.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantStatus } from '../products.enum';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('CreateProductVariantService', () => {
  let service: CreateProductVariantService;

  const mockUser = { id: 1 } as User;
  const mockProduct = { id: 9 } as Product;

  const mockVariantsRepo = {
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockFindProductService = { execute: jest.fn() };
  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: FindProductService, useValue: mockFindProductService },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<CreateProductVariantService>(CreateProductVariantService);
  });

  it('should persist price and isDefault, then recompute the product price', async () => {
    mockFindProductService.execute.mockResolvedValue(mockProduct);
    const createdEntity = {
      id: 3,
      name: 'Large',
      price: 150,
      isDefault: true,
      status: ProductVariantStatus.ACTIVE,
      product: mockProduct,
    };
    mockVariantsRepo.create.mockReturnValue(createdEntity);
    mockVariantsRepo.save.mockResolvedValue(createdEntity);

    const result = await service.execute(
      { productId: 9, name: 'Large', price: 150, isDefault: true },
      mockUser,
    );

    expect(mockVariantsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Large', price: 150, isDefault: true, product: mockProduct }),
    );
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
    expect(result).toEqual({
      id: 3,
      productId: 9,
      name: 'Large',
      price: 150,
      isDefault: true,
      isActive: true,
    });
  });
});
