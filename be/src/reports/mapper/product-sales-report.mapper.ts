import { toDecimalNumber } from '../../utils/calculation.helper';
import { ProductSalesDataItemDto } from '../dto/product-sales-response.dto';
import type { IdNameTotalSalesRawRow } from '../reports.interface';

/**
 * Maps a raw row to ProductSalesDataItemDto (id, name, totalSales with 2 decimals).
 */
export function toProductSalesItemDto(row: IdNameTotalSalesRawRow): ProductSalesDataItemDto {
  return {
    id: Number(row.id),
    name: row.name,
    totalSales: toDecimalNumber(row.totalSales),
  };
}
