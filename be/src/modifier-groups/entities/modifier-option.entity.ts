import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ModifierGroup } from './modifier-group.entity';
import { Material } from '../../materials/entities/material.entity';
import { RecipeItem } from '../../recipes/entities/recipe-item.entity';

@Entity('modifier_options')
export class ModifierOption {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => ModifierGroup, { nullable: false })
  @JoinColumn({ name: 'modifier_group_id' })
  modifierGroup: ModifierGroup;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    name: 'price_add_on',
    default: 0,
  })
  priceAddOn: string;

  @Column({ type: 'boolean', name: 'is_available', default: true })
  isAvailable: boolean;

  @Column({ type: 'int', name: 'sort_order', default: 0 })
  sortOrder: number;

  @ManyToOne(() => Material, { nullable: true })
  @JoinColumn({ name: 'material_id' })
  material: Material | null;

  @Column({ name: 'material_id', nullable: true, insert: false, update: false })
  materialId: number | null;

  @ManyToOne(() => RecipeItem, { nullable: true })
  @JoinColumn({ name: 'recipe_item_id' })
  recipeItem: RecipeItem | null;

  @Column({ name: 'recipe_item_id', nullable: true, insert: false, update: false })
  recipeItemId: number | null;

  @Column({
    type: 'bytea',
    nullable: true,
    name: 'image_url',
    transformer: {
      to: (value: Buffer | string | null): Buffer | null =>
        value == null ? null : typeof value === 'string' ? Buffer.from(value, 'base64') : value,
      from: (value: Buffer | null): Buffer | null => value,
    },
  })
  imageUrl: Buffer | null;

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
