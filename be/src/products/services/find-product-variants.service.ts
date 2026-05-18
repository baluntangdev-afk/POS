import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { ProductVariant } from '../entities/product-variant.entity';

@Injectable()
export class FindProductVariantsService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(ids: number[]): Promise<Map<number, ProductVariant>> {
    const productVariants = await this.productVariantsRepository.find({
      where: { id: In(ids) },
      select: {
        id: true,
        name: true,
        product: {
          id: true,
          name: true,
        },
      },
      relations: {
        product: true,
      },
    });

    return new Map(productVariants.map((pv) => [pv.id, pv]));
  }
}
