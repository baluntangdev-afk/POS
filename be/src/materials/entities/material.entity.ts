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
import { BaseStatus } from '../../utils/shared-enums';
import { User } from '../../users/entities/user.entity';
import { MaterialType } from '../../material-types/entities/material-type.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { TaxCategory } from '../../tax-categories/entities/tax-category.entity';
import { DispenseType } from '../materials.enum';
import { RecipeItem } from '../../recipes/entities/recipe-item.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';

@Entity('materials')
export class Material {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 15, unique: true, name: 'material_code' })
  materialCode: string;

  @Column({ type: 'varchar', length: 100, name: 'material_name' })
  materialName: string;

  @Column({ type: 'text', nullable: true, name: 'material_specification' })
  materialSpecification: string | null;

  @Column({
    type: 'varchar',
    length: 20,
    default: BaseStatus.ACTIVE,
  })
  status: BaseStatus;

  @ManyToOne(() => MaterialType, { nullable: false })
  @JoinColumn({ name: 'material_type_id' })
  materialType: MaterialType;

  // TODO: TBD - FK to locations(id) when locations table exists
  // @ManyToOne(() => Location)
  // @JoinColumn({ name: 'default_location_id' })
  // @Column({ type: 'int', nullable: true, name: 'default_location_id' })
  // defaultLocationId: number | null;

  @ManyToOne(() => Uom, { nullable: true })
  @JoinColumn({ name: 'standard_packing_unit_id' })
  standardPackingUnit: Uom | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'standard_packing_qty',
  })
  standardPackingQty: string | null;

  @ManyToOne(() => Uom, { nullable: true })
  @JoinColumn({ name: 'standard_issuance_unit_id' })
  standardIssuanceUnit: Uom | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'standard_issuance_qty',
  })
  standardIssuanceQty: string | null;

  @ManyToOne(() => Uom, { nullable: false })
  @JoinColumn({ name: 'standard_base_unit_id' })
  standardBaseUnit: Uom;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    default: 1,
    name: 'standard_base_qty',
  })
  standardBaseQty: string;

  // TODO: TBD - FK to suppliers(id) when suppliers table exists
  // @ManyToOne(() => Supplier)
  // @JoinColumn({ name: 'default_supplier_id' })
  // @Column({ type: 'int', nullable: true, name: 'default_supplier_id' })
  // defaultSupplierId: number | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'material_lead_time',
  })
  materialLeadTime: string | null;

  @ManyToOne(() => TaxCategory, { nullable: true })
  @JoinColumn({ name: 'tax_category_id' })
  taxCategory: TaxCategory | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'minimum_stock_level_qty',
  })
  minimumStockLevelQty: string | null;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'maximum_stock_level_qty',
  })
  maximumStockLevelQty: string | null;

  @Column({
    type: 'enum',
    enum: DispenseType,
    enumName: 'materials_dispense_type_enum',
    default: DispenseType.FEFO,
    name: 'dispense_type',
  })
  dispenseType: DispenseType;

  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
    nullable: true,
    name: 'shelf_life_days',
  })
  shelfLifeDays: string | null;

  @Column({ type: 'decimal', precision: 18, scale: 4, nullable: true })
  weight: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  image: string | null;

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
  @OneToMany(() => RecipeItem, (recipeItem) => recipeItem.material)
  recipeItems: RecipeItem[];

  @OneToMany(() => ModifierOption, (modifierOption) => modifierOption.material)
  modifierOptions: ModifierOption[];
}
