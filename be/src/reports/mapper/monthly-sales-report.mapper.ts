import dayjs from 'dayjs';
import { toDecimalNumber } from '../../utils/calculation.helper';
import { MonthlySalesDataItemDto } from '../dto/monthly-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';

const MONTH_NAME_FORMAT = 'MMMM';
const YEAR_FORMAT = 'YYYY';

/**
 * Maps a raw row to MonthlySalesDataItemDto (month name, year, numbers with 2 decimals).
 */
export function toMonthlySalesDataItemDto(raw: SalesByPeriodRawRow): MonthlySalesDataItemDto {
  const d = raw.date && dayjs(raw.date).isValid() ? dayjs(raw.date) : null;
  const monthFormatted = d ? d.format(MONTH_NAME_FORMAT) : '';
  const yearFormatted = d ? d.format(YEAR_FORMAT) : '';
  return {
    month: monthFormatted,
    year: yearFormatted,
    total: toDecimalNumber(raw.total),
    transactions: Math.floor(toDecimalNumber(raw.transactions)),
    items: Math.floor(toDecimalNumber(raw.items)),
    discount: toDecimalNumber(raw.discount),
  };
}
