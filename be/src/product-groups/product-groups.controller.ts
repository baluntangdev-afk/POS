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
import { ProductGroupsService } from './product-groups.service';
import { CreateProductGroupDto } from './dto/create-product-group.dto';
import { ProductGroupDto } from './dto/product-group.dto';
import { ProductGroupQueryDto } from './dto/product-group-query.dto';
import { ProductListItemDto } from './dto/product-list-item.dto';
import { UpdateProductGroupDto } from './dto/update-product-group.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { PaginatedQueryDto } from '../utils/pagination';
import { PaginatedResponse } from '../utils/pagination/dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { File } from 'multer';

@ApiTags('Product Groups')
@Controller('product-groups')
export class ProductGroupsController {
  constructor(private readonly productGroupsService: ProductGroupsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Create a new product group' })
  @ApiBody({
    description: 'Product group creation payload with optional image file',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Beverages' },
        description: { type: 'string', example: 'Cold and hot beverages' },
        image: { type: 'string', format: 'binary' },
      },
      required: ['name'],
    },
  })
  @ApiCreatedResponse({
    description: 'The product group has been created.',
    type: ProductGroupDto,
  })
  create(
    @Body() createProductGroupDto: CreateProductGroupDto,
    @UploadedFile() image: File,
    @CurrentUser() causer: User,
  ) {
    return this.productGroupsService.create(createProductGroupDto, image, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all product groups' })
  @ApiOkResponse({
    description: 'Paginated list of product groups.',
    type: PaginatedResponse(ProductGroupDto),
  })
  findAll(@Query() query: ProductGroupQueryDto) {
    return this.productGroupsService.findAll(query);
  }

  @Get(':id/products')
  @ApiOperation({ summary: 'List products by product group ID (paginated)' })
  @ApiParam({ name: 'id', description: 'Product group ID', example: 1 })
  @ApiOkResponse({
    description: 'Paginated list of products in the group.',
    type: PaginatedResponse(ProductListItemDto),
  })
  findProductsByGroupId(@Param('id') id: string, @Query() query: PaginatedQueryDto) {
    return this.productGroupsService.findProductsByGroupId(+id, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a product group by ID' })
  @ApiParam({ name: 'id', description: 'Product group ID', example: 1 })
  @ApiOkResponse({
    description: 'The product group.',
    type: ProductGroupDto,
  })
  findOne(@Param('id') id: string) {
    return this.productGroupsService.findOne(+id);
  }

  @Patch(':id')
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Update a product group by ID' })
  @ApiParam({ name: 'id', description: 'Product group ID', example: 1 })
  @ApiBody({
    description: 'Partial product group update payload with optional image file',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'Beverages' },
        description: { type: 'string', example: 'Cold and hot beverages' },
        image: { type: 'string', format: 'binary' },
      },
      required: ['name'],
    },
  })
  @ApiOkResponse({
    description: 'The product group has been updated.',
    type: ProductGroupDto,
  })
  update(
    @Param('id') id: string,
    @Body() updateProductGroupDto: UpdateProductGroupDto,
    @UploadedFile() image: File,
    @CurrentUser() causer: User,
  ) {
    return this.productGroupsService.update(+id, updateProductGroupDto, image, causer);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a product group by ID' })
  @ApiParam({ name: 'id', description: 'Product group ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The product group has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User) {
    return this.productGroupsService.remove(+id, causer);
  }
}
