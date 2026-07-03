import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductVariant } from '../entities/product-variant.entity';

@Injectable()
export class FindDistinctVariantNamesService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(): Promise<string[]> {
    const rows = await this.productVariantsRepository
      .createQueryBuilder('pv')
      .select('DISTINCT pv.name', 'name')
      .where('pv.deleted_at IS NULL')
      .orderBy('pv.name', 'ASC')
      .getRawMany<{ name: string }>();

    return rows.map((row) => row.name);
  }
}
