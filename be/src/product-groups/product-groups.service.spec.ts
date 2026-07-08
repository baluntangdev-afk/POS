import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ProductGroupsService } from './product-groups.service';
import { ProductGroup } from './entities/product-group.entity';
import { Product } from '../products/entities/product.entity';
import { BaseStatus } from '../utils/shared-enums';
import { ProductStatus } from '../products/products.enum';

describe('ProductGroupsService', () => {
  let service: ProductGroupsService;

  const mockProductGroupRepo = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    findAndCount: jest.fn().mockResolvedValue([[], 0]),
    update: jest.fn(),
    softDelete: jest.fn(),
  };

  const mockProductRepo = {
    findAndCount: jest.fn().mockResolvedValue([[], 0]),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockProductGroupRepo.findAndCount.mockResolvedValue([[], 0]);
    mockProductRepo.findAndCount.mockResolvedValue([[], 0]);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductGroupsService,
        { provide: getRepositoryToken(ProductGroup), useValue: mockProductGroupRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
      ],
    }).compile();

    service = module.get<ProductGroupsService>(ProductGroupsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should only query active categories', async () => {
      await service.findAll({ page: 1, limit: 20 } as never);

      expect(mockProductGroupRepo.findAndCount).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ status: BaseStatus.ACTIVE }),
        }),
      );
    });
  });

  describe('findProductsByGroupId', () => {
    it('should only query available, active products', async () => {
      await service.findProductsByGroupId(7, { page: 1, limit: 20 } as never);

      expect(mockProductRepo.findAndCount).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            productGroup: { id: 7 },
            isAvailable: true,
            status: ProductStatus.ACTIVE,
          }),
        }),
      );
    });
  });
});
