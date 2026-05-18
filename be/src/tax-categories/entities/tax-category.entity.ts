import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('tax_categories')
export class TaxCategory {
  @PrimaryGeneratedColumn({ type: 'int' })
  id: number;

  @Column({ type: 'varchar', length: 50 })
  name: string;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: false,
  })
  value: string;
}
