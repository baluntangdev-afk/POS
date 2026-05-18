import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { StoreMenu } from './store-menu.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { MenuItemModifier } from './menu-item-modifier.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => StoreMenu, { nullable: false })
  @JoinColumn({ name: 'store_menu_id' })
  storeMenu: StoreMenu;

  @ManyToOne(() => ProductVariant, { nullable: true })
  @JoinColumn({ name: 'product_variant_id' })
  productVariant: ProductVariant | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    name: 'display_price',
  })
  displayPrice: string;

  @Column({ type: 'varchar', length: 50 })
  category: string;

  @Column({ type: 'int', name: 'display_order', default: 0 })
  displayOrder: number;

  @Column({ type: 'boolean', name: 'is_available', default: true })
  isAvailable: boolean;

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
  @OneToMany(() => MenuItemModifier, (menuItemModifier) => menuItemModifier.menuItem)
  menuItemModifiers: MenuItemModifier[];
}
