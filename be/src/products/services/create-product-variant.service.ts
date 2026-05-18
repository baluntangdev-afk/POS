import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateProductVariantDto } from '../dto/create-product.variant.dto';
import { User } from '../../users/entities/user.entity';
import { ProductVariant } from '../entities/product-variant.entity';
import { ProductVariantDto } from '../dto/product-variant.dto';
import { FindProductService } from './find-product.service';
import { ProductVariantMapper } from '../mapper/product-variant.mapper';

@Injectable()
export class CreateProductVariantService {
  constructor(
    @InjectRepository(ProductVariant)
    private readonly productVariantsRepository: Repository<ProductVariant>,
    private readonly findProductService: FindProductService,
  ) {}

  async execute(
    createProductVariantDto: CreateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    const payload: Partial<ProductVariant> = {
      name: createProductVariantDto.name,
      createdBy: causer,
      updatedBy: causer,
    };

    const product = await this.findProductService.execute(createProductVariantDto.productId);
    payload.product = product;

    const entity = this.productVariantsRepository.create(payload);
    const result = await this.productVariantsRepository.save(entity);

    return ProductVariantMapper.toProductVariantDto(result);
  }
}
