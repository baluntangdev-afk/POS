import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrder } from './sales-order.entity';
import { Discount } from '../../discounts/entities/discount.entity';

/**
 * Junction of a sales order and a discount (so_discounts). Stores the actual currency value deducted per discount.
 */
@Entity('so_discounts')
export class SalesOrderDiscount extends UuidIdEntity {
  @ManyToOne(() => SalesOrder, { nullable: false })
  @JoinColumn({ name: 'sales_order_id' })
  salesOrder: SalesOrder;

  @ManyToOne(() => Discount, { nullable: false })
  @JoinColumn({ name: 'discount_id' })
  discount: Discount;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'applied_amount',
  })
  appliedAmount: string;

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
