import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiParam, ApiOkResponse, ApiCreatedResponse } from '@nestjs/swagger';
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

  @Delete('categories/:id')
  @UseGuards(AdminOrSupervisorGuard)
  @ApiOperation({ summary: 'Delete a category (admin/supervisor only)' })
  @ApiParam({ name: 'id', description: 'Category ID', example: 1 })
  @ApiOkResponse({ description: 'Category deleted.' })
  async deleteCategory(
    @Param('id') id: string,
    @CurrentUser() causer: User,
  ): Promise<{ success: boolean; message: string }> {
    try {
      const result = await this.catalogService.deleteCategory(+id, causer);
      return { success: true, message: result.message };
    } catch (error) {
      if (error instanceof HttpException) throw error;
      const message = error instanceof Error ? error.message : 'Internal server error';
      const status =
        message === 'Category not found' ? HttpStatus.NOT_FOUND : HttpStatus.INTERNAL_SERVER_ERROR;
      throw new HttpException({ success: false, error: message }, status);
    }
  }
}
