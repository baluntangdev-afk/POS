import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { UpdateProductVariantService } from './update-product-variant.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';

describe('UpdateProductVariantService', () => {
  let service: UpdateProductVariantService;

  const mockUser = { id: 1 } as User;

  const mockVariantsRepo = {
    findOne: jest.fn(),
    update: jest.fn(),
  };

  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<UpdateProductVariantService>(UpdateProductVariantService);
  });

  it('should throw NotFoundException when the variant does not exist', async () => {
    mockVariantsRepo.findOne.mockResolvedValue(null);

    await expect(
      service.execute(99, { name: 'Large', price: 150, isDefault: true }, mockUser),
    ).rejects.toThrow(NotFoundException);
  });

  it('should persist the new price and recompute the product price', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);

    await service.execute(3, { name: 'Large', price: 175, isDefault: true }, mockUser);

    expect(mockVariantsRepo.update).toHaveBeenCalledWith(
      3,
      expect.objectContaining({ name: 'Large', price: 175, isDefault: true }),
    );
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
  });
});
