import type { DataSource } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { PRODUCT_MODIFIER_GROUPS_FIXTURE } from './fixtures/product-modifier-groups.fixture';

export class ProductModifierGroupsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const productNames = [...new Set(PRODUCT_MODIFIER_GROUPS_FIXTURE.map((l) => l.productName))];
    const modifierGroupNames = [
      ...new Set(PRODUCT_MODIFIER_GROUPS_FIXTURE.map((l) => l.modifierGroupName)),
    ];

    const products: { id: number; name: string }[] = await dataSource.query(
      `SELECT id, name FROM products WHERE name = ANY($1) AND deleted_at IS NULL`,
      [productNames],
    );
    const productByName = new Map(products.map((p) => [p.name, p.id]));

    const modifierGroups: { id: number; name: string }[] = await dataSource.query(
      `SELECT id, name FROM modifier_groups WHERE name = ANY($1) AND deleted_at IS NULL`,
      [modifierGroupNames],
    );
    const modifierGroupByName = new Map(modifierGroups.map((g) => [g.name, g.id]));

    let upserted = 0;
    for (const link of PRODUCT_MODIFIER_GROUPS_FIXTURE) {
      const productId = productByName.get(link.productName);
      const modifierGroupId = modifierGroupByName.get(link.modifierGroupName);
      if (!productId || !modifierGroupId) continue;

      await dataSource.query(
        `INSERT INTO product_modifier_groups (product_id, modifier_group_id, sort_order)
         VALUES ($1, $2, $3)
         ON CONFLICT (product_id, modifier_group_id)
         DO UPDATE SET sort_order = EXCLUDED.sort_order`,
        [productId, modifierGroupId, link.sortOrder],
      );
      upserted++;
    }

    console.log(`Product–modifier-group links: ${upserted} upserted`);
  }
}
