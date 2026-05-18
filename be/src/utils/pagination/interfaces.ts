import { FindOptionsOrder } from 'typeorm';

/**
 * Result shape for a paginated list response.
 */
export class PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}

/**
 * Options for parsing a sort query string into TypeORM order.
 */
export interface ParseSortOptions<Entity> {
  /** Allowed entity field names for sorting. */
  allowedFields: (keyof Entity)[];
  /** Default order when sort is missing or invalid. */
  defaultOrder: FindOptionsOrder<Entity>;
}

/**
 * Plain query params for pagination (e.g. from URL).
 */
export interface PaginatedQueryParams {
  page: number;
  limit: number;
  sort?: string;
  filter?: string;
}
