import { Injectable } from '@nestjs/common';
import { ProductQueryDto } from './dto/product-query.dto';
import { User } from '../users/entities/user.entity';
import { ProductVariant } from './entities/product-variant.entity';
import { ProductDto } from './dto/product.dto';
import { ProductDetailsDto } from './dto/product-details/product-details.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateProductDto } from './dto/create-product.dto';
import { File } from 'multer';
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { FindProductDetailsService } from './services/find-product-details.service';

@Injectable()
export class ProductsService {
  constructor(
    private readonly createProductService: CreateProductService,
    private readonly findProductsService: FindProductsService,
    private readonly findProductService: FindProductService,
    private readonly findProductVariantsService: FindProductVariantsService,
    private readonly updateProductService: UpdateProductService,
    private readonly findProductDetailsService: FindProductDetailsService,
  ) {}

  async create(
    createProductDto: CreateProductDto,
    image: File,
    causer: User,
    baseUrl: string,
  ): Promise<ProductDto> {
    return this.createProductService.execute(createProductDto, image, causer, baseUrl);
  }

  async findAll(query: ProductQueryDto) {
    return this.findProductsService.execute(query);
  }

  async findOne(id: number): Promise<ProductDetailsDto> {
    return this.findProductDetailsService.execute(id);
  }

  async findProductVariantsByIds(ids: number[]): Promise<Map<number, ProductVariant>> {
    return this.findProductVariantsService.execute(ids);
  }

  async update(
    id: number,
    updateProductDto: UpdateProductDto,
    image: File,
    causer: User,
    baseUrl: string,
  ): Promise<ProductDetailsDto> {
    await this.updateProductService.execute(id, updateProductDto, image, causer, baseUrl);
    return this.findProductDetailsService.execute(id);
  }
}
