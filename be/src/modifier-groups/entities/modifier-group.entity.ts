import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { MenuItemModifier } from '../../store-menus/entities/menu-item-modifier.entity';
import { ModifierOption } from './modifier-option.entity';

@Entity('modifier_groups')
export class ModifierGroup {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'int', name: 'min_selection', default: 0 })
  minSelection: number;

  @Column({ type: 'int', name: 'max_selection', default: 1 })
  maxSelection: number;

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

  // Relations
  @OneToMany(() => MenuItemModifier, (menuItemModifier) => menuItemModifier.modifierGroup)
  menuItemModifiers: MenuItemModifier[];

  @OneToMany(() => ModifierOption, (modifierOption) => modifierOption.modifierGroup)
  modifierOptions: ModifierOption[];
}
