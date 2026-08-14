import { Controller, Get, Post } from '@nestjs/common';
import { ErpMenuSyncService } from './services/erp-menu-sync.service';
import { ErpOrderPushService } from './services/erp-order-push.service';
import { ErpReportPushService } from './services/erp-report-push.service';
import { ErpClientService } from './services/erp-client.service';
import { AppConfigService } from '../config/config.service';

@Controller('erp-sync')
export class ErpSyncController {
  constructor(
    private readonly config: AppConfigService,
    private readonly erpClient: ErpClientService,
    private readonly menuSync: ErpMenuSyncService,
    private readonly orderPush: ErpOrderPushService,
    private readonly reportPush: ErpReportPushService,
  ) {}

  /** On-demand menu pull from the ERP (also runs on a schedule). */
  @Post('menu')
  async syncMenu() {
    return this.menuSync.syncMenu();
  }

  /** Push closed X / Daily / Z snapshots that were never synced to ERP. */
  @Post('reports/backfill')
  async backfillReports() {
    return this.reportPush.backfillFromHistory();
  }

  @Get('status')
  async status() {
    return {
      enabled: this.config.erpSyncEnabled,
      configured: this.erpClient.isConfigured,
      erp_base_url: this.config.erpBaseUrl || null,
      erp_store_code: this.config.erpStoreCode || null,
      erp_terminal_id: this.config.erpTerminalId || null,
      last_menu_sync: this.menuSync.status,
      order_push_queue: await this.orderPush.queueStatus(),
      report_push_queue: await this.reportPush.queueStatus(),
    };
  }
}
