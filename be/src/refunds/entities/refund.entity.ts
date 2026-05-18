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
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { PaymentMethod } from '../../payments/payments.enum';
import { RefundItem } from './refund-item.entity';

@Entity('refunds')
export class Refund {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 20, unique: true, name: 'refund_number' })
  refundNumber: string;

  @ManyToOne(() => SalesOrder, { nullable: false })
  @JoinColumn({ name: 'original_sales_order_id' })
  originalSalesOrder: SalesOrder;

  @Column({ type: 'text', nullable: false })
  reason: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: false,
    name: 'total_refund_amount',
  })
  totalRefundAmount: string;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    enumName: 'refunds_payment_method_enum',
    name: 'payment_method',
  })
  paymentMethod: PaymentMethod;

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
    name: 'transaction_reference',
  })
  transactionReference: string | null;

  @Column({ type: 'timestamp', name: 'refund_date', default: () => 'CURRENT_TIMESTAMP' })
  refundDate: Date;

  @OneToMany(() => RefundItem, (refundItem) => refundItem.refund)
  refundItems: RefundItem[];

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
