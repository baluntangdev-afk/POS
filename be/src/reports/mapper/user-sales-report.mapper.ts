import { toDecimalNumber } from '../../utils/calculation.helper';
import { UserSalesDataItemDto } from '../dto/user-sales-response.dto';
import type { IdNameTotalSalesRawRow } from '../reports.interface';

/**
 * Maps a raw row to UserSalesDataItemDto (id, name, totalSales with 2 decimals).
 */
export function toUserSalesItemDto(row: IdNameTotalSalesRawRow): UserSalesDataItemDto {
  return {
    id: Number(row.id),
    name: row.name,
    totalSales: toDecimalNumber(row.totalSales),
  };
}
