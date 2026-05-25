import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { CatalogCategory } from './entities/catalog-category.entity';
import { CatalogProduct } from './entities/catalog-product.entity';
import { CatalogModifierGroup } from './entities/catalog-modifier-group.entity';
import { CatalogModifier } from './entities/catalog-modifier.entity';
import { CatalogProductModifierGroup } from './entities/catalog-product-modifier-group.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CatalogCategory,
      CatalogProduct,
      CatalogModifierGroup,
      CatalogModifier,
      CatalogProductModifierGroup,
    ]),
  ],
  controllers: [CatalogController],
  providers: [CatalogService],
})
export class CatalogModule {}
