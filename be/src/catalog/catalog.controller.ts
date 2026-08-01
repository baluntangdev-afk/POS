import { Controller, Get, Query, HttpException, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiOkResponse } from '@nestjs/swagger';
import { CatalogService } from './catalog.service';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('Catalog')
@Public()
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List active categories with available product counts' })
  @ApiOkResponse({ description: 'Active categories sorted by sort_order.' })
  async getCategories(): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getCategories();
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Get('products')
  @ApiOperation({ summary: 'List available products with nested category and modifier groups' })
  @ApiQuery({ name: 'category_id', required: false, description: 'Filter by category UUID' })
  @ApiQuery({ name: 'search', required: false, description: 'Case-insensitive name search' })
  @ApiOkResponse({ description: 'Products sorted by sort_order with full modifier nesting.' })
  async getProducts(
    @Query('category_id') categoryId?: string,
    @Query('search') search?: string,
  ): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getProducts(categoryId, search);
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  @Get('modifier-groups')
  @ApiOperation({ summary: 'List all modifier groups with nested modifiers' })
  @ApiOkResponse({ description: 'Modifier groups sorted by name with nested modifiers.' })
  async getModifierGroups(): Promise<{ success: boolean; data: unknown[] }> {
    try {
      const data = await this.catalogService.getModifierGroups();
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Internal server error';
      throw new HttpException({ success: false, error: message }, HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}
