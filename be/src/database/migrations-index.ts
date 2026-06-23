import type { MigrationInterface } from 'typeorm';
import { TestInit1770175003018 } from './migrations/1770175003018-test-init';
import { UserEntity1770262063243 } from './migrations/1770262063243-user-entity';
import { UserActionRelation1770277769598 } from './migrations/1770277769598-user-action-relation';
import { UserDetails1770345160261 } from './migrations/1770345160261-user-details';
import { UserGroups1770345965325 } from './migrations/1770345965325-user-groups';
import { UserPermissions1770346302364 } from './migrations/1770346302364-user-permissions';
import { UniquePin1770346935922 } from './migrations/1770346935922-unique-pin';
import { UserAddresses1770349773794 } from './migrations/1770349773794-user-addresses';
import { Uom1770366434120 } from './migrations/1770366434120-uom';
import { MaterialTypes1770366765490 } from './migrations/1770366765490-material-types';
import { Materials1770367283716 } from './migrations/1770367283716-materials';
import { Currencies1770367500000 } from './migrations/1770367500000-currencies';
import { TaxCategories1770367600000 } from './migrations/1770367600000-tax-categories';
import { MaterialsTaxCategory1770367700000 } from './migrations/1770367700000-materials-tax-category';
import { InventoryCounts1770367800000 } from './migrations/1770367800000-inventory-counts';
import { InventoryStocks1770367900000 } from './migrations/1770367900000-inventory-stocks';
import { InventoryCountItems1770368000000 } from './migrations/1770368000000-inventory-count-items';
import { StoreMenus1770368100000 } from './migrations/1770368100000-store-menus';
import { MenuItems1770370160965 } from './migrations/1770370160965-menu-items';
import { ModifierGroups1770370200000 } from './migrations/1770370200000-modifier-groups';
import { ModifierOptions1770370300000 } from './migrations/1770370300000-modifier-options';
import { MenuItemModifiers1770370400000 } from './migrations/1770370400000-menu-item-modifiers';
import { Products1770370500000 } from './migrations/1770370500000-products';
import { ProductVariants1770370600000 } from './migrations/1770370600000-product-variants';
import { MenuItemsProductVariant1770370700000 } from './migrations/1770370700000-menu-items-product-variant';
import { InventoryCountItemsVariant1770370800000 } from './migrations/1770370800000-inventory-count-items-variant';
import { InventoryStocksVariant1770370900000 } from './migrations/1770370900000-inventory-stocks-variant';
import { Recipes1770371000000 } from './migrations/1770371000000-recipes';
import { RecipeItems1770601255704 } from './migrations/1770601255704-recipe-items';
import { Discounts1770601823921 } from './migrations/1770601823921-discounts';
import { Payments1770602209121 } from './migrations/1770602209121-payments';
import { SalesOrders1770602300000 } from './migrations/1770602300000-sales-orders';
import { PaymentsSalesOrder1770602400000 } from './migrations/1770602400000-payments-sales-order';
import { SalesOrderItems1770603539609 } from './migrations/1770603539609-sales-order-items';
import { SalesOrderDiscounts1770603903921 } from './migrations/1770603903921-sales-order-discounts';
import { Refunds1770604000000 } from './migrations/1770604000000-refunds';
import { RefundItems1770604414268 } from './migrations/1770604414268-refund-items';
import { InventoryCountTypes1770604847126 } from './migrations/1770604847126-inventory-count-types';
import { InventoryCountsTypeId1770605060016 } from './migrations/1770605060016-inventory-counts-type-id';
import { ProductGroups1770605100000 } from './migrations/1770605100000-product-groups';
import { ProductsGroupId1770605200000 } from './migrations/1770605200000-products-group-id';
import { SalesOrdersTaxRate1770605300000 } from './migrations/1770605300000-sales-orders-tax-rate';
import { Menus1770605400000 } from './migrations/1770605400000-menus';
import { UserPermissionsMenuId1770605500000 } from './migrations/1770605500000-user-permissions-menu-id';
import { ProductGroupsImageUrlBytea1770605600000 } from './migrations/1770605600000-product-groups-image-url-bytea';
import { UserIsPinChanged1770605600000 } from './migrations/1770605600000-user-is-pin-changed';
import { RecipeItemsExtra1770605700000 } from './migrations/1770605700000-recipe-items-extra';
import { ModifierOptionsImageUrlBytea1770605800000 } from './migrations/1770605800000-modifier-options-image-url-bytea';
import { ModifierOptionsRecipeItemId1770605900000 } from './migrations/1770605900000-modifier-options-recipe-item-id';
import { SalesOrdersIdUuid1770606000000 } from './migrations/1770606000000-sales-orders-id-uuid';
import { UuidV7SoItemsPaymentsInventory1770606100000 } from './migrations/1770606100000-uuid-v7-so-items-payments-inventory';
import { InventoryCountsSalesOrderId1770606200000 } from './migrations/1770606200000-inventory-counts-sales-order-id';
import { SalesOrdersTotalAmount1770606300000 } from './migrations/1770606300000-sales-orders-total-amount';
import { TaxCategoriesValue1770606400000 } from './migrations/1770606400000-tax-categories-value';
import { SoItemsDescriptionAddOnRecipeItem1770606500000 } from './migrations/1770606500000-so-items-description-add-on-recipe-item';
import { SalesOrdersSoNumberLength1770606600000 } from './migrations/1770606600000-sales-orders-so-number-length';
import { InventoryCountItemsStatus1770606700000 } from './migrations/1770606700000-inventory-count-items-status';
import { InventoryCountItemsSoItemId1770606800000 } from './migrations/1770606800000-inventory-count-items-so-item-id';
import { SoItemsSoDiscountId1770873862938 } from './migrations/1770873862938-so-items-so-discount-id';
import { SoItemsParentSoItemId1770873956257 } from './migrations/1770873956257-so-items-parent-so-item-id';
import { SoItemsVatExclusiveAmount1770874000000 } from './migrations/1770874000000-so-items-vat-exclusive-amount';
import { SoItemsVatAmountItemSubtotal1770874100000 } from './migrations/1770874100000-so-items-vat-amount-item-subtotal';
import { PaymentsChangeForTransaction1770874200000 } from './migrations/1770874200000-payments-change-for-transaction';
import { SalesOrdersDecimalPrecisionScale1770874300000 } from './migrations/1770874300000-sales-orders-decimal-precision-scale';
import { AddRefundItemRelations1772524305356 } from './migrations/1772524305356-add-refund-item-relations';
import { Catalog1779580800000 } from './migrations/1779580800000-catalog';
import { AugmentTablesForKioskCatalog1779582000000 } from './migrations/1779582000000-augment-tables-for-kiosk-catalog';
import { DropCatalogTables1779582100000 } from './migrations/1779582100000-drop-catalog-tables';
import { ProductGroupModifierGroups1779582200000 } from './migrations/1779582200000-product-group-modifier-groups';
import { SoItemsOptionalProductVariant1779582300000 } from './migrations/1779582300000-so-items-optional-product-variant';
import { CreatePosTerminals1779583000000 } from './migrations/1779583000000-create-pos-terminals';
import { AlterPosTerminalsKioskIdPaymentNumber1779583100000 } from './migrations/1779583100000-alter-pos-terminals-kiosk-id-payment-number';
import { AlterPosTerminalsAddLegalName1779583200000 } from './migrations/1779583200000-alter-pos-terminals-add-legal-name';
import { UsersPosTerminalId1779583300000 } from './migrations/1779583300000-users-pos-terminal-id';
import { PosTerminalPaymentMethods1779583400000 } from './migrations/1779583400000-pos-terminal-payment-methods';
import { PosTerminalPaymentMethodName1779583500000 } from './migrations/1779583500000-pos-terminal-payment-method-name';
import { ProductVariantsPrice1779583600000 } from './migrations/1779583600000-product-variants-price';
import { UsersRole1779583700000 } from './migrations/1779583700000-users-role';
import { SalesOrdersVoidFields1779583800000 } from './migrations/1779583800000-sales-orders-void-fields';
import { SalesOrdersDoneExport1779584000000 } from './migrations/1779584000000-sales-orders-done-export';
import { SoItemsSaleTypeNote1779584100000 } from './migrations/1779584100000-so-items-sale-type-note';
import { PaymentsMethodName1779584200000 } from './migrations/1779584200000-payments-method-name';
import { FixAdminRole1779584300000 } from './migrations/1779584300000-fix-admin-role';
import { ProductsUniqueNamePerGroup1779584400000 } from './migrations/1779584400000-products-unique-name-per-group';

