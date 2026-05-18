import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { ProductVariantsController } from './product-variants.controller';
import { ProductVariantsService } from './product-variants.service';
import { Product } from './entities/product.entity';
import { ProductVariant } from './entities/product-variant.entity';
import { ProductGroup } from '../product-groups/entities/product-group.entity';
import { CurrenciesModule } from '../currencies/currencies.module';
import { StoreMenusModule } from '../store-menus/store-menus.module';
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { DeleteProductService } from './services/delete-product.service';
import { FindProductGroupService } from './services/find-product-group.service';
import { CreateProductVariantService } from './services/create-product-variant.service';
import { FindProductVariantsByProductIdService } from './services/find-product-variants-by-product-id.service';
import { FindProductVariantService } from './services/find-product-variant.service';
import { UpdateProductVariantService } from './services/update-product-variant.service';
import { FindProductDetailsService } from './services/find-product-details.service';
import { DeleteProductVariantService } from './services/delete-product-variant.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Product, ProductVariant, ProductGroup]),
    CurrenciesModule,
    StoreMenusModule,
  ],
  controllers: [ProductsController, ProductVariantsController],
  providers: [
    ProductsService,
    ProductVariantsService,
    CreateProductService,
    FindProductsService,
    FindProductService,
    FindProductDetailsService,
    FindProductVariantsService,
    UpdateProductService,
    DeleteProductService,
    FindProductGroupService,
    CreateProductVariantService,
    FindProductVariantsByProductIdService,
    FindProductVariantService,
    UpdateProductVariantService,
    DeleteProductVariantService,
  ],
  exports: [ProductsService, ProductVariantsService],
})
export class ProductsModule {}
