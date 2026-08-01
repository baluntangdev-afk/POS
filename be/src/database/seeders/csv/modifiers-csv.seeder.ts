import type { DataSource } from 'typeorm';
import { ModifierGroup } from '../../../modifier-groups/entities/modifier-group.entity';
import { ModifierOption } from '../../../modifier-groups/entities/modifier-option.entity';
import { SeederHelper } from '../../../utils/seeder.helper';

interface OptionData {
  name: string;
  /** Kept as a string — ModifierOption.priceAddOn is a decimal column typed as string. */
  priceAddOn: string;
  isAvailable: boolean;
  sortOrder: number;
}

interface GroupData {
  name: string;
  description: string;
  selectionType: string;
  isRequired: boolean;
  minSelection: number;
  maxSelection: number;
  options: OptionData[];
}

const toBool = (v: string): boolean => v.trim().toLowerCase() === 'true';

/**
 * Collapses the flat CSV rows into unique modifier groups. Rows sharing a
 * Modifier Group Name accumulate into one group (the first row's group-level
 * fields win); each row contributes one option in file order. The
 * `Linked Product Group` column is intentionally ignored — category linking is
 * out of scope for this importer.
 */
function groupRows(rows: string[][]): GroupData[] {
  const groupMap = new Map<string, GroupData>();

  for (const row of rows) {
    const [
      groupName,
      groupDesc,
      selectionType,
      isRequired,
      minSelection,
      maxSelection,
      ,
      optionName,
      optionPrice,
      optionAvailable,
    ] = row;

    let group = groupMap.get(groupName);
    if (!group) {
      group = {
        name: groupName,
        description: groupDesc ?? '',
        selectionType: (selectionType ?? 'single').trim().toLowerCase(),
        isRequired: toBool(isRequired ?? 'false'),
        minSelection: parseInt(minSelection, 10),
        maxSelection: parseInt(maxSelection, 10),
        options: [],
      };
      groupMap.set(groupName, group);
    }

    group.options.push({
      name: optionName.trim(),
      priceAddOn: (optionPrice ?? '').trim(),
      isAvailable: toBool(optionAvailable ?? 'true'),
      sortOrder: group.options.length,
    });
  }

  return [...groupMap.values()];
}

/**
 * Seeds modifier groups and their options from validated CSV rows, then makes
 * the CSV authoritative: any modifier group or option NOT present in the CSV is
 * soft-deleted. Idempotent — upserts by name (groups) and group:name (options),
 * undeleting matches, so it is safe to run on every install and recovery.
 */
export class ModifiersCsvSeeder {
  async run(dataSource: DataSource, rows: string[][]): Promise<void> {
    const seederHelper = new SeederHelper(dataSource);
    const adminUser = await seederHelper.getAdminUser();
    const groupRepo = dataSource.getRepository(ModifierGroup);
    const optionRepo = dataSource.getRepository(ModifierOption);

    const groups = groupRows(rows);
    const csvGroupNames = new Set(groups.map((g) => g.name));

    // ── Pass 1: Modifier Groups ───────────────────────────────────────────
    const existingGroups = await groupRepo.find({ withDeleted: true });
    // Key by name (first match) — modifier_groups.name has no unique constraint.
    const groupByName = new Map<string, ModifierGroup>();
    for (const g of existingGroups) {
      if (!groupByName.has(g.name)) groupByName.set(g.name, g);
    }

    const groupsToInsert: Partial<ModifierGroup>[] = [];
    const groupsToUpdate: ModifierGroup[] = [];

    for (const g of groups) {
      const existing = groupByName.get(g.name);
      if (existing) {
        existing.description = g.description;
        existing.selectionType = g.selectionType;
        existing.isRequired = g.isRequired;
        existing.minSelection = g.minSelection;
        existing.maxSelection = g.maxSelection;
        existing.deletedAt = null;
        existing.deletedBy = null;
        existing.updatedBy = adminUser;
        groupsToUpdate.push(existing);
      } else {
        groupsToInsert.push({
          name: g.name,
          description: g.description,
          selectionType: g.selectionType,
          isRequired: g.isRequired,
          minSelection: g.minSelection,
          maxSelection: g.maxSelection,
          createdBy: adminUser,
          updatedBy: adminUser,
        });
      }
    }

    // Soft-delete groups not present in the CSV (CSV is authoritative)
    let groupsDeleted = 0;
    for (const g of existingGroups) {
      if (!csvGroupNames.has(g.name) && !g.deletedAt) {
        g.deletedAt = new Date();
        g.deletedBy = adminUser;
        groupsToUpdate.push(g);
        groupsDeleted++;
      }
    }

    if (groupsToInsert.length > 0) await groupRepo.save(groupsToInsert);
    if (groupsToUpdate.length > 0) await groupRepo.save(groupsToUpdate);
    console.log(
      `  Modifier groups: ${groupsToInsert.length} inserted, ${groupsToUpdate.length - groupsDeleted} updated, ${groupsDeleted} soft-deleted`,
    );

    // Reload groups with IDs for option foreign keys (key by name, first match)
    const allGroups = await groupRepo.find();
    const groupIdByName = new Map<string, ModifierGroup>();
    for (const g of allGroups) {
      if (!groupIdByName.has(g.name)) groupIdByName.set(g.name, g);
    }

    // ── Pass 2: Modifier Options ──────────────────────────────────────────
    const existingOptions = await optionRepo.find({
      withDeleted: true,
      relations: { modifierGroup: true },
    });
    const existingOptionByKey = new Map(
      existingOptions.map((o) => [`${o.modifierGroup.id}:${o.name}`, o]),
    );
    const csvOptionKeys = new Set<string>();
    const optionsToInsert: Partial<ModifierOption>[] = [];
    const optionsToUpdate: ModifierOption[] = [];

    for (const g of groups) {
      const group = groupIdByName.get(g.name);
      if (!group) continue;

      for (const opt of g.options) {
        const key = `${group.id}:${opt.name}`;
        csvOptionKeys.add(key);

        const existing = existingOptionByKey.get(key);
        if (existing) {
          existing.priceAddOn = opt.priceAddOn;
          existing.isAvailable = opt.isAvailable;
          existing.sortOrder = opt.sortOrder;
          existing.deletedAt = null;
          existing.deletedBy = null;
          existing.updatedBy = adminUser;
          optionsToUpdate.push(existing);
        } else {
          optionsToInsert.push({
            modifierGroup: group,
            name: opt.name,
            priceAddOn: opt.priceAddOn,
            isAvailable: opt.isAvailable,
            sortOrder: opt.sortOrder,
            imageUrl: null,
            createdBy: adminUser,
            updatedBy: adminUser,
          });
        }
      }
    }

    // Soft-delete options not present in the CSV (CSV is authoritative)
    let optionsDeleted = 0;
    for (const o of existingOptions) {
      const key = `${o.modifierGroup.id}:${o.name}`;
      if (!csvOptionKeys.has(key) && !o.deletedAt) {
        o.deletedAt = new Date();
        o.deletedBy = adminUser;
        optionsToUpdate.push(o);
        optionsDeleted++;
      }
    }

    if (optionsToInsert.length > 0) await optionRepo.save(optionsToInsert);
    if (optionsToUpdate.length > 0) await optionRepo.save(optionsToUpdate);
    console.log(
      `  Modifier options: ${optionsToInsert.length} inserted, ${optionsToUpdate.length - optionsDeleted} updated, ${optionsDeleted} soft-deleted`,
    );
  }
}
