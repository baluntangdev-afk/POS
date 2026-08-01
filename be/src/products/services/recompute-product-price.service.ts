import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../entities/product.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantStatus } from '../products.enum';

@Injectable()
export class RecomputeProductPriceService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
  ) {}

  async execute(productId: number): Promise<void> {
    const result = await this.productVariantsRepository
      .createQueryBuilder('pv')
      .select('MIN(pv.price)', 'min')
      .where('pv.product_id = :productId', { productId })
      .andWhere('pv.deleted_at IS NULL')
      .andWhere('pv.status = :status', { status: ProductVariantStatus.ACTIVE })
      .getRawOne<{ min: string | null }>();

    const price = result?.min != null ? Number(result.min) : 0;
    await this.productsRepository.update(productId, { price: price.toString() });
  }
}
