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

@Entity('material_types')
export class MaterialType {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 3, name: 'material_type_code' })
  materialTypeCode: string;

  @Column({ type: 'varchar', length: 100, name: 'material_type_name' })
  materialTypeName: string;

  @Column({ type: 'boolean', default: false, name: 'auto_material_code' })
  autoMaterialCode: boolean;

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
