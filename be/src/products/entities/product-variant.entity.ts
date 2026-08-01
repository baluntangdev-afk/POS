import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  OneToMany,
  OneToOne,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Product } from './product.entity';
import { ProductVariantStatus } from '../products.enum';
import { MenuItem } from '../../store-menus/entities/menu-item.entity';
import { Recipe } from '../../recipes/entities/recipe.entity';

@Entity('product_variants')
export class ProductVariant {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => Product, { nullable: false })
  @JoinColumn({ name: 'product_id' })
  product: Product;

  @Column({ type: 'varchar', length: 50 })
  name: string;

  @Column({
    type: 'enum',
    enum: ProductVariantStatus,
    enumName: 'product_variants_status_enum',
    default: ProductVariantStatus.ACTIVE,
  })
  status: ProductVariantStatus;

  @Column({ type: 'numeric', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ type: 'boolean', name: 'is_default', default: false })
  isDefault: boolean;

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
  @OneToMany(() => MenuItem, (menuItem) => menuItem.productVariant)
  menuItems: MenuItem[];

  @OneToOne(() => Recipe, (recipe) => recipe.productVariant)
  recipe: Recipe;
}
