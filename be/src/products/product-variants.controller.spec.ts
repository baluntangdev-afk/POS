import { Test, TestingModule } from '@nestjs/testing';
import { ProductVariantsController } from './product-variants.controller';
import { ProductVariantsService } from './product-variants.service';
import { CreateProductVariantDto } from './dto/create-product.variant.dto';
import { ProductVariantDto } from './dto/product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';
import { User } from '../users/entities/user.entity';

describe('ProductVariantsController', () => {
  let controller: ProductVariantsController;
  let service: ProductVariantsService;

  const mockUser: User = {
    id: 1,
    email: 'test@example.com',
    createdAt: new Date(),
    updatedAt: new Date(),
  } as User;

  const mockProductVariantDto: ProductVariantDto = {
    id: 1,
    productId: 1,
    name: 'Large',
    isDefault: false,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ProductVariantsController],
      providers: [
        {
          provide: ProductVariantsService,
          useValue: {
            create: jest.fn(),
            findProductVariantsByProductId: jest.fn(),
            findOne: jest.fn(),
            update: jest.fn(),
            remove: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<ProductVariantsController>(ProductVariantsController);
    service = module.get<ProductVariantsService>(ProductVariantsService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('should create a product variant', async () => {
      const createDto: CreateProductVariantDto = {
        productId: 1,
        name: 'Large',
        isDefault: false,
      };

      jest.spyOn(service, 'create').mockResolvedValue(mockProductVariantDto);

      const result = await controller.create(createDto, mockUser);

      expect(service.create).toHaveBeenCalledWith(createDto, mockUser);
      expect(result).toEqual(mockProductVariantDto);
    });
  });

  describe('findByProductId', () => {
    it('should return product variants by product ID', async () => {
      jest.spyOn(service, 'findByProductId').mockResolvedValue([mockProductVariantDto]);

      const result = await controller.findByProductId('1');

      expect(service.findByProductId).toHaveBeenCalledWith(1);
      expect(result).toEqual([mockProductVariantDto]);
    });
  });

  describe('findOne', () => {
    it('should return a single product variant', async () => {
      jest.spyOn(service, 'findOne').mockResolvedValue(mockProductVariantDto);

      const result = await controller.findOne('1');

      expect(service.findOne).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockProductVariantDto);
    });
  });

  describe('update', () => {
    it('should update a product variant', async () => {
      const updateDto: UpdateProductVariantDto = {
        name: 'Extra Large',
      };

      jest.spyOn(service, 'update').mockResolvedValue(mockProductVariantDto);

      const result = await controller.update('1', updateDto, mockUser);

      expect(service.update).toHaveBeenCalledWith(1, updateDto, mockUser);
      expect(result).toEqual(mockProductVariantDto);
    });
  });

  describe('remove', () => {
    it('should remove a product variant', async () => {
      jest
        .spyOn(service, 'remove')
        .mockResolvedValue({ message: 'Product variant deleted successfully' });

      const result = await controller.remove('1', mockUser);

      expect(service.remove).toHaveBeenCalledWith(1, mockUser);
      expect(result).toEqual({ message: 'Product variant deleted successfully' });
    });
  });
});
