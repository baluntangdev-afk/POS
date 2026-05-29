import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  BeforeInsert,
} from 'typeorm';
import { uuidv7 } from 'uuidv7';
import { User } from '../../users/entities/user.entity';
import { PosTerminalPaymentMethod } from './pos-terminal-payment-method.entity';

@Entity('pos_terminals')
export class PosTerminal {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'uuid', unique: true, name: 'kiosk_id' })
  kioskId: string;

  @BeforeInsert()
  generateKioskId(): void {
    if (!this.kioskId) this.kioskId = uuidv7();
  }

  @Column({ type: 'varchar', length: 255 })
  address: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'legal_name' })
  legalName: string | null;

  @Column({ type: 'varchar', length: 50, name: 'tin_number' })
  tinNumber: string;

  @OneToMany(() => PosTerminalPaymentMethod, (pm) => pm.posTerminal)
  paymentMethods: PosTerminalPaymentMethod[];

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'assigned_user_id' })
  assignedUser: User | null;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'created_by' })
  createdBy: User | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'updated_by' })
  updatedBy: User | null;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'deleted_by' })
  deletedBy: User | null;

  @DeleteDateColumn({ type: 'timestamptz', nullable: true, name: 'deleted_at' })
  deletedAt: Date | null;
}
