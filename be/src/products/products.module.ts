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
import { CreateProductService } from './services/create-product.service';
import { FindProductsService } from './services/find-products.service';
import { FindProductService } from './services/find-product.service';
import { FindProductVariantsService } from './services/find-product-variants.service';
import { UpdateProductService } from './services/update-product.service';
import { FindProductGroupService } from './services/find-product-group.service';
import { CreateProductVariantService } from './services/create-product-variant.service';
import { FindProductVariantsByProductIdService } from './services/find-product-variants-by-product-id.service';
import { FindProductVariantService } from './services/find-product-variant.service';
import { UpdateProductVariantService } from './services/update-product-variant.service';
import { FindProductDetailsService } from './services/find-product-details.service';
import { RecomputeProductPriceService } from './services/recompute-product-price.service';
import { FindDistinctVariantNamesService } from './services/find-distinct-variant-names.service';
import { ImportProductsCsvService } from './services/import-products-csv.service';

@Module({
  imports: [TypeOrmModule.forFeature([Product, ProductVariant, ProductGroup]), CurrenciesModule],
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
    FindProductGroupService,
    CreateProductVariantService,
    FindProductVariantsByProductIdService,
    FindProductVariantService,
    UpdateProductVariantService,
    RecomputeProductPriceService,
    FindDistinctVariantNamesService,
    ImportProductsCsvService,
  ],
  exports: [ProductsService, ProductVariantsService],
})
export class ProductsModule {}
