import dayjs from 'dayjs';
import { toDecimalNumber } from '../../utils/calculation.helper';
import { DailySalesDataItemDto } from '../dto/daily-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';
import { DATE_FORMAT } from '../reports.constants';

/**
 * Maps a raw row to DailySalesDataItemDto (date MM/DD/YYYY, numbers with 2 decimals).
 */
export function toDailySalesDataItemDto(raw: SalesByPeriodRawRow): DailySalesDataItemDto {
  const d = raw.date && dayjs(raw.date).isValid() ? dayjs(raw.date) : null;
  const dateFormatted = d ? d.format(DATE_FORMAT) : '';
  return {
    date: dateFormatted,
    total: toDecimalNumber(raw.total),
    transactions: Math.floor(toDecimalNumber(raw.transactions)),
    items: Math.floor(toDecimalNumber(raw.items)),
    discount: toDecimalNumber(raw.discount),
  };
}
