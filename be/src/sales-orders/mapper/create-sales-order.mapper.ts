import { ProductVariant } from '../../products/entities/product-variant.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { CreateSalesOrderDto } from '../dto/create-sales-order/create-sales-order.dto';
import { CreateSalesOrderModifierOptionDto } from '../dto/create-sales-order/modifier-option.dto';
import { CreateSalesOrderItemDto } from '../dto/create-sales-order/sales-order-item.dto';
import { SalesOrderItem } from '../entities/sales-order-item.entity';
import { SalesOrder } from '../entities/sales-order.entity';
import {
  DECIMAL_PLACES,
  calculateLineItemSubtotal,
  calculateLineItemTotalAmount,
  calculateLineItemVatAmount,
  calculateLineItemVatExclusiveAmount,
} from '../../utils/calculation.helper';

export class CreateSalesOrderMapper {
  static toEntity(dto: CreateSalesOrderDto): SalesOrder {
    const salesOrder = new SalesOrder();

    if (dto.id) {
      salesOrder.id = dto.id;
    }

    salesOrder.soNumber = dto.soNumber;
    salesOrder.soDate = dto.soDate;
    salesOrder.status = dto.status;
    salesOrder.soType = dto.soType;
    salesOrder.createdBy = dto.createdBy;
    salesOrder.updatedBy = dto.updatedBy;

    // amounts
    salesOrder.discountRate = dto.discountRate.toFixed(DECIMAL_PLACES);
    salesOrder.discountAmount = dto.discountAmount.toFixed(DECIMAL_PLACES);

    salesOrder.taxRate = dto.taxRate.toFixed(DECIMAL_PLACES);
    salesOrder.taxAmount = dto.taxAmount.toFixed(DECIMAL_PLACES);

    salesOrder.totalAmount = dto.totalAmount.toFixed(DECIMAL_PLACES);
    salesOrder.finalTotalAmount = dto.finalTotalAmount.toFixed(DECIMAL_PLACES);

    return salesOrder;
  }

  /**
   * Maps a SalesOrder entity to CreateSalesOrderDto (header and amounts only; products left empty).
   */
  static toDto(entity: SalesOrder): CreateSalesOrderDto {
    const dto = new CreateSalesOrderDto();

    dto.id = entity.id;
    dto.soNumber = entity.soNumber;
    dto.soDate = entity.soDate;
    dto.status = entity.status;
    dto.soType = entity.soType;
    dto.createdBy = entity.createdBy;
    dto.updatedBy = entity.updatedBy ?? entity.createdBy;

    dto.discountRate = parseFloat(entity.discountRate ?? '0');
    dto.discountAmount = parseFloat(entity.discountAmount);
    dto.taxRate = parseFloat(entity.taxRate);
    dto.taxAmount = parseFloat(entity.taxAmount);
    dto.totalAmount = parseFloat(entity.totalAmount);
    dto.finalTotalAmount = parseFloat(entity.finalTotalAmount);

    dto.products = [];

    return dto;
  }

  static toSalesOrderItemEntity(dto: CreateSalesOrderItemDto): SalesOrderItem {
    const salesOrderItem = new SalesOrderItem();

    salesOrderItem.itemSequence = dto.itemSequence;
    salesOrderItem.productVariant = new ProductVariant();
    salesOrderItem.productVariant.id = dto.productVariantId;
    salesOrderItem.recipe = new Recipe();
    salesOrderItem.recipe.id = dto.recipeId;
    salesOrderItem.description = `${dto.productVariant.name} ${dto.productVariant.product.name}`;
    salesOrderItem.qty = dto.quantity.toString();
    salesOrderItem.unitPrice = dto.price.toString();

    salesOrderItem.vatExclusiveAmount = calculateLineItemVatExclusiveAmount(
      dto.quantity,
      dto.price,
    );

    salesOrderItem.itemSubtotal = calculateLineItemSubtotal(
      parseFloat(salesOrderItem.vatExclusiveAmount ?? '0'),
      parseFloat(salesOrderItem.itemDiscountedPrice ?? '0'),
    );

    salesOrderItem.vatAmount = calculateLineItemVatAmount(
      parseFloat(salesOrderItem.itemSubtotal ?? '0'),
    );

    salesOrderItem.itemTotalAmount = calculateLineItemTotalAmount(
      parseFloat(salesOrderItem.vatAmount ?? '0'),
      parseFloat(salesOrderItem.itemSubtotal ?? '0'),
    );

    salesOrderItem.createdBy = dto.causer;
    salesOrderItem.updatedBy = dto.causer;
    // salesOrderItem.modifierGroups = dto.modifierGroups;

    return salesOrderItem;
  }

  static fromAddOnToSalesOrderItemEntity(dto: CreateSalesOrderModifierOptionDto): SalesOrderItem {
    const salesOrderItem = new SalesOrderItem();

    if (dto.createSoItem) {
      salesOrderItem.itemSequence = dto.createSoItem.itemSequence;
      salesOrderItem.productVariant = dto.createSoItem.productVariant;
      salesOrderItem.recipe = new Recipe();
      salesOrderItem.recipe.id = dto.createSoItem.recipeId;
      salesOrderItem.createdBy = dto.createSoItem.causer;
      salesOrderItem.updatedBy = dto.createSoItem.causer;
    }

    salesOrderItem.qty = dto.quantity.toString();
    salesOrderItem.unitPrice = dto.priceAddOn.toFixed(DECIMAL_PLACES);

    salesOrderItem.vatExclusiveAmount = calculateLineItemVatExclusiveAmount(
      dto.quantity,
      dto.priceAddOn,
    );

    salesOrderItem.itemSubtotal = calculateLineItemSubtotal(
      parseFloat(salesOrderItem.vatExclusiveAmount ?? '0'),
      parseFloat(salesOrderItem.itemDiscountedPrice ?? '0'),
    );

    salesOrderItem.vatAmount = calculateLineItemVatAmount(
      parseFloat(salesOrderItem.itemSubtotal ?? '0'),
    );

    salesOrderItem.itemTotalAmount = calculateLineItemTotalAmount(
      parseFloat(salesOrderItem.vatAmount ?? '0'),
      parseFloat(salesOrderItem.itemSubtotal ?? '0'),
    );

    salesOrderItem.addOn = true;

    if (dto.recipeItem) {
      salesOrderItem.recipeItem = dto.recipeItem;
      salesOrderItem.recipe = dto.recipe;
      salesOrderItem.productVariant = dto.productVariant;
    }

    salesOrderItem.description = `${dto.name}`;

    return salesOrderItem;
  }
}
