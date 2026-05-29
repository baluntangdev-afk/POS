import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PaymentMethod } from '../../payments/payments.enum';
import { PosTerminal } from './pos-terminal.entity';

@Entity('pos_terminal_payment_methods')
export class PosTerminalPaymentMethod {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => PosTerminal, (terminal) => terminal.paymentMethods, {
    nullable: false,
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'pos_terminal_id' })
  posTerminal: PosTerminal;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    enumName: 'payments_payment_method_enum',
    name: 'payment_method',
  })
  paymentMethod: PaymentMethod;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'payment_number' })
  paymentNumber: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;
}
