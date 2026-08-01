import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CatalogController } from './catalog.controller';
import { CatalogAdminController } from './catalog-admin.controller';
import { CatalogService } from './catalog.service';
import { ProductGroup } from '../product-groups/entities/product-group.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ProductGroup])],
  controllers: [CatalogController, CatalogAdminController],
  providers: [CatalogService],
})
export class CatalogModule {}
