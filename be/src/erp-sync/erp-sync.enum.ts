export enum ErpOrderPushStatus {
  PENDING = 'Pending',
  SENT = 'Sent',
  FAILED = 'Failed',
}

export type ErpReportType = 'x_reading' | 'cashier_daily' | 'z_reading';
