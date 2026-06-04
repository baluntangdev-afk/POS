import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  OneToMany,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrder } from './sales-order.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';
import { RecipeItem } from '../../recipes/entities/recipe-item.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { Currency } from '../../currencies/entities/currency.entity';
import { SalesOrderStatus, SalesOrderType } from '../sales-orders.enum';
import { SalesOrderDiscount } from './sales-order-discount.entity';
import { RefundItem } from '../../refunds/entities/refund-item.entity';

/**
 * Line item of a sales order (so_items). Tracks product, quantity, pricing and line-level status for KDS.
 */
@Entity('so_items')
export class SalesOrderItem extends UuidIdEntity {
  @ManyToOne(() => SalesOrder, { nullable: false })
  @JoinColumn({ name: 'so_id' })
  salesOrder: SalesOrder;

  @ManyToOne(() => SalesOrderItem, { nullable: true })
  @JoinColumn({ name: 'parent_so_item_id' })
  parentSoItem: SalesOrderItem | null;

  @Column({ type: 'int', nullable: true, name: 'item_sequence' })
  itemSequence: number | null;

  @ManyToOne(() => ProductVariant, { nullable: true })
  @JoinColumn({ name: 'product_variant_id' })
  productVariant: ProductVariant | null;

  @ManyToOne(() => Recipe, { nullable: true })
  @JoinColumn({ name: 'recipe_id' })
  recipe: Recipe | null;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: false,
    comment: 'Product Summary (e.g., 1 PC CHICKENJOY)',
  })
  description: string;

  @Column({
    type: 'boolean',
    nullable: false,
    default: false,
    name: 'add_on',
    comment: 'Whether this line is an add-on (snapshot for inventory via recipe_item_id)',
  })
  addOn: boolean;

  @ManyToOne(() => RecipeItem, { nullable: true })
  @JoinColumn({ name: 'recipe_item_id' })
  recipeItem: RecipeItem | null;

  @Column({ type: 'decimal', precision: 12, scale: 3 })
  qty: string;

  @ManyToOne(() => Uom, { nullable: true })
  @JoinColumn({ name: 'uom' })
  uom: Uom | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'unit_price',
  })
  unitPrice: string;

  @ManyToOne(() => SalesOrderDiscount, { nullable: true })
  @JoinColumn({ name: 'so_discount_id' })
  salesOrderDiscount: SalesOrderDiscount | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'item_discount_rate',
    default: 0,
  })
  itemDiscountRate: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'item_discounted_price',
  })
  itemDiscountedPrice: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'vat_exclusive_amount',
  })
  vatExclusiveAmount: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'vat_amount',
  })
  vatAmount: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'item_subtotal',
  })
  itemSubtotal: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'item_total_amount',
  })
  itemTotalAmount: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'item_paid_amount',
    default: 0,
  })
  itemPaidAmount: string | null;

  @ManyToOne(() => Currency, { nullable: true })
  @JoinColumn({ name: 'currency' })
  currency: Currency | null;

  @OneToMany(() => RefundItem, (refundItem) => refundItem.salesOrderItem)
  refundItems: RefundItem[];

  @Column({
    type: 'enum',
    enum: SalesOrderType,
    enumName: 'sales_orders_so_type_enum',
    name: 'sale_type',
    nullable: true,
  })
  saleType: SalesOrderType | null;

  @Column({ type: 'varchar', length: 500, nullable: true, name: 'note' })
  note: string | null;

  @Column({
    type: 'varchar',
    length: 20,
    default: SalesOrderStatus.PENDING,
  })
  status: SalesOrderStatus;

  @ManyToOne(() => User, (user) => user.id)
  @JoinColumn({ name: 'created_by' })
  createdBy: User;

  @CreateDateColumn({ type: 'timestamp', name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'updated_by' })
  updatedBy: User | null;

  @UpdateDateColumn({ type: 'timestamp', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'deleted_by' })
  deletedBy: User | null;

  @DeleteDateColumn({ type: 'timestamp', nullable: true, name: 'deleted_at' })
  deletedAt: Date | null;
}
