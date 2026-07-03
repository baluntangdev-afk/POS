import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { EntityHelper } from '../../utils/entity.helper';
import { RecomputeProductPriceService } from './recompute-product-price.service';

@Injectable()
export class DeleteProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly recomputeProductPriceService: RecomputeProductPriceService,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const existing = await this.productVariantsRepository.findOne({
      where: { id },
      relations: { product: true },
    });

    if (!existing) {
      throw new NotFoundException('Product variant not found');
    }

    const payload: Partial<ProductVariant> = { deletedBy: causer };
    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.productVariantsRepository.softDelete(id);
    await this.recomputeProductPriceService.execute(existing.product.id);
  }
}
