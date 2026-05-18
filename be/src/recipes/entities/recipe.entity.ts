import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  Unique,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { RecipeStatus } from '../recipes.enum';
import { RecipeItem } from './recipe-item.entity';

@Entity('recipes')
@Unique(['productVariant'])
export class Recipe {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => ProductVariant, { nullable: false })
  @JoinColumn({ name: 'product_variant_id' })
  productVariant: ProductVariant;

  @Column({ type: 'varchar', length: 150 })
  name: string;

  @Column({ type: 'int', nullable: true, name: 'prep_time_minutes' })
  prepTimeMinutes: number | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    name: 'yield_qty',
    default: 1,
  })
  yieldQty: string;

  @ManyToOne(() => Uom, { nullable: false })
  @JoinColumn({ name: 'yield_unit_id' })
  yieldUnit: Uom;

  @Column({
    type: 'enum',
    enum: RecipeStatus,
    enumName: 'recipes_status_enum',
    default: RecipeStatus.DRAFT,
  })
  status: RecipeStatus;

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
  @OneToMany(() => RecipeItem, (recipeItem) => recipeItem.recipe)
  recipeItems: RecipeItem[];
}
