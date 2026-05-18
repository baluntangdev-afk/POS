import { Injectable } from '@nestjs/common';
import { CreateStoreMenuDto } from './dto/create-store-menu.dto';
import { UpdateStoreMenuDto } from './dto/update-store-menu.dto';
import { StoreMenuDto } from './dto/store-menu.dto';
import { StoreMenuQueryDto } from './dto/store-menu-query.dto';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { MenuItemDto } from './dto/menu-item.dto';
import { User } from '../users/entities/user.entity';
import { PaginatedResult } from '../utils/pagination';
import { CreateStoreMenuService } from './services/create-store-menu.service';
import { FindStoreMenusService } from './services/find-store-menus.service';
import { FindStoreMenuService } from './services/find-store-menu.service';
import { UpdateStoreMenuService } from './services/update-store-menu.service';
import { DeleteStoreMenuService } from './services/delete-store-menu.service';
import { FindDefaultStoreMenuService } from './services/find-default-store-menu.service';
import { CreateMenuItemService } from './services/create-menu-item.service';
import { UpdateMenuItemService } from './services/update-menu-item.service';
import { DeleteMenuItemService } from './services/delete-menu-item.service';
import { FindMenuItemService } from './services/find-menu-item.service';

@Injectable()
export class StoreMenusService {
  constructor(
    private readonly createStoreMenuService: CreateStoreMenuService,
    private readonly findStoreMenusService: FindStoreMenusService,
    private readonly findStoreMenuService: FindStoreMenuService,
    private readonly updateStoreMenuService: UpdateStoreMenuService,
    private readonly deleteStoreMenuService: DeleteStoreMenuService,
    private readonly findDefaultStoreMenuService: FindDefaultStoreMenuService,
    private readonly createMenuItemService: CreateMenuItemService,
    private readonly updateMenuItemService: UpdateMenuItemService,
    private readonly deleteMenuItemService: DeleteMenuItemService,
    private readonly findMenuItemService: FindMenuItemService,
  ) {}

  async create(createStoreMenuDto: CreateStoreMenuDto, causer: User): Promise<StoreMenuDto> {
    return this.createStoreMenuService.execute(createStoreMenuDto, causer);
  }

  async findAll(query: StoreMenuQueryDto): Promise<PaginatedResult<StoreMenuDto>> {
    return this.findStoreMenusService.execute(query);
  }

  async findOne(id: number): Promise<StoreMenuDto> {
    return this.findStoreMenuService.execute(id);
  }

  async findDefaultStoreMenu() {
    return this.findDefaultStoreMenuService.execute();
  }

  async update(
    id: number,
    updateStoreMenuDto: UpdateStoreMenuDto,
    causer: User,
  ): Promise<StoreMenuDto> {
    await this.updateStoreMenuService.execute(id, updateStoreMenuDto, causer);
    return this.findStoreMenuService.execute(id);
  }

  async remove(id: number, causer: User): Promise<{ message: string }> {
    await this.findStoreMenuService.execute(id);
    await this.deleteStoreMenuService.execute(id, causer);
    return { message: 'Store menu deleted successfully' };
  }

  async createMenuItem(createMenuItemDto: CreateMenuItemDto, causer: User): Promise<MenuItemDto> {
    return this.createMenuItemService.execute(createMenuItemDto, causer);
  }

  async findMenuItem(id: number): Promise<MenuItemDto> {
    return this.findMenuItemService.execute(id);
  }

  async updateMenuItem(id: number, updateMenuItemDto: UpdateMenuItemDto): Promise<MenuItemDto> {
    await this.updateMenuItemService.execute(id, updateMenuItemDto);
    return this.findMenuItemService.execute(id);
  }

  async removeMenuItem(id: number): Promise<{ message: string }> {
    await this.findMenuItemService.execute(id);
    await this.deleteMenuItemService.execute(id);
    return { message: 'Menu item deleted successfully' };
  }
}
