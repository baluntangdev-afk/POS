import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiResponse,
} from '@nestjs/swagger';
import { CreateProductVariantDto } from './dto/create-product.variant.dto';
import { ProductVariantDto } from './dto/product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { ProductVariantsService } from './product-variants.service';

@ApiTags('Product Variants')
@Controller('product-variants')
export class ProductVariantsController {
  constructor(private readonly productVariantsService: ProductVariantsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new product variant' })
  @ApiBody({
    description: 'Product variant creation payload',
    type: CreateProductVariantDto,
  })
  @ApiCreatedResponse({
    description: 'The product variant has been created.',
    type: ProductVariantDto,
  })
  create(@Body() createProductVariantDto: CreateProductVariantDto, @CurrentUser() causer: User) {
    return this.productVariantsService.create(createProductVariantDto, causer);
  }

  @Get('by-product/:productId')
  @ApiOperation({ summary: 'Get product variants by product ID' })
  @ApiParam({ name: 'productId', description: 'Product ID', example: 1 })
  @ApiOkResponse({
    description: 'List of product variants for the specified product.',
    type: [ProductVariantDto],
  })
  findByProductId(@Param('productId') productId: string) {
    return this.productVariantsService.findByProductId(+productId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a product variant by ID' })
  @ApiParam({ name: 'id', description: 'Product Variant ID', example: 1 })
  @ApiOkResponse({
    description: 'Product variant details.',
    type: ProductVariantDto,
  })
  findOne(@Param('id') id: string) {
    return this.productVariantsService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a product variant by ID' })
  @ApiParam({ name: 'id', description: 'Product Variant ID', example: 1 })
  @ApiBody({
    description: 'Partial product variant update payload',
    type: UpdateProductVariantDto,
  })
  @ApiOkResponse({
    description: 'The product variant has been updated.',
    type: ProductVariantDto,
  })
  update(
    @Param('id') id: string,
    @Body() updateProductVariantDto: UpdateProductVariantDto,
    @CurrentUser() causer: User,
  ) {
    return this.productVariantsService.update(+id, updateProductVariantDto, causer);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a product variant by ID' })
  @ApiParam({ name: 'id', description: 'Product Variant ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The product variant has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.productVariantsService.remove(+id, causer);
  }
}
