import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UpdateProductVariantDto } from '../dto/update-product-variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class UpdateProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(
    id: number,
    updateProductVariantDto: UpdateProductVariantDto,
    causer: User,
  ): Promise<void> {
    const payload: Partial<ProductVariant> = {
      name: updateProductVariantDto.name,
      isDefault: updateProductVariantDto.isDefault,
      updatedBy: causer,
    };

    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
  }
}
