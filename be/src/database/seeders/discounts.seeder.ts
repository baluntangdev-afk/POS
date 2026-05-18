import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Discount } from '../../discounts/entities/discount.entity';
import { DiscountStatus } from '../../discounts/discounts.enum';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { DISCOUNTS_FIXTURE } from './fixtures/discounts.fixture';

/**
 * Seeder: DiscountsSeeder
 */
export class DiscountsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const data = this.getData(adminUser);
    const repo = dataSource.getRepository(Discount);

    const existingNames = await repo
      .createQueryBuilder('d')
      .select('d.name')
      .getMany()
      .then((rows) => new Set(rows.map((r) => r.name)));

    const toInsert = data.filter((d) => !existingNames.has(d.name!));
    if (toInsert.length === 0) {
      console.log('Discounts already seeded, skip');
      return;
    }

    await repo.save(toInsert);
    console.log(`${toInsert.length} discounts seeded`);
  }

  private getData(adminUser: User): Partial<Discount>[] {
    const base = {
      status: DiscountStatus.ACTIVE,
      createdBy: adminUser,
      updatedBy: adminUser,
    };

    return DISCOUNTS_FIXTURE.map((item) => ({
      ...base,
      ...item,
    }));
  }
}
