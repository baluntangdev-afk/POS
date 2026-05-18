import type { DataSource } from 'typeorm';
import { In } from 'typeorm';
import type { Seeder } from './seeder.interface';
import { Material } from '../../materials/entities/material.entity';
import { MaterialType } from '../../material-types/entities/material-type.entity';
import { Uom } from '../../uom/entities/uom.entity';
import { BaseStatus } from '../../utils/shared-enums';
import { SeederHelper } from '../../utils/seeder.helper';
import { User } from '../../users/entities/user.entity';
import { MATERIALS_FIXTURE, formatMaterialCodeSequence } from './fixtures/materials.fixture';

/**
 * Seeder: MaterialsSeeder
 * Requires MaterialTypesSeeder and UomSeeder to run first.
 * Material codes are generated as {materialTypeCode}{4-digit sequence}, e.g. RAW0001.
 */
export class MaterialsSeeder implements Seeder {
  public async run(dataSource: DataSource): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const materialTypeRepo = dataSource.getRepository(MaterialType);
    const uomRepo = dataSource.getRepository(Uom);
    const materialRepo = dataSource.getRepository(Material);
    const materialTypeByCode = await this.getMaterialTypeMap(materialTypeRepo);
    const uomByCode = await this.getUomMap(uomRepo);

    const existingMaterials = await materialRepo
      .createQueryBuilder('m')
      .select(['m.materialCode', 'm.materialName'])
      .getMany();

    const existingNames = new Set(existingMaterials.map((r) => r.materialName));
    const maxSeqByType = this.getMaxSequenceByType(existingMaterials.map((r) => r.materialCode));

    const toInsertItems = MATERIALS_FIXTURE.filter((item) => !existingNames.has(item.materialName));
    if (toInsertItems.length === 0) {
      console.log('Materials already seeded, skip');
      return;
    }

    const data = await this.getDataWithGeneratedCodes(
      adminUser,
      toInsertItems,
      materialTypeByCode,
      uomByCode,
      maxSeqByType,
    );

    const persistedData = await materialRepo.save(data);
    await materialRepo.save(persistedData);
    console.log(`${persistedData.length} materials seeded`);
  }

  /** Parse existing material codes to get max sequence per type (format: {typeCode}{4 digits}). */
  private getMaxSequenceByType(existingCodes: string[]): Map<string, number> {
    const maxByType = new Map<string, number>();
    const pattern = /^(.{3})(\d{4})$/;
    for (const code of existingCodes) {
      const match = code.match(pattern);
      if (match) {
        const [, typePrefix, seqStr] = match;
        const seq = parseInt(seqStr, 10);
        const current = maxByType.get(typePrefix) ?? 0;
        if (seq > current) {
          maxByType.set(typePrefix, seq);
        }
      }
    }
    return maxByType;
  }

  private async getMaterialTypeMap(repo: {
    find: (opts: object) => Promise<MaterialType[]>;
  }): Promise<Map<string, MaterialType>> {
    const codes = [...new Set(MATERIALS_FIXTURE.map((f) => f.materialTypeCode))];
    const types = await repo.find({ where: { materialTypeCode: In(codes) } });
    return new Map(types.map((t) => [t.materialTypeCode, t]));
  }

  private async getUomMap(repo: {
    find: (opts: object) => Promise<Uom[]>;
  }): Promise<Map<string, Uom>> {
    const codes = [...new Set(MATERIALS_FIXTURE.map((f) => f.standardBaseUnitCode))];
    const uoms = await repo.find({ where: { code: In(codes) } });
    return new Map(uoms.map((u) => [u.code, u]));
  }

  private getDataWithGeneratedCodes(
    adminUser: User,
    items: typeof MATERIALS_FIXTURE,
    materialTypeByCode: Map<string, MaterialType>,
    uomByCode: Map<string, Uom>,
    maxSeqByType: Map<string, number>,
  ): Partial<Material>[] {
    const base = { status: BaseStatus.ACTIVE, createdBy: adminUser, updatedBy: adminUser };
    const nextSeqByType = new Map(maxSeqByType);

    return items.map((item) => {
      const materialType = materialTypeByCode.get(item.materialTypeCode);
      const standardBaseUnit = uomByCode.get(item.standardBaseUnitCode);

      if (!materialType || !standardBaseUnit) {
        throw new Error(
          `Material fixture references missing type or UOM: ${item.materialTypeCode}, ${item.standardBaseUnitCode}`,
        );
      }

      const nextSeq = (nextSeqByType.get(item.materialTypeCode) ?? 0) + 1;
      nextSeqByType.set(item.materialTypeCode, nextSeq);
      const materialCode = `${item.materialTypeCode}${formatMaterialCodeSequence(nextSeq)}`;

      return {
        ...base,
        materialCode,
        materialName: item.materialName,
        materialType,
        standardBaseUnit,
        standardBaseQty: '50',
        minimumStockLevelQty: '30',
      };
    });
  }
}
