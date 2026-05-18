import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToOne,
  DeleteDateColumn,
} from 'typeorm';
import { UserSuffix } from '../users.enum';
import { BaseStatus } from '../../utils/shared-enums';
import { UserDetails } from '../../user-details/entities/user-details.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 50, unique: true, name: 'user_id' })
  userId: string;

  @Column({ type: 'varchar', length: 100, unique: true })
  email: string;

  @Column({ type: 'varchar', length: 255 })
  password: string;

  @Column({ type: 'varchar', length: 255 })
  salt: string;

  @Column({ type: 'varchar', length: 100, name: 'first_name' })
  firstName: string;

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'middle_name' })
  middleName: string | null;

  @Column({ type: 'varchar', length: 100, name: 'last_name' })
  lastName: string;

  @Column({
    type: 'enum',
    enum: UserSuffix,
    default: UserSuffix.NONE,
    nullable: true,
  })
  suffix: UserSuffix | null;

  @Column({ type: 'boolean', default: false, name: 'system_admin' })
  systemAdmin: boolean;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image: string | null;

  // @Column({ type: 'int', nullable: true, name: 'cost_center' })
  // costCenter: number | null;

  @Column({ type: 'varchar', length: 255, nullable: false, unique: true, name: 'device_pin' })
  devicePin: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone: string | null;

  @Column({ type: 'boolean', default: false, name: 'email_verified' })
  emailVerified: boolean;

  @Column({ type: 'boolean', default: false, name: 'phone_verified' })
  phoneVerified: boolean;

  // @Column({ type: 'int', nullable: true, name: 'preferred_currency_id' })
  // preferredCurrencyId: number | null;

  @Column({ type: 'boolean', default: false })
  locked: boolean;

  @Column({ type: 'timestamptz', nullable: true, name: 'last_login' })
  lastLogin: Date | null;

  @Column({ type: 'boolean', default: false, name: 'is_pin_changed' })
  isPinChanged: boolean;

  @Column({
    type: 'enum',
    enum: BaseStatus,
    default: BaseStatus.ACTIVE,
  })
  status: BaseStatus;

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

  // relations
  @OneToOne(() => UserDetails, (userDetails) => userDetails.user)
  userDetails: UserDetails;
}
