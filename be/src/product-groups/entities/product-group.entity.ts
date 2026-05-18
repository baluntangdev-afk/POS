import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { BaseStatus } from '../../utils/shared-enums';
import { User } from '../../users/entities/user.entity';

@Entity('product_groups')
export class ProductGroup {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 100, unique: true })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({
    type: 'bytea',
    nullable: true,
    name: 'image_url',
    transformer: {
      to: (value: Buffer | string | null): Buffer | null =>
        value == null ? null : typeof value === 'string' ? Buffer.from(value, 'base64') : value,
      from: (value: Buffer | null): Buffer | null => value,
    },
  })
  imageUrl: Buffer | null;

  @Column({
    type: 'varchar',
    length: 20,
    default: BaseStatus.ACTIVE,
  })
  status: BaseStatus;

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
}
