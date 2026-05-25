import { Entity, PrimaryColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { CatalogProduct } from './catalog-product.entity';
import { CatalogModifierGroup } from './catalog-modifier-group.entity';

@Entity('catalog_product_modifier_groups')
export class CatalogProductModifierGroup {
  @PrimaryColumn({ type: 'uuid', name: 'product_id' })
  productId: string;

  @PrimaryColumn({ type: 'uuid', name: 'modifier_group_id' })
  modifierGroupId: string;

  @Column({ type: 'int', name: 'sort_order', default: 0 })
  sortOrder: number;

  @ManyToOne(() => CatalogProduct, (product) => product.productModifierGroups, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'product_id' })
  product: CatalogProduct;

  @ManyToOne(() => CatalogModifierGroup, (mg) => mg.productModifierGroups, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'modifier_group_id' })
  modifierGroup: CatalogModifierGroup;
}
