import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SalesOrdersService } from './sales-orders.service';
import { SalesOrdersController } from './sales-orders.controller';
import { SalesOrder } from './entities/sales-order.entity';
import { SalesOrderItem } from './entities/sales-order-item.entity';
import { SalesOrderDiscount } from './entities/sales-order-discount.entity';
import { CreateSalesOrderService } from './services/create-sales-order.service';
import { AppendSalesOrderItemService } from './services/append-sales-order-item.service';
import { SalesOrderCalculationService } from './services/sales-order-calculation.service';
import { SalesOrderItemsPersistenceService } from './services/sales-order-items-persistence.service';
import { SalesOrderDiscountPersistenceService } from './services/sales-order-discount-persistence.service';
import { SalesOrderInventoryValidationService } from './services/sales-order-inventory-validation.service';
import { SalesOrderItemBuildService } from './services/sales-order-item-build.service';
import { TaxCategoriesModule } from '../tax-categories/tax-categories.module';
import { Payment } from '../payments/entities/payment.entity';
import { RecipesModule } from '../recipes/recipes.module';
import { ProductsModule } from '../products/products.module';
import { InventoryStocksModule } from '../inventory-stocks/inventory-stocks.module';
import { ModifierGroupsModule } from '../modifier-groups/modifier-groups.module';
import { UpdateSalesOrderItemService } from './services/update-sales-order-item.service';
import { RemoveSalesOrderItemService } from './services/remove-sales-order-item.service';
import { DiscountsModule } from '../discounts/discounts.module';
import { AddDiscountToItemService } from './services/add-discount-to-item.service';
import { ConfirmSalesOrderService } from './services/confirm-sales-order.service';
@Module({
  imports: [
    TypeOrmModule.forFeature([SalesOrder, SalesOrderItem, SalesOrderDiscount, Payment]),
    TaxCategoriesModule,
    RecipesModule,
    ProductsModule,
    InventoryStocksModule,
    ModifierGroupsModule,
    DiscountsModule,
  ],
  controllers: [SalesOrdersController],
  providers: [
    SalesOrdersService,
    SalesOrderItemsPersistenceService,
    SalesOrderDiscountPersistenceService,
    SalesOrderInventoryValidationService,
    SalesOrderItemBuildService,
    SalesOrderCalculationService,
    CreateSalesOrderService,
    AppendSalesOrderItemService,
    UpdateSalesOrderItemService,
    RemoveSalesOrderItemService,
    AddDiscountToItemService,
    ConfirmSalesOrderService,
  ],
})
export class SalesOrdersModule {}
