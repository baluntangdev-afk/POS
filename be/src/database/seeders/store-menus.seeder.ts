import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { StoreMenu } from '../../store-menus/entities/store-menu.entity';
import { StoreMenuStatus } from '../../store-menus/store-menus.enum';
import { SeederHelper } from '../../utils/seeder.helper';

const DEFAULT_STORE_MENU_NAME = 'DEFAULT';

/**
 * Seeder: StoreMenusSeeder
 * Creates one store menu named DEFAULT if it does not exist.
 */
export class StoreMenusSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const repo = dataSource.getRepository(StoreMenu);
    const existing = await repo.findOne({ where: { name: DEFAULT_STORE_MENU_NAME } });
    if (existing) {
      console.log('Store menu already seeded, skip');
      return;
    }
    const data: Partial<StoreMenu> = {
      name: DEFAULT_STORE_MENU_NAME,
      description: null,
      status: StoreMenuStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };
    await repo.save(data);
    console.log('1 store menu seeded');
  }
}
