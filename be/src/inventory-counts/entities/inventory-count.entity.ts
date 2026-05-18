import {
  Entity,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { UuidIdEntity } from '../../utils/uuid-id.entity';
import { User } from '../../users/entities/user.entity';
import { InventoryCountType } from './inventory-count-type.entity';
import { InventoryCountStatus } from '../inventory-counts.enum';
import { SalesOrder } from '../../sales-orders/entities/sales-order.entity';

@Entity('inventory_counts')
export class InventoryCount extends UuidIdEntity {
  @Column({ type: 'date', name: 'count_date' })
  countDate: Date;

  @Column({
    type: 'enum',
    enum: InventoryCountStatus,
    enumName: 'inventory_counts_status_enum',
    default: InventoryCountStatus.DRAFT,
  })
  status: InventoryCountStatus;

  @ManyToOne(() => InventoryCountType, { nullable: false })
  @JoinColumn({ name: 'type_id' })
  type: InventoryCountType;

  @ManyToOne(() => SalesOrder, { nullable: true })
  @JoinColumn({ name: 'sales_order_id' })
  salesOrder: SalesOrder | null;

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
