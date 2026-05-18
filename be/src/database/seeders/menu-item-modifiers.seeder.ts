import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { MenuItemModifier } from '../../store-menus/entities/menu-item-modifier.entity';
import { MenuItem } from '../../store-menus/entities/menu-item.entity';
import { StoreMenu } from '../../store-menus/entities/store-menu.entity';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { DEFAULT_STORE_MENU_NAME } from './fixtures/menu-items.fixture';
import {
  BEVERAGE_CATEGORY,
  MODIFIER_GROUPS_FOR_BEVERAGES,
  MODIFIER_GROUPS_FOR_OTHERS,
} from './fixtures/menu-item-modifiers.fixture';

/**
 * Seeder: MenuItemModifiersSeeder
 * Requires MenuItemsSeeder and ModifierGroupsSeeder to run first.
 * Beverage menu items get Add-Ons, Temperature, Add Syrup; all others get Add Drink.
 */
export class MenuItemModifiersSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const storeMenuRepo = dataSource.getRepository(StoreMenu);
    const menuItemRepo = dataSource.getRepository(MenuItem);
    const modifierGroupRepo = dataSource.getRepository(ModifierGroup);
    const menuItemModifierRepo = dataSource.getRepository(MenuItemModifier);
    const defaultMenu = await storeMenuRepo.findOne({
      where: { name: DEFAULT_STORE_MENU_NAME },
    });
    if (!defaultMenu) {
      throw new Error(
        `Store menu "${DEFAULT_STORE_MENU_NAME}" not found. Run StoreMenusSeeder and MenuItemsSeeder first.`,
      );
    }
    const menuItems = await menuItemRepo.find({
      where: { storeMenu: { id: defaultMenu.id } },
      select: { id: true, category: true },
    });
    if (menuItems.length === 0) {
      console.log('No menu items found, skip');
      return;
    }
    const allGroupNames = [
      ...new Set([...MODIFIER_GROUPS_FOR_BEVERAGES, ...MODIFIER_GROUPS_FOR_OTHERS]),
    ];
    const modifierGroups = await modifierGroupRepo.find({
      where: { name: In(allGroupNames) },
    });
    const groupByName = new Map(modifierGroups.map((g) => [g.name, g]));
    const missing = allGroupNames.filter((n) => !groupByName.has(n));
    if (missing.length > 0) {
      throw new Error(
        `MenuItemModifiers fixture references missing modifier groups: ${missing.join(', ')}. Run ModifierGroupsSeeder first.`,
      );
    }
    const existing = await menuItemModifierRepo.find({
      relations: { menuItem: true, modifierGroup: true },
      select: { id: true, menuItem: { id: true }, modifierGroup: { id: true } },
    });
    const existingKeySet = new Set(existing.map((e) => `${e.menuItem.id}:${e.modifierGroup.id}`));
    const toInsert: Partial<MenuItemModifier>[] = [];
    for (const menuItem of menuItems) {
      const groupNames =
        menuItem.category === BEVERAGE_CATEGORY
          ? MODIFIER_GROUPS_FOR_BEVERAGES
          : MODIFIER_GROUPS_FOR_OTHERS;
      for (const groupName of groupNames) {
        const modifierGroup = groupByName.get(groupName)!;
        const key = `${menuItem.id}:${modifierGroup.id}`;
        if (existingKeySet.has(key)) continue;
        existingKeySet.add(key);
        toInsert.push({
          menuItem: { id: menuItem.id } as MenuItem,
          modifierGroup,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }
    if (toInsert.length === 0) {
      console.log('Menu item modifiers already seeded, skip');
      return;
    }
    await menuItemModifierRepo.save(toInsert);
    console.log(`${toInsert.length} menu item modifiers seeded`);
  }
}
