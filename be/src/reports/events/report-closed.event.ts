export enum ReportEvents {
  REPORT_CLOSED = 'report-closed',
}

export type ClosedReportType = 'x_reading' | 'cashier_daily' | 'z_reading';

/** Emitted after a cashier/X/Z report close transaction commits. */
export class ReportClosedEvent {
  constructor(
    public readonly reportType: ClosedReportType,
    public readonly clientReportId: string,
    public readonly snapshot: Record<string, unknown>,
  ) {}
}
