import { Injectable } from '@nestjs/common';

import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { SalesOrderDiscount } from '../entities/sales-order-discount.entity';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { CreateSalesOrderItemDto } from '../dto/create-sales-order/sales-order-item.dto';
import { CreateSalesOrderMapper } from '../mapper/create-sales-order.mapper';
import { User } from '../../users/entities/user.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';

import { RecipesService } from '../../recipes/recipes.service';
import { ProductsService } from '../../products/products.service';
import { ModifierGroupsService } from '../../modifier-groups/modifier-groups.service';
import { SalesOrderItemsPersistenceService } from './sales-order-items-persistence.service';
import { ApplyDiscountDto } from '../dto/add-discount/apply-discount.dto';
import { SalesOrderDiscountPersistenceService } from './sales-order-discount-persistence.service';
import { DiscountsService } from '../../discounts/discounts.service';
import { DECIMAL_PLACES } from '../../utils/calculation.helper';
import { ApplyDiscountToItemMapper } from '../mapper/apply-discount-to-item.mapper';
import { SalesOrderDiscountMapper } from '../mapper/sales-order-discount.mapper';
import { ApplyDiscountSalesOrderItemDto } from '../dto/add-discount/apply-discount-sales-order-item.dto';
import { Discount } from '../../discounts/entities/discount.entity';
import type { LookupData, ResolveDiscountContextResult } from '../sales-order.interface';

/**
 * Builds sales order item entities from create DTO (products and add-ons). Single responsibility.
 */
@Injectable()
export class SalesOrderItemBuildService {
  constructor(
    private readonly recipesService: RecipesService,
    private readonly productsService: ProductsService,
    private readonly modifierGroupsService: ModifierGroupsService,
    private readonly salesOrderItemsPersistence: SalesOrderItemsPersistenceService,
    private readonly salesOrderDiscountPersistence: SalesOrderDiscountPersistenceService,
    private readonly discountsService: DiscountsService,
  ) {}

  /**
   * Builds sales order item entities from create DTO products (including add-ons from modifier options).
   */
  async generateSalesOrderItems(
    products: CreateSalesOrderDto['products'],
    causer: User,
    soId?: string,
    soItemId?: string,
  ): Promise<{ salesOrderItems: SalesOrderItem[]; salesOrderDiscounts: SalesOrderDiscount[] }> {
    const lookup = await this.loadLookupData(products);
    const maxItemSequence = soId
      ? await this.salesOrderItemsPersistence.getMaxItemSequence(soId)
      : 0;
    const itemSequenceForUpdate = soItemId
      ? await this.salesOrderItemsPersistence.getItemSequence(soItemId)
      : null;

    const salesOrderItems: SalesOrderItem[] = [];
    const salesOrderDiscounts: SalesOrderDiscount[] = [];

    const hasDiscounts = products.some((p) => p.discount);
    if (!hasDiscounts) {
      for (const [index, product] of products.entries()) {
        const itemSequence = itemSequenceForUpdate ?? maxItemSequence + index + 1;
        this.enrichProduct(product, lookup, causer, itemSequence);
        salesOrderItems.push(CreateSalesOrderMapper.toSalesOrderItemEntity(product));
        salesOrderItems.push(...this.buildAddOnItemsForProduct(product, lookup.modifierOptionMap));
      }
      return { salesOrderItems, salesOrderDiscounts };
    }

    const discountIds = products.filter((p) => p.discount).map((p) => p.discount!.id);
    const discountMap = await this.discountsService.findByIdsToMap(discountIds);

    let nextSequence = itemSequenceForUpdate ?? maxItemSequence + 1;
    for (const product of products) {
      const itemSequence = itemSequenceForUpdate ?? nextSequence;
      this.enrichProduct(product, lookup, causer, itemSequence);

      const salesOrderItem = CreateSalesOrderMapper.toSalesOrderItemEntity(product);
      let itemDiscount: SalesOrderDiscount | null = null;

      if (product.discount) {
        const discount = discountMap.get(product.discount.id);
        if (!discount) {
          throw new Error(`Discount not found for id ${product.discount.id}`);
        }

        const amounts = ApplyDiscountToItemMapper.computeItemDiscountAmounts(
          discount,
          Number(salesOrderItem.vatExclusiveAmount),
        );
        const appliedAmount = ApplyDiscountToItemMapper.computeAppliedAmount(
          Number(salesOrderItem.vatExclusiveAmount),
          amounts.discountedUnitPrice,
          Number(salesOrderItem.qty),
        );

        ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
          salesOrderItem,
          parseFloat(discount.value),
          amounts,
          causer,
        );

        itemDiscount = SalesOrderDiscountMapper.toEntityWithAppliedAmount(
          '', // soId will be set later during persistence
          discount,
          appliedAmount,
          causer,
        );

        salesOrderItem.salesOrderDiscount = itemDiscount;
        salesOrderDiscounts.push(itemDiscount);
      }

      salesOrderItems.push(salesOrderItem);

      const addOnItems = this.buildAddOnItemsForProduct(product, lookup.modifierOptionMap);
      if (product.discount && itemDiscount) {
        const discount = discountMap.get(product.discount.id)!;
        for (const addOnItem of addOnItems) {
          const amounts = ApplyDiscountToItemMapper.computeItemDiscountAmounts(
            discount,
            Number(addOnItem.vatExclusiveAmount),
          );
          ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
            addOnItem,
            parseFloat(discount.value),
            amounts,
            causer,
          );

          const appliedAmount = ApplyDiscountToItemMapper.computeAppliedAmount(
            Number(addOnItem.vatExclusiveAmount),
            amounts.discountedUnitPrice,
            Number(addOnItem.qty),
          );

          const addOnDiscount = SalesOrderDiscountMapper.toEntityWithAppliedAmount(
            '', // soId will be set later during persistence
            discount,
            appliedAmount,
            causer,
          );

          addOnItem.salesOrderDiscount = addOnDiscount;
          salesOrderDiscounts.push(addOnDiscount);
        }
      }

