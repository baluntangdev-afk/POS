import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateProductVariantDto } from '../dto/update-product-variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantStatus } from '../products.enum';
import { EntityHelper } from '../../utils/entity.helper';
import { RecomputeProductPriceService } from './recompute-product-price.service';

@Injectable()
export class UpdateProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly recomputeProductPriceService: RecomputeProductPriceService,
  ) {}

  async execute(
    id: number,
    updateProductVariantDto: UpdateProductVariantDto,
    causer: User,
  ): Promise<void> {
    const existing = await this.productVariantsRepository.findOne({
      where: { id },
      relations: { product: true },
    });

    if (!existing) {
      throw new NotFoundException('Product variant not found');
    }

    const payload: Partial<ProductVariant> = {
      name: updateProductVariantDto.name,
      price: updateProductVariantDto.price,
      isDefault: updateProductVariantDto.isDefault,
      updatedBy: causer,
    };

    if (updateProductVariantDto.isActive !== undefined) {
      payload.status = updateProductVariantDto.isActive
        ? ProductVariantStatus.ACTIVE
        : ProductVariantStatus.DISABLED;
    }

    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.recomputeProductPriceService.execute(existing.product.id);
  }
}
