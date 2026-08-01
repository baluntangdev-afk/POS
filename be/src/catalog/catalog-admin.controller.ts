import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiOkResponse,
  ApiCreatedResponse,
} from '@nestjs/swagger';
import { CatalogService } from './catalog.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { AdminOrSupervisorGuard } from '../auth/guards/admin-or-supervisor.guard';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Catalog Admin')
@Controller('catalog/admin')
export class CatalogAdminController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List all categories including inactive (authenticated users)' })
  @ApiOkResponse({ description: 'All categories sorted by name.' })
  async getAllCategories(): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getAllCategoriesForAdmin();
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Get('products')
  @ApiOperation({
    summary: 'List all products including disabled/unavailable ones (authenticated users)',
  })
  @ApiQuery({ name: 'category_id', required: false, description: 'Filter by category UUID' })
  @ApiQuery({ name: 'search', required: false, description: 'Case-insensitive name search' })
  @ApiOkResponse({ description: 'All products for the given filters, including disabled ones.' })
  async getAllProducts(
    @Query('category_id') categoryId?: string,
    @Query('search') search?: string,
  ): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getProducts(categoryId, search, true);
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Post('categories')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Create a new category (admin/supervisor only)' })
  @ApiCreatedResponse({ description: 'Category created.' })
  async createCategory(
    @Body() dto: CreateCategoryDto,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; data: unknown }> {
    try {
      const data = await this.catalogService.createCategory(dto, causer);
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Patch('categories/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Update a category (admin/supervisor only)' })
  @ApiParam({ name: 'id', description: 'Category ID', example: 1 })
  @ApiOkResponse({ description: 'Category updated.' })
  async updateCategory(
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; data: unknown }> {
    try {
      const data = await this.catalogService.updateCategory(+id, dto, causer);
      return { success: true, data };
    } catch (error) {
      if (error instanceof HttpException) throw error;
      const message = error instanceof Error ? error.message : 'Internal server error';
      const status =
        message === 'Category not found' ? HttpStatus.NOT_FOUND : HttpStatus.INTERNAL_SERVER_ERROR;
      throw new HttpException({ success: false, error: message }, status);
    }
  }
}
