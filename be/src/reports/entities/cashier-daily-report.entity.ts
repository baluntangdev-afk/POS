import { Entity, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';

@Entity('cashier_daily_reports')
export class CashierDailyReport extends UuidIdEntity {
  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'cashier_id' })
  cashier: User;

  @Column({ type: 'timestamp', name: 'period_start', nullable: true })
  periodStart: Date | null;

  @Column({ type: 'timestamp', name: 'period_end', nullable: true })
  periodEnd: Date | null;

  @Column({ type: 'timestamp', name: 'generated_at', default: () => 'CURRENT_TIMESTAMP' })
  generatedAt: Date;

  @Column({ type: 'jsonb', name: 'snapshot' })
  snapshot: Record<string, unknown>;

  @CreateDateColumn({ type: 'timestamp', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamp', name: 'updated_at' })
  updatedAt: Date;
}
