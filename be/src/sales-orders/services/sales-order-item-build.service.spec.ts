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
