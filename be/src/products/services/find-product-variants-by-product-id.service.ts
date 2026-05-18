import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductVariant } from '../entities/product-variant.entity';
import { PRODUCT_VARIANT_LIST_SELECT } from '../products.constant';
import { ProductVariantMapper } from '../mapper/product-variant.mapper';
import { ProductVariantDto } from '../dto/product-variant.dto';

@Injectable()
export class FindProductVariantsByProductIdService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(productId: number): Promise<ProductVariantDto[]> {
    const variants = await this.productVariantsRepository.find({
      where: { product: { id: productId } },
      select: PRODUCT_VARIANT_LIST_SELECT,
      relations: {
        product: true,
      },
      order: {
        isDefault: 'DESC',
        id: 'ASC',
      },
    });

    return variants.map(ProductVariantMapper.toProductVariantDto);
  }
}
