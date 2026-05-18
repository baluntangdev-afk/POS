import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StoreMenusService } from './store-menus.service';
import { StoreMenusController } from './store-menus.controller';
import { StoreMenu } from './entities/store-menu.entity';
import { MenuItem } from './entities/menu-item.entity';
import { MenuItemModifier } from './entities/menu-item-modifier.entity';
import { ModifierGroup } from '../modifier-groups/entities/modifier-group.entity';
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

@Module({
  imports: [TypeOrmModule.forFeature([StoreMenu, MenuItem, MenuItemModifier, ModifierGroup])],
  controllers: [StoreMenusController],
  providers: [
    StoreMenusService,
    CreateStoreMenuService,
    FindStoreMenusService,
    FindStoreMenuService,
    UpdateStoreMenuService,
    DeleteStoreMenuService,
    FindDefaultStoreMenuService,
    CreateMenuItemService,
    UpdateMenuItemService,
    DeleteMenuItemService,
    FindMenuItemService,
  ],
  exports: [StoreMenusService],
})
export class StoreMenusModule {}
