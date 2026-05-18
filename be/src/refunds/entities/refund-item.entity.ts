import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Refund } from './refund.entity';
import { SalesOrderItem } from '../../sales-orders/entities/sales-order-item.entity';

/**
 * Line item of a refund (refund_items). Links a refund to a sales order line and tracks quantity, amount and restock flag.
 */
@Entity('refund_items')
export class RefundItem {
  @PrimaryGeneratedColumn({ type: 'int', name: 'id' })
  id: number;

  @ManyToOne(() => Refund, { nullable: false })
  @JoinColumn({ name: 'refund_id' })
  refund: Refund;

  @ManyToOne(() => SalesOrderItem, { nullable: false })
  @JoinColumn({ name: 'sales_order_item_id' })
  salesOrderItem: SalesOrderItem;

  @Column({ type: 'int' })
  quantity: number;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    name: 'refund_amount',
  })
  refundAmount: string;

  @Column({
    type: 'boolean',
    name: 'restock_inventory',
    default: false,
  })
  restockInventory: boolean;
}
