import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  Index,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ProductGroup } from '../../product-groups/entities/product-group.entity';
import { ProductVariant } from './product-variant.entity';
import { ProductStatus } from '../products.enum';

@Entity('products')
// Product names are unique per category (group), not globally. Partial index so
// soft-deleted rows never block re-using a name — see migration 1779584300000.
@Index('UQ_products_group_name', ['productGroup', 'name'], {
  unique: true,
  where: '"deleted_at" IS NULL',
})
// ERP SKU (material code) — unique among live rows; see migration 1784246400000.
@Index('UQ_products_sku', ['sku'], {
  unique: true,
  where: '"sku" IS NOT NULL AND "deleted_at" IS NULL',
})
export class Product {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => ProductGroup, { nullable: false })
  @JoinColumn({ name: 'group_id' })
  productGroup: ProductGroup;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  /** ERP material code (SKU). Set when the product is managed/synced by the ERP back office. */
  @Column({ type: 'varchar', length: 140, nullable: true })
  sku: string | null;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({
    type: 'text',
    nullable: true,
    name: 'image_url',
    transformer: {
      to: (value: Buffer | string | null): string | null => {
        if (value == null) return null;
        if (typeof value === 'string') return value;
        return value.toString('base64');
      },
      from: (value: string | null): string | null => value,
    },
  })
  imageUrl: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    default: 0,
  })
  price: string;

  @Column({ type: 'boolean', name: 'is_available', default: true })
  isAvailable: boolean;

  /**
   * Remaining sellable servings from the last ERP menu sync (null = not ERP-managed).
   * Decremented on each confirmed order so availability stays accurate between syncs.
   */
  @Column({ type: 'int', name: 'available_servings', nullable: true })
  availableServings: number | null;

  @Column({ type: 'int', name: 'sort_order', default: 0 })
  sortOrder: number;

  @Column({
    type: 'enum',
    enum: ProductStatus,
    enumName: 'products_status_enum',
    default: ProductStatus.ACTIVE,
  })
  status: ProductStatus;

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

  // Relations
  @OneToMany(() => ProductVariant, (productVariant) => productVariant.product)
  productVariants: ProductVariant[];
}
