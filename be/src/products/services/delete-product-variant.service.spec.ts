import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { DeleteProductVariantService } from './delete-product-variant.service';
import { RecomputeProductPriceService } from './recompute-product-price.service';
import { ProductVariant } from '../entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';

describe('DeleteProductVariantService', () => {
  let service: DeleteProductVariantService;

  const mockUser = { id: 1 } as User;

  const mockVariantsRepo = {
    findOne: jest.fn(),
    update: jest.fn(),
    softDelete: jest.fn(),
  };

  const mockRecomputeProductPriceService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeleteProductVariantService,
        { provide: getRepositoryToken(ProductVariant), useValue: mockVariantsRepo },
        { provide: RecomputeProductPriceService, useValue: mockRecomputeProductPriceService },
      ],
    }).compile();

    service = module.get<DeleteProductVariantService>(DeleteProductVariantService);
  });

  it('should throw NotFoundException when the variant does not exist', async () => {
    mockVariantsRepo.findOne.mockResolvedValue(null);

    await expect(service.execute(99, mockUser)).rejects.toThrow(NotFoundException);
  });

  it('should soft delete the variant and recompute the product price', async () => {
    mockVariantsRepo.findOne.mockResolvedValue({ id: 3, product: { id: 9 } });
    mockVariantsRepo.update.mockResolvedValue(undefined);
    mockVariantsRepo.softDelete.mockResolvedValue(undefined);

    await service.execute(3, mockUser);

    expect(mockVariantsRepo.softDelete).toHaveBeenCalledWith(3);
    expect(mockRecomputeProductPriceService.execute).toHaveBeenCalledWith(9);
  });
});
