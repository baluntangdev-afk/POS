import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { EntityHelper } from '../../utils/entity.helper';

@Injectable()
export class DeleteProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
  ) {}

  async execute(id: number, causer: User): Promise<void> {
    const payload: Partial<ProductVariant> = { deletedBy: causer };
    await this.productVariantsRepository.update(id, EntityHelper.toPartialEntity(payload));
    await this.productVariantsRepository.softDelete(id);
  }
}
