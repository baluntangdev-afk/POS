import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateProductService } from './create-product.service';
import { FindProductGroupService } from './find-product-group.service';
import { Product } from '../entities/product.entity';
import { User } from '../../users/entities/user.entity';

describe('CreateProductService', () => {
  let service: CreateProductService;

  const mockUser = { id: 1 } as User;
  const mockProductGroup = { id: 2, name: 'Beverages' };

  const mockProductsRepo = {
    create: jest.fn((payload) => payload),
    save: jest.fn((entity) => Promise.resolve({ id: 10, ...entity })),
  };

  const mockFindProductGroupService = { execute: jest.fn().mockResolvedValue(mockProductGroup) };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockFindProductGroupService.execute.mockResolvedValue(mockProductGroup);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateProductService,
        { provide: getRepositoryToken(Product), useValue: mockProductsRepo },
        { provide: FindProductGroupService, useValue: mockFindProductGroupService },
      ],
    }).compile();

    service = module.get<CreateProductService>(CreateProductService);
  });

  it('should default isAvailable to true when not provided', async () => {
    await service.execute({ groupId: 2, name: 'Cappuccino' }, undefined as never, mockUser, '');

    expect(mockProductsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ isAvailable: true }),
    );
  });

  it('should persist isAvailable: false when explicitly provided', async () => {
    await service.execute(
      { groupId: 2, name: 'Cappuccino', isAvailable: false },
      undefined as never,
      mockUser,
      '',
    );

    expect(mockProductsRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ isAvailable: false }),
    );
  });
});
