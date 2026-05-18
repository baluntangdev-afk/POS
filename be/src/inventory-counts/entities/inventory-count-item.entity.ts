import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { InventoryCount } from './inventory-count.entity';
import { Material } from '../../materials/entities/material.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { ProductVariant } from '../../products/entities/product-variant.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';
import { InventoryCountItemStatus } from '../inventory-counts.enum';

@Entity('inventory_count_items')
export class InventoryCountItem extends UuidIdEntity {
  @ManyToOne(() => InventoryCount, { nullable: false })
  @JoinColumn({ name: 'inventory_count_id' })
  inventoryCount: InventoryCount;

  @ManyToOne(() => ProductVariant, { nullable: true })
  @JoinColumn({ name: 'variant_id' })
  productVariant: ProductVariant | null;

  @ManyToOne(() => Material, { nullable: true })
  @JoinColumn({ name: 'material_id' })
  material: Material | null;

  @ManyToOne(() => SalesOrderItem, { nullable: true })
  @JoinColumn({ name: 'so_item_id' })
  salesOrderItem: SalesOrderItem | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    name: 'system_qty',
  })
  systemQty: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    name: 'counted_qty',
  })
  countedQty: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 3,
    name: 'variance_qty',
  })
  varianceQty: string;

  @ManyToOne(() => Uom, { nullable: false })
  @JoinColumn({ name: 'unit_id' })
  unit: Uom;

  @Column({
    type: 'enum',
    enum: InventoryCountItemStatus,
    enumName: 'inventory_count_items_status_enum',
    default: InventoryCountItemStatus.PENDING,
  })
  status: InventoryCountItemStatus;
}
