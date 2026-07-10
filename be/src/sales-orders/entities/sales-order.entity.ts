import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  OneToMany,
  OneToOne,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';
import { SalesOrderType, SalesOrderStatus } from '../sales-orders.enum';
import { SalesOrderItem } from './sales-order-item.entity';
import { SalesOrderDiscount } from './sales-order-discount.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { Refund } from '../../refunds/entities/refund.entity';

@Entity('sales_orders')
export class SalesOrder extends UuidIdEntity {
  @Column({ type: 'varchar', length: 20, unique: true, name: 'so_number' })
  soNumber: string;

  @Column({ type: 'timestamp', name: 'so_date', default: () => 'CURRENT_TIMESTAMP' })
  soDate: Date;

  @Column({
    type: 'enum',
    enum: SalesOrderType,
    enumName: 'sales_orders_so_type_enum',
    name: 'so_type',
    default: SalesOrderType.DINE_IN,
  })
  soType: SalesOrderType;

  // TODO: TBD - FK to restaurant_tables(id) when restaurant_tables table exists
  // @ManyToOne(() => RestaurantTable, { nullable: true })
  // @JoinColumn({ name: 'restaurant_table_id' })
  // restaurantTable: RestaurantTable | null;

  // TODO: TBD - FK to customers(id) when customers table exists
  // @ManyToOne(() => Customer, { nullable: true })
  // @JoinColumn({ name: 'customer_id' })
  // customer: Customer | null;

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'payee_name' })
  payeeName: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'shipping_address' })
  shippingAddress: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  location: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  remarks: string | null;

  @Column({
    type: 'enum',
    enum: SalesOrderStatus,
    enumName: 'sales_orders_status_enum',
    default: SalesOrderStatus.PENDING,
  })
  status: SalesOrderStatus;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: true,
    name: 'discount_rate',
    default: 0,
  })
  discountRate: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    nullable: false,
    name: 'tax_rate',
    default: 0,
  })
  taxRate: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'discount_amount',
    default: 0,
  })
  discountAmount: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'tax_amount',
    default: 0,
  })
  taxAmount: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'total_amount',
    default: 0,
  })
  totalAmount: string;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 6,
    name: 'final_total_amount',
    default: 0,
  })
  finalTotalAmount: string;

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

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'approved_by' })
  approvedBy: User | null;

  @Column({ type: 'timestamp', nullable: true, name: 'approved_at' })
  approvedAt: Date | null;

  // relations
  @OneToMany(() => SalesOrderItem, (salesOrderItem) => salesOrderItem.salesOrder)
  salesOrderItems: SalesOrderItem[];

  @OneToMany(() => SalesOrderDiscount, (salesOrderDiscount) => salesOrderDiscount.salesOrder)
  salesOrderDiscounts: SalesOrderDiscount[];

  @OneToMany(() => Payment, (payment) => payment.salesOrder)
  payments: Payment[];

  @Column({ type: 'varchar', length: 500, nullable: true, name: 'void_reason' })
  voidReason: string | null;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'voided_by' })
  voidedBy: User | null;

  @Column({ type: 'timestamp', nullable: true, name: 'voided_at' })
  voidedAt: Date | null;

  @Column({ name: 'done_export', type: 'boolean', default: false })
  doneExport: boolean;

  @Column({ name: 'done_daily_report', type: 'boolean', default: false })
  doneDailyReport: boolean;

  @Column({ name: 'done_x_reading', type: 'boolean', default: false })
  doneXReading: boolean;

  @OneToOne(() => Refund, (refund) => refund.originalSalesOrder)
  refund: Refund | null;
}
