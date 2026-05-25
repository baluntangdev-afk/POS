import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { CatalogModifierGroup } from './catalog-modifier-group.entity';

@Entity('catalog_modifiers')
export class CatalogModifier extends UuidIdEntity {
  @Column({ type: 'uuid', name: 'modifier_group_id' })
  modifierGroupId: string;

  @ManyToOne(() => CatalogModifierGroup, (mg) => mg.modifiers, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'modifier_group_id' })
  modifierGroup: CatalogModifierGroup;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'numeric', precision: 10, scale: 2, name: 'price_adjustment', default: 0 })
  priceAdjustment: number;

  @Column({ type: 'boolean', name: 'is_available', default: true })
  isAvailable: boolean;

  @Column({ type: 'int', name: 'sort_order', default: 0 })
  sortOrder: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
