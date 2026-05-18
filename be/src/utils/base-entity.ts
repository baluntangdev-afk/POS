import { Column, CreateDateColumn, UpdateDateColumn, DeleteDateColumn } from 'typeorm';
import { BaseStatus } from './shared-enums';
import { User } from '../users/entities/user.entity';

export class BaseEntity {
  @Column({
    type: 'enum',
    enum: BaseStatus,
    default: BaseStatus.ACTIVE,
  })
  status: BaseStatus;

  @Column({ type: 'int4', name: 'created_by' })
  createdBy: User;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @Column({ type: 'int4', name: 'updated_by' })
  updatedBy: User;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @Column({ type: 'int4', nullable: true, name: 'deleted_by' })
  deletedBy: User | null;

  @DeleteDateColumn({ type: 'timestamptz', nullable: true, name: 'deleted_at' })
  deletedAt: Date | null;
}
