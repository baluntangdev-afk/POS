import { Currency } from '../currencies/entities/currency.entity';
import { Discount } from '../discounts/entities/discount.entity';
import { InventoryCount } from '../inventory-counts/entities/inventory-count.entity';
import { InventoryCountItem } from '../inventory-counts/entities/inventory-count-item.entity';
import { InventoryCountType } from '../inventory-counts/entities/inventory-count-type.entity';
import { InventoryStock } from '../inventory-stocks/entities/inventory-stock.entity';
import { Material } from '../materials/entities/material.entity';
import { MaterialType } from '../material-types/entities/material-type.entity';
import { Menu } from '../menus/entities/menu.entity';
import { MenuItem } from '../store-menus/entities/menu-item.entity';
import { MenuItemModifier } from '../store-menus/entities/menu-item-modifier.entity';
import { StoreMenu } from '../store-menus/entities/store-menu.entity';
import { ModifierGroup } from '../modifier-groups/entities/modifier-group.entity';
import { ModifierOption } from '../modifier-groups/entities/modifier-option.entity';
import { Payment } from '../payments/entities/payment.entity';
import { Product } from '../products/entities/product.entity';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { ProductVariant } from '../products/entities/product-variant.entity';
import { Recipe } from '../recipes/entities/recipe.entity';
import { RecipeItem } from '../recipes/entities/recipe-item.entity';
import { Refund } from '../refunds/entities/refund.entity';
import { RefundItem } from '../refunds/entities/refund-item.entity';
import { SalesOrder } from '../sales-orders/entities/sales-order.entity';
import { SalesOrderDiscount } from '../sales-orders/entities/sales-order-discount.entity';
import { SalesOrderItem } from '../sales-orders/entities/sales-order-item.entity';
import { TaxCategory } from '../tax-categories/entities/tax-category.entity';
import { User } from '../users/entities/user.entity';
import { UserAddress } from '../user-addresses/entities/user-address.entity';
import { UserDetails } from '../user-details/entities/user-details.entity';
import { UserGroup } from '../user-groups/entities/user-group.entity';
import { UserPermission } from '../user-permissions/entities/user-permission.entity';
import { Uom } from '../uom/entities/uom.entity';
import { PosTerminal } from '../pos-terminals/entities/pos-terminal.entity';
import { PosTerminalPaymentMethod } from '../pos-terminals/entities/pos-terminal-payment-method.entity';
import { CashierDailyReport } from '../reports/entities/cashier-daily-report.entity';
import { CashierXReading } from '../reports/entities/cashier-x-reading.entity';
/** Entity constructor type for TypeORM (avoids generic Function). */
type EntityCtor = new (...args: unknown[]) => object;

/**
 * All TypeORM entities as an explicit array for use when running outside Nest (seed, migrate).
 * Required for SEA/bundled executable where entity glob patterns do not resolve to files.
 */
export const entities: EntityCtor[] = [
  Currency,
  Discount,
  InventoryCount,
  InventoryCountItem,
  InventoryCountType,
  InventoryStock,
  Material,
  MaterialType,
  Menu,
  MenuItem,
  MenuItemModifier,
  StoreMenu,
  ModifierGroup,
  ModifierOption,
  Payment,
  Product,
  ProductGroup,
  ProductVariant,
  Recipe,
  RecipeItem,
  Refund,
  RefundItem,
  SalesOrder,
  SalesOrderDiscount,
  SalesOrderItem,
  TaxCategory,
  User,
  UserAddress,
  UserDetails,
  UserGroup,
  UserPermission,
  Uom,
  PosTerminal,
  PosTerminalPaymentMethod,
  CashierDailyReport,
  CashierXReading,
];
