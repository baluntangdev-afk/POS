import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductGroupsService } from './product-groups.service';
import { ProductGroupsController } from './product-groups.controller';
import { ProductGroup } from './entities/product-group.entity';
import { Product } from '../products/entities/product.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ProductGroup, Product])],
  controllers: [ProductGroupsController],
  providers: [ProductGroupsService],
})
export class ProductGroupsModule {}
