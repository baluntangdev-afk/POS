import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { UserGroup } from '../../user-groups/entities/user-group.entity';
import { Menu } from '../../menus/entities/menu.entity';
import { BaseStatus } from '../../utils/shared-enums';

@Entity('user_permissions')
export class UserPermission {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @ManyToOne(() => UserGroup)
  @JoinColumn({ name: 'group_id' })
  group: UserGroup;

  @ManyToOne(() => Menu, { nullable: false })
  @JoinColumn({ name: 'menu_id' })
  menu: Menu;

  @Column({ type: 'text', array: true })
  permissions: string[];

  @Column({
    type: 'enum',
    enum: BaseStatus,
    enumName: 'user_permissions_status_enum',
    default: BaseStatus.ACTIVE,
  })
  status: BaseStatus;

  @ManyToOne(() => User, (user) => user.id)
  @JoinColumn({ name: 'created_by' })
  createdBy: User;

  @CreateDateColumn({ type: 'timestamp', name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.id)
  @JoinColumn({ name: 'updated_by' })
  updatedBy: User;

  @UpdateDateColumn({ type: 'timestamp', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.id, { nullable: true })
  @JoinColumn({ name: 'deleted_by' })
  deletedBy: User | null;

  @DeleteDateColumn({ type: 'timestamp', nullable: true, name: 'deleted_at' })
  deletedAt: Date | null;
}
