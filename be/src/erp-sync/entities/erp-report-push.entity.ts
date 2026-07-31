import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { ErpOrderPushStatus } from '../erp-sync.enum';

/**
 * Retry queue for pushing closed POS report snapshots to the ERP back office.
 * Idempotent on (report_type, client_report_id).
 */
@Entity('erp_report_push')
@Index('UQ_erp_report_push_type_client', ['reportType', 'clientReportId'], { unique: true })
export class ErpReportPush {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 30, name: 'report_type' })
  reportType: string;

  @Column({ type: 'varchar', length: 64, name: 'client_report_id' })
  clientReportId: string;

  @Column({ type: 'jsonb' })
  snapshot: Record<string, unknown>;

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
