import { Module } from '@nestjs/common';

import { ConfigModule } from './config/config.module';
import { AppConfigService } from './config/config.service';
import { HealthModule } from './health/health.module';
import { DatabaseModule } from './database/database.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { UserDetailsModule } from './user-details/user-details.module';
import { UserGroupsModule } from './user-groups/user-groups.module';
import { UserPermissionsModule } from './user-permissions/user-permissions.module';
import { UserAddressesModule } from './user-addresses/user-addresses.module';
import { ProductsModule } from './products/products.module';
import { UomModule } from './uom/uom.module';
import { MaterialTypesModule } from './material-types/material-types.module';
import { MaterialsModule } from './materials/materials.module';
import { CurrenciesModule } from './currencies/currencies.module';
import { TaxCategoriesModule } from './tax-categories/tax-categories.module';
import { InventoryCountsModule } from './inventory-counts/inventory-counts.module';
import { InventoryStocksModule } from './inventory-stocks/inventory-stocks.module';
import { StoreMenusModule } from './store-menus/store-menus.module';
import { ModifierGroupsModule } from './modifier-groups/modifier-groups.module';
import { RecipesModule } from './recipes/recipes.module';
import { DiscountsModule } from './discounts/discounts.module';
import { PaymentsModule } from './payments/payments.module';
import { SalesOrdersModule } from './sales-orders/sales-orders.module';
import { RefundsModule } from './refunds/refunds.module';
import { ProductGroupsModule } from './product-groups/product-groups.module';
import { MenusModule } from './menus/menus.module';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ScheduleModule } from '@nestjs/schedule';
import { CronJobsModule } from './cron-jobs/cron-jobs.module';
import { ReportsModule } from './reports/reports.module';
import { CatalogModule } from './catalog/catalog.module';
import { PosTerminalsModule } from './pos-terminals/pos-terminals.module';
import { ErpSyncModule } from './erp-sync/erp-sync.module';

@Module({
  imports: [
    EventEmitterModule.forRoot(),
    ScheduleModule.forRoot(),
    ConfigModule,
    DatabaseModule,
    HealthModule,
    UsersModule,
    AuthModule,
    UserDetailsModule,
    UserGroupsModule,
    UserPermissionsModule,
    UserAddressesModule,
    ProductsModule,
    ProductGroupsModule,
    UomModule,
    MaterialTypesModule,
    MaterialsModule,
    CurrenciesModule,
    TaxCategoriesModule,
    InventoryCountsModule,
    InventoryStocksModule,
    StoreMenusModule,
    ModifierGroupsModule,
    RecipesModule,
    DiscountsModule,
    PaymentsModule,
    SalesOrdersModule,
    RefundsModule,
    MenusModule,
    CronJobsModule,
    ReportsModule,
    CatalogModule,
    PosTerminalsModule,
    ErpSyncModule,
  ],
  providers: [AppConfigService],
})
export class AppModule {}
