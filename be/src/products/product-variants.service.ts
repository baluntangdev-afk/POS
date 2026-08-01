import { Injectable } from '@nestjs/common';
import { User } from '../users/entities/user.entity';
import { ProductVariantDto } from './dto/product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';
import { CreateProductVariantDto } from './dto/create-product.variant.dto';
import { FindProductVariantsByProductIdService } from './services/find-product-variants-by-product-id.service';
import { CreateProductVariantService } from './services/create-product-variant.service';
import { FindProductVariantService } from './services/find-product-variant.service';
import { UpdateProductVariantService } from './services/update-product-variant.service';
import { FindDistinctVariantNamesService } from './services/find-distinct-variant-names.service';

@Injectable()
export class ProductVariantsService {
  constructor(
    private readonly createProductVariantService: CreateProductVariantService,
    private readonly findProductVariantsByProductIdService: FindProductVariantsByProductIdService,
    private readonly findProductVariantService: FindProductVariantService,
    private readonly updateProductVariantService: UpdateProductVariantService,
    private readonly findDistinctVariantNamesService: FindDistinctVariantNamesService,
  ) {}

  async create(
    createProductVariantDto: CreateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    return this.createProductVariantService.execute(createProductVariantDto, causer);
  }

  async findByProductId(productId: number): Promise<ProductVariantDto[]> {
    return this.findProductVariantsByProductIdService.execute(productId);
  }

  async findOne(id: number): Promise<ProductVariantDto> {
    return this.findProductVariantService.execute(id);
  }

  async findDistinctNames(): Promise<string[]> {
    return this.findDistinctVariantNamesService.execute();
  }

  async update(
    id: number,
    updateProductVariantDto: UpdateProductVariantDto,
    causer: User,
  ): Promise<ProductVariantDto> {
    await this.updateProductVariantService.execute(id, updateProductVariantDto, causer);
    return this.findProductVariantService.execute(id);
  }
}
