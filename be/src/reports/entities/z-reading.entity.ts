import { Entity, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';

@Entity('z_readings')
export class ZReading extends UuidIdEntity {
  @Column({ type: 'integer', name: 'z_counter' })
  zCounter: number;

  @Column({ type: 'timestamp', name: 'period_start', nullable: true })
  periodStart: Date | null;

  @Column({ type: 'timestamp', name: 'period_end', nullable: true })
  periodEnd: Date | null;

  @Column({ type: 'timestamp', name: 'generated_at', default: () => 'CURRENT_TIMESTAMP' })
  generatedAt: Date;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'closed_by' })
  closedBy: User;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'authorized_by' })
  authorizedBy: User;

  @Column({ type: 'numeric', precision: 14, scale: 2, name: 'beginning_balance' })
  beginningBalance: string;

  @Column({ type: 'numeric', precision: 14, scale: 2, name: 'ending_balance' })
  endingBalance: string;

  @Column({ type: 'jsonb', name: 'snapshot' })
  snapshot: Record<string, unknown>;

  @CreateDateColumn({ type: 'timestamp', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamp', name: 'updated_at' })
  updatedAt: Date;
}
