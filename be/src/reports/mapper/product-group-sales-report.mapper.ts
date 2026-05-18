import { toDecimalNumber } from '../../utils/calculation.helper';
import { ProductGroupSalesDataItemDto } from '../dto/product-group-sales-response.dto';
import type { IdNameTotalSalesRawRow } from '../reports.interface';

/**
 * Maps a raw row to ProductGroupSalesDataItemDto (id, name, totalSales with 2 decimals).
 */
export function toProductGroupSalesItemDto(
  row: IdNameTotalSalesRawRow,
): ProductGroupSalesDataItemDto {
  return {
    id: Number(row.id),
    name: row.name,
    totalSales: toDecimalNumber(row.totalSales),
  };
}
