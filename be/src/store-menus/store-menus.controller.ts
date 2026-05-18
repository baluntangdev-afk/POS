import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiResponse,
} from '@nestjs/swagger';
import { StoreMenusService } from './store-menus.service';
import { CreateStoreMenuDto } from './dto/create-store-menu.dto';
import { UpdateStoreMenuDto } from './dto/update-store-menu.dto';
import { StoreMenuDto } from './dto/store-menu.dto';
import { StoreMenuQueryDto } from './dto/store-menu-query.dto';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { MenuItemDto } from './dto/menu-item.dto';
import { CurrentUser } from '../utils/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { PaginatedResult } from '../utils/pagination';

@ApiTags('Store Menus')
@Controller('store-menus')
export class StoreMenusController {
  constructor(private readonly storeMenusService: StoreMenusService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new store menu' })
  @ApiBody({ type: CreateStoreMenuDto, description: 'Store menu creation payload' })
  @ApiCreatedResponse({ description: 'The store menu has been created.', type: StoreMenuDto })
  create(
    @Body() createStoreMenuDto: CreateStoreMenuDto,
    @CurrentUser() causer: User,
  ): Promise<StoreMenuDto> {
    return this.storeMenusService.create(createStoreMenuDto, causer);
  }

  @Get()
  @ApiOperation({ summary: 'List all store menus' })
  @ApiOkResponse({ description: 'Paginated list of store menus.' })
  findAll(@Query() query: StoreMenuQueryDto): Promise<PaginatedResult<StoreMenuDto>> {
    return this.storeMenusService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a store menu by ID' })
  @ApiParam({ name: 'id', description: 'Store menu ID', example: 1 })
  @ApiOkResponse({ description: 'The store menu.', type: StoreMenuDto })
  findOne(@Param('id') id: string): Promise<StoreMenuDto> {
    return this.storeMenusService.findOne(+id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a store menu by ID' })
  @ApiParam({ name: 'id', description: 'Store menu ID', example: 1 })
  @ApiBody({ type: UpdateStoreMenuDto, description: 'Partial store menu update payload' })
  @ApiOkResponse({ description: 'The store menu has been updated.', type: StoreMenuDto })
  update(
    @Param('id') id: string,
    @Body() updateStoreMenuDto: UpdateStoreMenuDto,
    @CurrentUser() causer: User,
  ): Promise<StoreMenuDto> {
    return this.storeMenusService.update(+id, updateStoreMenuDto, causer);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a store menu by ID' })
  @ApiParam({ name: 'id', description: 'Store menu ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The store menu has been removed.' })
  remove(@Param('id') id: string, @CurrentUser() causer: User): Promise<{ message: string }> {
    return this.storeMenusService.remove(+id, causer);
  }

  @Post('menu-items')
  @ApiOperation({ summary: 'Create a new menu item in default store menu' })
  @ApiBody({ type: CreateMenuItemDto, description: 'Menu item creation payload' })
  @ApiCreatedResponse({ description: 'The menu item has been created.', type: MenuItemDto })
  createMenuItem(
    @Body() createMenuItemDto: CreateMenuItemDto,
    @CurrentUser() causer: User,
  ): Promise<MenuItemDto> {
    return this.storeMenusService.createMenuItem(createMenuItemDto, causer);
  }

  @Get('menu-items/:id')
  @ApiOperation({ summary: 'Get a menu item by ID from default store menu' })
  @ApiParam({ name: 'id', description: 'Menu item ID', example: 1 })
  @ApiOkResponse({ description: 'The menu item.', type: MenuItemDto })
  findMenuItem(@Param('id') id: string): Promise<MenuItemDto> {
    return this.storeMenusService.findMenuItem(+id);
  }

  @Patch('menu-items/:id')
  @ApiOperation({ summary: 'Update a menu item by ID in default store menu' })
  @ApiParam({ name: 'id', description: 'Menu item ID', example: 1 })
  @ApiBody({ type: UpdateMenuItemDto, description: 'Partial menu item update payload' })
  @ApiOkResponse({ description: 'The menu item has been updated.', type: MenuItemDto })
  updateMenuItem(
    @Param('id') id: string,
    @Body() updateMenuItemDto: UpdateMenuItemDto,
  ): Promise<MenuItemDto> {
    return this.storeMenusService.updateMenuItem(+id, updateMenuItemDto);
  }

  @Delete('menu-items/:id')
  @ApiOperation({ summary: 'Remove a menu item by ID from default store menu' })
  @ApiParam({ name: 'id', description: 'Menu item ID', example: 1 })
  @ApiResponse({ status: 200, description: 'The menu item has been removed.' })
  removeMenuItem(@Param('id') id: string): Promise<{ message: string }> {
    return this.storeMenusService.removeMenuItem(+id);
  }
}
