import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { PaymentMethod } from '../payments.enum';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';

@Entity('payments')
export class Payment extends UuidIdEntity {
  @ManyToOne(() => SalesOrder, { nullable: true })
  @JoinColumn({ name: 'sales_order_id' })
  salesOrder: SalesOrder | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: false,
    name: 'amount_paid',
  })
  amountPaid: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: false,
    default: '0',
    name: 'change',
  })
  change: string;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    enumName: 'payments_payment_method_enum',
    name: 'payment_method',
  })
  paymentMethod: PaymentMethod;

  @Column({ type: 'timestamp', name: 'payment_date', default: () => 'CURRENT_TIMESTAMP' })
  paymentDate: Date;

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
    name: 'transaction_reference',
  })
  transactionReference: string | null;

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
    name: 'payment_method_name',
  })
  paymentMethodName: string | null;
}
