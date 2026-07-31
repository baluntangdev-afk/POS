import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';
import { ErpOrderPushStatus } from '../erp-sync.enum';

/**
 * Retry queue for pushing confirmed sales orders to the ERP back office.
 * One row per confirmed order; the cron drains PENDING/FAILED rows with backoff.
 */
@Entity('erp_order_push')
@Index('UQ_erp_order_push_so_id', ['salesOrder'], { unique: true })
export class ErpOrderPush {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => SalesOrder, { nullable: false })
  @JoinColumn({ name: 'so_id' })
  salesOrder: SalesOrder;

  @Column({ type: 'varchar', length: 20, default: ErpOrderPushStatus.PENDING })
  status: ErpOrderPushStatus;

  @Column({ type: 'int', default: 0 })
  attempts: number;

  @Column({ type: 'text', nullable: true, name: 'last_error' })
  lastError: string | null;

  @Column({ type: 'timestamp', nullable: true, name: 'last_attempt_at' })
  lastAttemptAt: Date | null;

  @Column({ type: 'timestamp', nullable: true, name: 'sent_at' })
  sentAt: Date | null;

  @CreateDateColumn({ type: 'timestamp', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamp', name: 'updated_at' })
  updatedAt: Date;
}
