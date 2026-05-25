import { Entity, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { CatalogModifier } from './catalog-modifier.entity';
import { CatalogProductModifierGroup } from './catalog-product-modifier-group.entity';

@Entity('catalog_modifier_groups')
export class CatalogModifierGroup extends UuidIdEntity {
  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'varchar', length: 10, name: 'selection_type' })
  selectionType: 'single' | 'multiple';

  @Column({ type: 'int', name: 'min_selections', default: 0 })
  minSelections: number;

  @Column({ type: 'int', name: 'max_selections', default: 1 })
  maxSelections: number;

  @Column({ type: 'boolean', name: 'is_required', default: false })
  isRequired: boolean;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => CatalogModifier, (modifier) => modifier.modifierGroup)
  modifiers: CatalogModifier[];

  @OneToMany(() => CatalogProductModifierGroup, (pmg) => pmg.modifierGroup)
  productModifierGroups: CatalogProductModifierGroup[];
}
