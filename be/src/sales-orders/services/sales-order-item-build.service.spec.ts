import { ProductVariant } from '../../products/entities/product-variant.entity';
import { User } from '../../users/entities/user.entity';
import { CreateSalesOrderItemDto } from '../dto/create-sales-order/sales-order-item.dto';
import { SalesOrderItemBuildService } from './sales-order-item-build.service';

/**
 * A CSV-imported variant has no recipe (the CSV schema carries no ingredient
 * data). Ordering must still succeed — a missing recipe means "no inventory
 * deduction", which inventory validation and the order-created event already
 * handle. Previously enrichProduct threw "Recipe not found", surfacing as a 500.
 */
describe('SalesOrderItemBuildService.generateSalesOrderItems (variant without recipe)', () => {
  function buildService(variant: ProductVariant) {
    const recipesService = {
      // No recipe exists for the variant.
      findRecipeIdsByProductVariantIds: jest.fn().mockResolvedValue(new Map()),
    };
    const productsService = {
      findProductVariantsByIds: jest.fn().mockResolvedValue(new Map([[variant.id, variant]])),
    };
    const modifierGroupsService = {
      findModifierOptionWithRelationById: jest.fn().mockResolvedValue(new Map()),
    };

    return new SalesOrderItemBuildService(
      recipesService as never,
      productsService as never,
      modifierGroupsService as never,
      {} as never,
      {} as never,
      {} as never,
    );
  }

  function buildProductDto(): CreateSalesOrderItemDto {
    return {
      productVariantId: 9,
      quantity: 4,
      price: 337,
      modifierGroups: [],
    } as unknown as CreateSalesOrderItemDto;
  }

  const variant = {
    id: 9,
    name: 'Large',
    product: { name: 'Latte' },
  } as unknown as ProductVariant;

  it('does not throw when the variant has no recipe', async () => {
    const service = buildService(variant);

    await expect(
      service.generateSalesOrderItems([buildProductDto()], {} as User),
    ).resolves.toBeDefined();
  });

  it('keeps the product variant and leaves recipe null', async () => {
    const service = buildService(variant);

    const { salesOrderItems } = await service.generateSalesOrderItems(
      [buildProductDto()],
      {} as User,
    );

    expect(salesOrderItems).toHaveLength(1);
    expect(salesOrderItems[0].productVariant?.id).toBe(9);
    expect(salesOrderItems[0].recipe).toBeNull();
  });
});

describe('SalesOrderItemBuildService.generateSalesOrderItems (Senior/PWD beneficiary)', () => {
  function buildServiceWithDiscount(
    variant: ProductVariant,
    discount: { id: number; name: string; value: string; type: string },
  ) {
    const recipesService = {
      findRecipeIdsByProductVariantIds: jest.fn().mockResolvedValue(new Map()),
    };
    const productsService = {
      findProductVariantsByIds: jest.fn().mockResolvedValue(new Map([[variant.id, variant]])),
    };
    const modifierGroupsService = {
      findModifierOptionWithRelationById: jest.fn().mockResolvedValue(new Map()),
    };
    const discountsService = {
      findByIdsToMap: jest.fn().mockResolvedValue(new Map([[discount.id, discount]])),
    };

    return new SalesOrderItemBuildService(
      recipesService as never,
      productsService as never,
      modifierGroupsService as never,
      {} as never,
      {} as never,
      discountsService as never,
    );
  }

  const variant = {
    id: 9,
    name: 'Large',
    product: { name: 'Latte' },
  } as unknown as ProductVariant;

  const discount = { id: 1, name: 'Senior Citizen / PWD', value: '20', type: 'percentage' };

  it('persists the beneficiary id number and name onto the sales order item', async () => {
    const service = buildServiceWithDiscount(variant, discount);
    const productDto = {
      productVariantId: 9,
      quantity: 4,
      price: 337,
      modifierGroups: [],
      discount: {
        id: 1,
        name: 'Senior Citizen / PWD',
        value: 20,
        idNumber: 'SC-2024-00001',
        beneficiaryName: 'Juan Dela Cruz',
      },
    } as unknown as CreateSalesOrderItemDto;

    const { salesOrderItems } = await service.generateSalesOrderItems([productDto], {} as User);

    expect(salesOrderItems[0].discountBeneficiaryIdNumber).toBe('SC-2024-00001');
    expect(salesOrderItems[0].discountBeneficiaryName).toBe('Juan Dela Cruz');
  });
});
