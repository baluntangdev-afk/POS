import { FindOptionsWhere, ILike } from 'typeorm';

/**
 * Builds a TypeORM where condition for text search: OR of ILike on each given field.
 * @param filter - Search string (e.g. from query params).
 * @param fields - Entity field names to search in.
 * @returns Array of where conditions (OR) or undefined when filter is empty.
 */
export function buildFilterWhere<Entity>(
  filter: string | undefined,
  fields: (keyof Entity)[],
): FindOptionsWhere<Entity>[] | undefined {
  if (!filter?.trim() || fields.length === 0) {
    return undefined;
  }
  const pattern = `%${filter.trim()}%`;
  return fields.map((field) => ({
    [field]: ILike(pattern),
  })) as FindOptionsWhere<Entity>[];
}
