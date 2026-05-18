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
import { DeleteProductService } from './services/delete-product.service';

@Injectable()
export class ProductsService {
  constructor(
    private readonly createProductService: CreateProductService,
    private readonly findProductsService: FindProductsService,
    private readonly findProductService: FindProductService,
    private readonly findProductVariantsService: FindProductVariantsService,
    private readonly updateProductService: UpdateProductService,
    private readonly findProductDetailsService: FindProductDetailsService,
    private readonly deleteProductService: DeleteProductService,
  ) {}

  async create(createProductDto: CreateProductDto, image: File, causer: User): Promise<ProductDto> {
    return this.createProductService.execute(createProductDto, image, causer);
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
  ): Promise<ProductDetailsDto> {
    await this.updateProductService.execute(id, updateProductDto, image, causer);
    return this.findProductDetailsService.execute(id);
  }

  async remove(id: number, causer: User) {
    await this.findProductDetailsService.execute(id);
    await this.deleteProductService.execute(id, causer);
    return { message: 'Product deleted successfully' };
  }
}
