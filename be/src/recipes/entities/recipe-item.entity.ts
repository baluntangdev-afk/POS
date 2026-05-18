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
import { Recipe } from './recipe.entity';
import { Material } from '../../materials/entities/material.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';

@Entity('recipe_items')
export class RecipeItem {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => Recipe, { nullable: false })
  @JoinColumn({ name: 'recipe_id' })
  recipe: Recipe;

  @ManyToOne(() => Material, { nullable: false })
  @JoinColumn({ name: 'material_id' })
  material: Material;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    nullable: false,
  })
  quantity: string;

  @ManyToOne(() => Uom, { nullable: false })
  @JoinColumn({ name: 'unit_id' })
  unit: Uom;

  @Column({
    type: 'boolean',
    nullable: false,
    default: false,
    comment: 'Add-on to the base meal or part of the staple ingredients',
  })
  extra: boolean;

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
  @OneToOne(() => ModifierOption, (modifierOption) => modifierOption.recipeItem)
  modifierOption: ModifierOption;
}
