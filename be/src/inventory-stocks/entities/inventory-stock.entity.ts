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
import { Uom } from '../../uom/entities/uom.entity';
import { Material } from '../../materials/entities/material.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';

@Entity('inventory_stocks')
export class InventoryStock {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => ProductVariant, { nullable: true })
  @JoinColumn({ name: 'variant_id' })
  productVariant: ProductVariant | null;

  @ManyToOne(() => Material, { nullable: true })
  @JoinColumn({ name: 'material_id' })
  material: Material | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    default: 0,
    name: 'quantity_on_hand',
  })
  quantityOnHand: string;

  @ManyToOne(() => Uom, { nullable: false })
  @JoinColumn({ name: 'unit_id' })
  unit: Uom;

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
