import { FindOptionsOrder } from 'typeorm';
import { SORT_PATTERN } from './constants';
import type { ParseSortOptions } from './interfaces';

/**
 * Parses a sort query string (e.g. "email:ASC", "firstName:DESC") into TypeORM FindOptionsOrder.
 * @param sort - Raw sort string from query params.
 * @param options - Allowed fields and default order.
 * @returns Order object for TypeORM find/query.
 */
export function parseSort<Entity>(
  sort: string | undefined,
  options: ParseSortOptions<Entity>,
): FindOptionsOrder<Entity> {
  const { allowedFields, defaultOrder } = options;
  if (!sort?.trim()) {
    return defaultOrder;
  }
  const match = sort.trim().match(SORT_PATTERN);
  if (!match) {
    return defaultOrder;
  }
  const [, field, direction] = match;
  const order = direction.toUpperCase() as 'ASC' | 'DESC';
  const fieldKey = field as keyof Entity;
  if (!allowedFields.includes(fieldKey)) {
    return defaultOrder;
  }
  return { [fieldKey]: order } as FindOptionsOrder<Entity>;
}
