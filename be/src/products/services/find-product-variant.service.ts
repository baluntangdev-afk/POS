import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';
import { ProductVariantMapper } from '../mapper/product-variant.mapper';

@Injectable()
export class FindProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(id: number): Promise<ProductVariantDto> {
    const productVariant = await this.productVariantsRepository.findOne({
      where: { id },
      relations: {
        product: true,
      },
    });

    if (!productVariant) {
      throw new NotFoundException('Product variant not found');
    }

    return ProductVariantMapper.toProductVariantDto(productVariant);
  }
}
