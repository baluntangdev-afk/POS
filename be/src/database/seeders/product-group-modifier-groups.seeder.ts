import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { ModifierGroup } from '../../modifier-groups/entities/modifier-group.entity';
import { ModifierOption } from '../../modifier-groups/entities/modifier-option.entity';
import { SeederHelper } from '../../utils/seeder.helper';
import { PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE } from './fixtures/product-group-modifier-groups.fixture';

const TEMPERATURE_GROUP = {
  name: 'Temperature',
  description: 'Choose your preferred temperature',
  selectionType: 'single' as const,
  isRequired: true,
  minSelection: 1,
  maxSelection: 1,
};

const TEMPERATURE_OPTIONS = [
  { name: 'Hot',  priceAddOn: '0.00', sortOrder: 0, isAvailable: true },
  { name: 'Cold', priceAddOn: '0.00', sortOrder: 1, isAvailable: true },
];

export class ProductGroupModifierGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();

    // ── 1. Ensure Temperature modifier group exists ───────────────────────────
    const mgRepo = dataSource.getRepository(ModifierGroup);
    let temperatureGroup = await mgRepo.findOne({
      where: { name: TEMPERATURE_GROUP.name },
      withDeleted: true,
    });

    if (!temperatureGroup) {
      temperatureGroup = await mgRepo.save(
        mgRepo.create({
          ...TEMPERATURE_GROUP,
          createdBy: adminUser,
          updatedBy: adminUser,
        }),
      );
    } else {
      Object.assign(temperatureGroup, {
        ...TEMPERATURE_GROUP,
        deletedAt: null,
        updatedBy: adminUser,
      });
      temperatureGroup = await mgRepo.save(temperatureGroup);
    }

    // ── 2. Ensure Temperature options exist ───────────────────────────────────
    const moRepo = dataSource.getRepository(ModifierOption);
    for (const opt of TEMPERATURE_OPTIONS) {
      const existing = await moRepo.findOne({
        where: { name: opt.name, modifierGroup: { id: temperatureGroup.id } },
        withDeleted: true,
      });
      if (!existing) {
        await moRepo.save(
          moRepo.create({
            name: opt.name,
            priceAddOn: opt.priceAddOn,
            sortOrder: opt.sortOrder,
            isAvailable: opt.isAvailable,
            modifierGroup: temperatureGroup,
            createdBy: adminUser,
            updatedBy: adminUser,
          }),
        );
      } else {
        Object.assign(existing, { ...opt, deletedAt: null, updatedBy: adminUser });
        await moRepo.save(existing);
      }
    }

    console.log(`Temperature modifier group and options seeded`);

    // ── 3. Resolve product-group and modifier-group IDs by name ──────────────
    const allGroupNames = [
      ...new Set(PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE.map((l) => l.productGroupName)),
    ];
    const allModifierNames = [
      ...new Set(PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE.map((l) => l.modifierGroupName)),
    ];

    const productGroups: { id: number; name: string }[] = await dataSource.query(
      `SELECT id, name FROM product_groups WHERE name = ANY($1) AND deleted_at IS NULL`,
      [allGroupNames],
    );
    const productGroupByName = new Map(productGroups.map((g) => [g.name, g.id]));

    const modifierGroups: { id: number; name: string }[] = await dataSource.query(
      `SELECT id, name FROM modifier_groups WHERE name = ANY($1) AND deleted_at IS NULL`,
      [allModifierNames],
    );
    const modifierGroupByName = new Map(modifierGroups.map((g) => [g.name, g.id]));

    // ── 4. Upsert pivot table records ─────────────────────────────────────────
    let upserted = 0;
    for (const link of PRODUCT_GROUP_MODIFIER_GROUPS_FIXTURE) {
      const productGroupId = productGroupByName.get(link.productGroupName);
      const modifierGroupId = modifierGroupByName.get(link.modifierGroupName);
      if (!productGroupId || !modifierGroupId) continue;

      await dataSource.query(
        `INSERT INTO product_group_modifier_groups (product_group_id, modifier_group_id, sort_order)
         VALUES ($1, $2, $3)
         ON CONFLICT (product_group_id, modifier_group_id)
         DO UPDATE SET sort_order = EXCLUDED.sort_order`,
        [productGroupId, modifierGroupId, link.sortOrder],
      );
      upserted++;
    }

    console.log(`Product-group–modifier-group links: ${upserted} upserted`);
  }
}
