import { Test, TestingModule } from '@nestjs/testing';
import { getDataSourceToken, getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { User } from '../users/entities/user.entity';
import { BaseStatus } from '../utils/shared-enums';

const mockDataSource = { query: jest.fn() };

const mockPgRepo = {
  create: jest.fn(),
  save: jest.fn(),
  findOne: jest.fn(),
  update: jest.fn(),
  softDelete: jest.fn(),
  manager: { query: jest.fn() },
};

const mockUser = { id: 1, role: 'admin' } as User;

describe('CatalogService (admin methods)', () => {
  let service: CatalogService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatalogService,
        { provide: getDataSourceToken(), useValue: mockDataSource },
        { provide: getRepositoryToken(ProductGroup), useValue: mockPgRepo },
      ],
    }).compile();

    service = module.get<CatalogService>(CatalogService);
  });

  describe('createCategory', () => {
    it('saves a new ProductGroup and returns mapped response', async () => {
      const dto = { name: 'Beverages', description: 'Drinks', isActive: true };
      const saved = { id: 5, name: 'Beverages', description: 'Drinks', status: BaseStatus.ACTIVE };
      mockPgRepo.create.mockReturnValue(saved);
      mockPgRepo.save.mockResolvedValue(saved);

      const result = await service.createCategory(dto, mockUser);

      expect(mockPgRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'Beverages', status: BaseStatus.ACTIVE }),
      );
      expect(result).toMatchObject({
        id: '5',
        name: 'Beverages',
        is_active: true,
        product_count: 0,
      });
    });
  });

  describe('updateCategory', () => {
    it('throws NotFoundException when category does not exist', async () => {
      mockPgRepo.findOne.mockResolvedValue(null);

      await expect(service.updateCategory(999, { name: 'X' }, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('updates the category and returns mapped response', async () => {
      const existing = { id: 3, name: 'Old', description: null, status: BaseStatus.ACTIVE };
      const updated = { id: 3, name: 'New', description: null, status: BaseStatus.CANCELLED };
      mockPgRepo.findOne.mockResolvedValueOnce(existing).mockResolvedValueOnce(updated);
      mockPgRepo.update.mockResolvedValue(undefined);

      const result = await service.updateCategory(3, { name: 'New', isActive: false }, mockUser);

      expect(mockPgRepo.update).toHaveBeenCalled();
      expect(result).toMatchObject({ id: '3', name: 'New', is_active: false });
    });
  });

  describe('getProducts', () => {
    it('filters to active/available products by default', async () => {
      mockDataSource.query.mockResolvedValue([]);

      await service.getProducts();

      const [sql] = mockDataSource.query.mock.calls[0];
      expect(sql).toContain("p.status       = 'Active'");
      expect(sql).toContain('p.is_available = true');
    });

    it('drops the active/available filter when includeDisabled is true', async () => {
      mockDataSource.query.mockResolvedValue([]);

      await service.getProducts(undefined, undefined, true);

      const [sql] = mockDataSource.query.mock.calls[0];
      expect(sql).not.toContain("p.status       = 'Active'");
      expect(sql).not.toContain('p.is_available = true');
      expect(sql).toContain('p.deleted_at   IS NULL');
    });
  });
});
