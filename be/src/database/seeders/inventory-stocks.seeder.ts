import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { InventoryStock } from '../../inventory-stocks/entities/inventory-stock.entity';
import { Material } from '../../materials/entities/material.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';

/**
 * Seeder: InventoryStocksSeeder
 * Requires MaterialsSeeder and UomSeeder to run first.
 * Creates one inventory stock per material; unit follows material's standard base UOM.
 */
export class InventoryStocksSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const materialRepo = dataSource.getRepository(Material);
    const stockRepo = dataSource.getRepository(InventoryStock);

    const materials = await materialRepo.find({
      relations: { standardBaseUnit: true },
    });
    if (materials.length === 0) {
      console.log('No materials found, skip inventory stocks');
      return;
    }

    const materialIds = materials.map((m) => m.id);
    const existingStocks = await stockRepo.find({
      where: { material: { id: In(materialIds) } },
      select: { id: true, material: { id: true } },
      relations: { material: true },
    });
    const materialIdsWithStock = new Set(
      existingStocks.map((s) => s.material?.id).filter((id): id is number => id != null),
    );
    const materialsToSeed = materials.filter((m) => !materialIdsWithStock.has(m.id));
    if (materialsToSeed.length === 0) {
      console.log('Inventory stocks already seeded, skip');
      return;
    }

    const data = await this.getData(adminUser, materialsToSeed);
    await stockRepo.save(data);
    console.log(`${data.length} inventory stocks seeded`);
  }

  private getData(adminUser: User, materials: Material[]): Partial<InventoryStock>[] {
    const base = {
      productVariant: null,
      createdBy: adminUser,
      updatedBy: adminUser,
    };

    return materials.map((material) => ({
      ...base,
      material,
      unit: material.standardBaseUnit,
      quantityOnHand: '500',
    }));
  }
}
