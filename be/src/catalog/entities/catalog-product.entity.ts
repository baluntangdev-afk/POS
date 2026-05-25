import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { CatalogCategory } from './catalog-category.entity';
import { CatalogProductModifierGroup } from './catalog-product-modifier-group.entity';

@Entity('catalog_products')
export class CatalogProduct extends UuidIdEntity {
  @Column({ type: 'uuid', name: 'category_id', nullable: true })
  categoryId: string | null;

  @ManyToOne(() => CatalogCategory, (cat) => cat.products, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'category_id' })
  category: CatalogCategory | null;

  @Column({ type: 'varchar', length: 150 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'numeric', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ type: 'text', nullable: true, name: 'image_url' })
  imageUrl: string | null;

  @Column({ type: 'boolean', name: 'is_available', default: true })
  isAvailable: boolean;

  @Column({ type: 'int', name: 'sort_order', default: 0 })
  sortOrder: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => CatalogProductModifierGroup, (pmg) => pmg.product)
  productModifierGroups: CatalogProductModifierGroup[];
}
