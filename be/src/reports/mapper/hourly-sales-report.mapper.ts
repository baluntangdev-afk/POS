import dayjs from 'dayjs';
import { toDecimalNumber } from '../../utils/calculation.helper';
import { HourlySalesDataItemDto } from '../dto/hourly-sales-response.dto';
import type { SalesByPeriodRawRow } from '../reports.interface';
import { DATE_FORMAT, HOUR_FORMAT } from '../reports.constants';

/**
 * Maps a raw row to HourlySalesDataItemDto (date MM/DD/YYYY, hour e.g. 01:00 PM, numbers with 2 decimals).
 */
export function toHourlySalesDataItemDto(raw: SalesByPeriodRawRow): HourlySalesDataItemDto {
  const d = raw.date && dayjs(raw.date).isValid() ? dayjs(raw.date) : null;
  const dateFormatted = d ? d.format(DATE_FORMAT) : '';
  const hourFormatted = d ? d.format(HOUR_FORMAT) : '';
  return {
    date: dateFormatted,
    hour: hourFormatted,
    total: toDecimalNumber(raw.total),
    transactions: Math.floor(toDecimalNumber(raw.transactions)),
    items: Math.floor(toDecimalNumber(raw.items)),
    discount: toDecimalNumber(raw.discount),
  };
}
