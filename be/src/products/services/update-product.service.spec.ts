import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UpdateProductService } from './update-product.service';
import { FindProductGroupService } from './find-product-group.service';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('UpdateProductService', () => {
  let service: UpdateProductService;

  const mockUser = { id: 1 } as User;

  const mockProductsRepo = { update: jest.fn() };
  const mockFindProductGroupService = { execute: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateProductService,
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
        { provide: FindProductGroupService, useValue: mockFindProductGroupService },
      ],
    }).compile();

    service = module.get<UpdateProductService>(UpdateProductService);
  });

  it('should persist isAvailable when provided', async () => {
    await service.execute(5, { isAvailable: false }, undefined as never, mockUser, '');

    expect(mockProductsRepo.update).toHaveBeenCalledWith(
      5,
      expect.objectContaining({ isAvailable: false }),
    );
  });

  it('should not touch isAvailable when omitted', async () => {
    await service.execute(5, { name: 'New name' }, undefined as never, mockUser, '');

    const [, payload] = mockProductsRepo.update.mock.calls[0];
    expect(payload.isAvailable).toBeUndefined();
  });
});