      salesOrderItems.push(...addOnItems);
      nextSequence = Math.max(...salesOrderItems.map((item) => item.itemSequence ?? 0)) + 1;
    }

    return { salesOrderItems, salesOrderDiscounts };
  }

  /**
   * Builds sales order items with discounts applied and the corresponding sales order discount records.
   * Applied amount per discount = (unitPrice - discountedUnitPrice) × qty for that line.
   */
  async applyDiscountsToSalesOrderItems(
    items: ApplyDiscountDto['salesOrderItems'],
    causer: User,
  ): Promise<{ salesOrderItems: SalesOrderItem[]; salesOrderDiscounts: SalesOrderDiscount[] }> {
    const salesOrderItems: SalesOrderItem[] = [];
    const salesOrderDiscounts: SalesOrderDiscount[] = [];

    const discountIds = items.map((item, index) => {
      if (item.discounts?.id == null) {
        throw new Error(
          `salesOrderItems[${index}] is missing discounts or discounts.id (item id: ${item.id ?? 'unknown'})`,
        );
      }
      return item.discounts.id;
    });

    const [discountMap, existingSalesOrderItems] = await Promise.all([
      this.discountsService.findByIdsToMap(discountIds),
      this.salesOrderItemsPersistence.findSalesOrderItemsByIds(items.map((item) => item.id)),
    ]);

    const parentItems = items.filter((item) => !item.addOn);
    let nextSequence = parentItems[0].itemSequence;
    for (const item of parentItems) {
      const ctx = this.resolveDiscountContext(item, existingSalesOrderItems, discountMap);

      salesOrderDiscounts.push(
        SalesOrderDiscountMapper.toEntityWithAppliedAmount(
          ctx.soId,
          ctx.discount,
          ctx.appliedAmount,
          causer,
        ),
      );

      const qtyChanged = Number(ctx.existingItem.qty) !== Number(item.qty);
      const addons = this.getAddonsForParentItem(item, items);
      salesOrderItems.push(
        ...this.applyDiscountAndGetItemsToPush(item, ctx, causer, qtyChanged, false, nextSequence),
      );

      if (qtyChanged) {
        for (const addon of addons) {
          const addonCtx = this.resolveDiscountContext(addon, existingSalesOrderItems, discountMap);
          salesOrderItems.push(
            ...this.applyDiscountAndGetItemsToPush(
              addon,
              addonCtx,
              causer,
              qtyChanged,
              true,
              nextSequence,
            ),
          );
        }
      }

      nextSequence = Math.max(...salesOrderItems.map((soItem) => soItem.itemSequence ?? 0)) + 1;
    }

    return { salesOrderItems, salesOrderDiscounts };
  }

  /**
   * Returns add-on items that belong to the given parent (same itemSequence).
   */
  private getAddonsForParentItem(
    parentItem: ApplyDiscountSalesOrderItemDto,
    items: ApplyDiscountDto['salesOrderItems'],
  ): ApplyDiscountSalesOrderItemDto[] {
    return items.filter((i) => i.addOn && i.itemSequence === parentItem.itemSequence);
  }

  /**
   * Applies discount to existing item or creates child + subtracts from parent. Returns items to push.
   * When createChild is true, always creates a child line and subtracts from existingItem.
   */
  private applyDiscountAndGetItemsToPush(
    itemDto: ApplyDiscountSalesOrderItemDto,
    ctx: ResolveDiscountContextResult,
    causer: User,
    createChild: boolean,
    isAddon: boolean,
    nextSequence: number,
  ): SalesOrderItem[] {
    if (createChild) {
      const parentSequence = nextSequence;
      const childSequence = nextSequence + 1;
      const childItem = ApplyDiscountToItemMapper.toChildItemFromExisting(
        ctx.existingItem,
        childSequence,
      );

      ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
        childItem,
        ctx.discountValue,
        ctx.amounts,
        causer,
      );
      childItem.qty = Number(itemDto.qty).toFixed(DECIMAL_PLACES);
      childItem.createdBy = causer;

      ApplyDiscountToItemMapper.updateExistingItem(
        ctx.existingItem,
        childItem,
        causer,
        isAddon,
        parentSequence,
      );

      return [childItem, ctx.existingItem];
    }

    ApplyDiscountToItemMapper.applyDiscountAmountsToItem(
      ctx.existingItem,
      ctx.discountValue,
      ctx.amounts,
      causer,
    );
    ctx.existingItem.updatedBy = causer;
    return [ctx.existingItem];
  }

  /**
   * Resolves existing item and discount from maps, validates, and computes discount amounts for the line.
   */
  private resolveDiscountContext(
    item: ApplyDiscountSalesOrderItemDto,
    existingSalesOrderItems: Map<string, SalesOrderItem>,
    discountMap: Map<number, Discount>,
  ): ResolveDiscountContextResult {
    const existingItem = existingSalesOrderItems.get(item.id);
    const discount = discountMap.get(item.discounts.id);

    if (!existingItem) {
      throw new Error(`Sales order item not found for id ${item.id}`);
    }

    if (!discount) {
      throw new Error(`Discount not found for id ${item.discounts.id}`);
    }

    const soId = existingItem.salesOrder.id;
    const unitPrice = Number(existingItem.unitPrice);
    let vatExclusiveAmount = Number(existingItem.vatExclusiveAmount);
    const qty = Number(existingItem.qty);
    const discountValue = parseFloat(discount.value);

    if (discount.name === 'Senior Citizen / PWD') {
      vatExclusiveAmount = unitPrice;
    }

    const amounts = ApplyDiscountToItemMapper.computeItemDiscountAmounts(
      discount,
      vatExclusiveAmount,
    );

    const appliedAmount = ApplyDiscountToItemMapper.computeAppliedAmount(
      vatExclusiveAmount,
      amounts.discountedUnitPrice,
      qty,
    );

    return {
      existingItem,
      discount,
      soId,
      unitPrice,
      vatExclusiveAmount,
      qty,
      discountValue,
      amounts,
      appliedAmount,
    };
  }

  private async loadLookupData(products: CreateSalesOrderDto['products']): Promise<LookupData> {
    const [recipeIds, productVariants, modifierOptionMap] = await Promise.all([
      this.recipesService.findRecipeIdsByProductVariantIds(products.map((p) => p.productVariantId)),
      this.productsService.findProductVariantsByIds(products.map((p) => p.productVariantId)),
      this.modifierGroupsService.findModifierOptionWithRelationById(getModifierOptionIds(products)),
    ]);

    return { recipeIds, productVariants, modifierOptionMap };
  }

  private enrichProduct(
    product: CreateSalesOrderItemDto,
    lookup: LookupData,
    causer: User,
    itemSequence: number,
  ): void {
    const recipeId = lookup.recipeIds.get(product.productVariantId);
    const productVariant = lookup.productVariants.get(product.productVariantId);

    if (!productVariant) {
      throw new Error(`Product variant not found for product ${product.productVariantId}`);
    }
    if (!recipeId) {
      throw new Error(`Recipe not found for product variant ${product.productVariantId}`);
    }

    product.productVariant = productVariant;
    product.recipeId = recipeId;
    product.causer = causer;
    product.itemSequence = itemSequence;
  }

  private buildAddOnItemsForProduct(
    product: CreateSalesOrderItemDto,
    modifierOptionMap: Map<number, ModifierOption>,
  ): SalesOrderItem[] {
    const items: SalesOrderItem[] = [];

    for (const modifierGroup of product.modifierGroups) {
      for (const modifierOption of modifierGroup.modifierOptions) {
        const optionWithRelation = modifierOptionMap.get(modifierOption.id);
        const recipeItem = optionWithRelation?.recipeItem;

        modifierOption.name = optionWithRelation?.name ?? '';
        modifierOption.createSoItem = product;
        modifierOption.quantity = product.quantity;
        if (recipeItem) {
          modifierOption.productVariant = recipeItem.recipe.productVariant;
          modifierOption.recipe = recipeItem.recipe;
          modifierOption.recipeItem = recipeItem;
        }

        items.push(CreateSalesOrderMapper.fromAddOnToSalesOrderItemEntity(modifierOption));
      }
    }

    return items;
  }
}

/** Collects all modifier option IDs from products for lookup. */
function getModifierOptionIds(products: CreateSalesOrderDto['products']): number[] {
  return products.flatMap((p) =>
    p.modifierGroups.flatMap((mg) => mg.modifierOptions.map((mo) => mo.id)),
  );
}