/**
 * Migration classes for POSBackend.exe --migrate (same as npm run migration:up).
 * Auto-synced by scripts/sync-migrations-index.js when creating or generating migrations.
 */
export const migrations: Array<new () => MigrationInterface> = [
  TestInit1770175003018,
  UserEntity1770262063243,
  UserActionRelation1770277769598,
  UserDetails1770345160261,
  UserGroups1770345965325,
  UserPermissions1770346302364,
  UniquePin1770346935922,
  UserAddresses1770349773794,
  Uom1770366434120,
  MaterialTypes1770366765490,
  Materials1770367283716,
  Currencies1770367500000,
  TaxCategories1770367600000,
  MaterialsTaxCategory1770367700000,
  InventoryCounts1770367800000,
  InventoryStocks1770367900000,
  InventoryCountItems1770368000000,
  StoreMenus1770368100000,
  MenuItems1770370160965,
  ModifierGroups1770370200000,
  ModifierOptions1770370300000,
  MenuItemModifiers1770370400000,
  Products1770370500000,
  ProductVariants1770370600000,
  MenuItemsProductVariant1770370700000,
  InventoryCountItemsVariant1770370800000,
  InventoryStocksVariant1770370900000,
  Recipes1770371000000,
  RecipeItems1770601255704,
  Discounts1770601823921,
  Payments1770602209121,
  SalesOrders1770602300000,
  PaymentsSalesOrder1770602400000,
  SalesOrderItems1770603539609,
  SalesOrderDiscounts1770603903921,
  Refunds1770604000000,
  RefundItems1770604414268,
  InventoryCountTypes1770604847126,
  InventoryCountsTypeId1770605060016,
  ProductGroups1770605100000,
  ProductsGroupId1770605200000,
  SalesOrdersTaxRate1770605300000,
  Menus1770605400000,
  UserPermissionsMenuId1770605500000,
  ProductGroupsImageUrlBytea1770605600000,
  UserIsPinChanged1770605600000,
  RecipeItemsExtra1770605700000,
  ModifierOptionsImageUrlBytea1770605800000,
  ModifierOptionsRecipeItemId1770605900000,
  SalesOrdersIdUuid1770606000000,
  UuidV7SoItemsPaymentsInventory1770606100000,
  InventoryCountsSalesOrderId1770606200000,
  SalesOrdersTotalAmount1770606300000,
  TaxCategoriesValue1770606400000,
  SoItemsDescriptionAddOnRecipeItem1770606500000,
  SalesOrdersSoNumberLength1770606600000,
  InventoryCountItemsStatus1770606700000,
  InventoryCountItemsSoItemId1770606800000,
  SoItemsSoDiscountId1770873862938,
  SoItemsParentSoItemId1770873956257,
  SoItemsVatExclusiveAmount1770874000000,
  SoItemsVatAmountItemSubtotal1770874100000,
  PaymentsChangeForTransaction1770874200000,
  SalesOrdersDecimalPrecisionScale1770874300000,
  AddRefundItemRelations1772524305356,
  Catalog1779580800000,
  AugmentTablesForKioskCatalog1779582000000,
  DropCatalogTables1779582100000,
  ProductGroupModifierGroups1779582200000,
  SoItemsOptionalProductVariant1779582300000,
  CreatePosTerminals1779583000000,
  AlterPosTerminalsKioskIdPaymentNumber1779583100000,
  AlterPosTerminalsAddLegalName1779583200000,
  UsersPosTerminalId1779583300000,
  PosTerminalPaymentMethods1779583400000,
  PosTerminalPaymentMethodName1779583500000,
  ProductVariantsPrice1779583600000,
  UsersRole1779583700000,
  SalesOrdersVoidFields1779583800000,
  SalesOrdersDoneExport1779584000000,
  SoItemsSaleTypeNote1779584100000,
  PaymentsMethodName1779584200000,
  FixAdminRole1779584300000,
  ProductsUniqueNamePerGroup1779584400000
];
