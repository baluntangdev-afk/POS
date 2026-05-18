import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

/**
 * Type/category of an inventory count (inventory_count_types). E.g. Sales Order, Delivery.
 */
@Entity('inventory_count_types')
export class InventoryCountType {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 20 })
  name: string;
}
