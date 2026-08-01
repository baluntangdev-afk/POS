import { SalesResponseDto } from '../dto/sales-response.dto';
import { toDecimalNumber } from '../../utils/calculation.helper';
import type { SalesReportRawRow } from '../reports.interface';

/**
 * Maps raw sales report query result to SalesResponseDto. Uses 0 for null, undefined, or invalid numbers.
 */
export class SalesReportMapper {
  static toDto(raw: SalesReportRawRow | null | undefined): SalesResponseDto {
    if (raw == null) {
      return {
        totalSales: 0,
        totalDiscount: 0,
        totalRefunds: 0,
        totalItems: 0,
        totalTransactions: 0,
        totalVoidedTransactions: 0,
        totalVoidedAmount: 0,
      };
    }
    return {
      totalSales: toDecimalNumber(raw.totalSales),
      totalDiscount: toDecimalNumber(raw.totalDiscount),
      totalRefunds: toDecimalNumber(raw.totalRefunds),
      totalItems: toDecimalNumber(raw.totalItems),
      totalTransactions: toDecimalNumber(raw.totalTransactions),
      totalVoidedTransactions: toDecimalNumber(raw.totalVoidedTransactions),
      totalVoidedAmount: toDecimalNumber(raw.totalVoidedAmount),
    };
  }
}
