import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiResponse,
  ApiConsumes,
} from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { ProductDto } from './dto/product.dto';
import { ProductQueryDto } from './dto/product-query.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { PaginatedResponse } from '../utils/pagination/dto';
import { ProductDetailsDto } from './dto/product-details/product-details.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { File } from 'multer';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Create a new product' })
  @ApiBody({
    description: 'Product creation payload with optional image file',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Cappuccino' },
        description: { type: 'string', example: 'Classic Italian coffee drink' },
        groupId: { type: 'number', example: 1 },
        image: { type: 'string', format: 'binary' },
      },
      required: ['name', 'groupId'],
    },
  })
  @ApiCreatedResponse({
    description: 'The product has been created.',
    type: ProductDto,
  })
  create(
    @Body() createProductDto: CreateProductDto,
    @UploadedFile() image: File,
    @CurrentUser() causer: User,
  ) {
    return this.productsService.create(createProductDto, image, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all products' })
  @ApiOkResponse({
    description: 'Paginated list of products.',
    type: PaginatedResponse(ProductDto),
  })
  findAll(@Query() query: ProductQueryDto) {
    return this.productsService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a product by ID' })
  @ApiParam({ name: 'id', description: 'Product ID', example: 1 })
  @ApiOkResponse({
    description: 'Product with details.',
    type: ProductDetailsDto,
  })
  findOne(@Param('id') id: string) {
    return this.productsService.findOne(+id);
  }

  @Patch(':id')
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Update a product by ID' })
  @ApiParam({ name: 'id', description: 'Product ID', example: 1 })
  @ApiBody({
    description: 'Partial product update payload with optional image file',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Cappuccino' },
        description: { type: 'string', example: 'Classic Italian coffee drink' },
        groupId: { type: 'number', example: 1 },
        image: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiOkResponse({
    description: 'The product has been updated.',
    type: ProductDetailsDto,
  })
  update(
    @Param('id') id: string,
    @Body() updateProductDto: UpdateProductDto,
    @UploadedFile() image: File,
    @CurrentUser() causer: User,
  ) {
    return this.productsService.update(+id, updateProductDto, image, causer);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a product by ID' })
  @ApiParam({ name: 'id', description: 'Product ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The product has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.productsService.remove(+id, causer);
  }
}
