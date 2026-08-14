import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { AppConfigService } from '../../config/config.service';
import { CashierDailyReport } from '../../reports/entities/cashier-daily-report.entity';
import { CashierXReading } from '../../reports/entities/cashier-x-reading.entity';
import { ZReading } from '../../reports/entities/z-reading.entity';
import { ReportClosedEvent, ReportEvents } from '../../reports/events/report-closed.event';
import { ErpReportPush } from '../entities/erp-report-push.entity';
import { ErpOrderPushStatus } from '../erp-sync.enum';
import { ErpClientService, ErpReportPayload } from './erp-client.service';

/**
 * Pushes closed X / Daily / Z report snapshots to the ERP after local close commits.
 * Immediate attempt + cron retry; ERP is idempotent on report_type + client_report_id.
 */
@Injectable()
export class ErpReportPushService {
  private readonly logger = new Logger(ErpReportPushService.name);

  private static readonly MAX_ATTEMPTS = 20;
  private static backoffMs(attempts: number): number {
    return Math.min(attempts * 2, 30) * 60 * 1000;
  }

  constructor(
    private readonly config: AppConfigService,
    private readonly erpClient: ErpClientService,
    @InjectRepository(ErpReportPush)
    private readonly pushRepository: Repository<ErpReportPush>,
    @InjectRepository(CashierXReading)
    private readonly xReadingRepository: Repository<CashierXReading>,
    @InjectRepository(CashierDailyReport)
    private readonly dailyReportRepository: Repository<CashierDailyReport>,
    @InjectRepository(ZReading)
    private readonly zReadingRepository: Repository<ZReading>,
  ) {}

  @OnEvent(ReportEvents.REPORT_CLOSED)
  async handleReportClosed(event: ReportClosedEvent): Promise<void> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) return;

    try {
      const row = await this.enqueue(event.reportType, event.clientReportId, event.snapshot);
      await this.pushRow(row.id);
    } catch (err) {
      this.logger.warn(
        `Immediate ERP report push failed for ${event.reportType}/${event.clientReportId}: ${(err as Error).message}`,
      );
    }
  }

  /** Push already-closed report snapshots (e.g. before erp_report_push existed). */
  async backfillFromHistory(): Promise<{ queued: number; pushed: number; errors: string[] }> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) {
      return { queued: 0, pushed: 0, errors: ['ERP sync is not configured'] };
    }

    const errors: string[] = [];
    let queued = 0;
    let pushed = 0;

    const xRows = await this.xReadingRepository.find({ order: { generatedAt: 'ASC' } });
    for (const row of xRows) {
      try {
        const snapshot = { ...(row.snapshot as Record<string, unknown>), id: row.id };
        const entry = await this.enqueue('x_reading', String(row.id), snapshot);
        queued++;
        if (entry.status !== ErpOrderPushStatus.SENT) {
          await this.pushRow(entry.id);
          const refreshed = await this.pushRepository.findOne({ where: { id: entry.id } });
          if (refreshed?.status === ErpOrderPushStatus.SENT) pushed++;
          else if (refreshed?.lastError) errors.push(`x_reading/${row.id}: ${refreshed.lastError}`);
        } else {
          pushed++;
        }
      } catch (err) {
        errors.push(`x_reading/${row.id}: ${(err as Error).message}`);
      }
    }

    const dailyRows = await this.dailyReportRepository.find({ order: { generatedAt: 'ASC' } });
    for (const row of dailyRows) {
      try {
        const snapshot = { ...(row.snapshot as Record<string, unknown>), id: row.id };
        const entry = await this.enqueue('cashier_daily', String(row.id), snapshot);
        queued++;
        if (entry.status !== ErpOrderPushStatus.SENT) {
          await this.pushRow(entry.id);
          const refreshed = await this.pushRepository.findOne({ where: { id: entry.id } });
          if (refreshed?.status === ErpOrderPushStatus.SENT) pushed++;
          else if (refreshed?.lastError) errors.push(`cashier_daily/${row.id}: ${refreshed.lastError}`);
        } else {
          pushed++;
        }
      } catch (err) {
        errors.push(`cashier_daily/${row.id}: ${(err as Error).message}`);
      }
    }

    const zRows = await this.zReadingRepository.find({ order: { generatedAt: 'ASC' } });
    for (const row of zRows) {
      try {
        const snapshot = { ...(row.snapshot as Record<string, unknown>), id: row.id };
        const entry = await this.enqueue('z_reading', String(row.id), snapshot);
        queued++;
        if (entry.status !== ErpOrderPushStatus.SENT) {
          await this.pushRow(entry.id);
          const refreshed = await this.pushRepository.findOne({ where: { id: entry.id } });
          if (refreshed?.status === ErpOrderPushStatus.SENT) pushed++;
          else if (refreshed?.lastError) errors.push(`z_reading/${row.id}: ${refreshed.lastError}`);
        } else {
          pushed++;
        }
      } catch (err) {
        errors.push(`z_reading/${row.id}: ${(err as Error).message}`);
      }
    }

    return { queued, pushed, errors };
  }

  private async enqueue(
    reportType: string,
    clientReportId: string,
    snapshot: Record<string, unknown>,
  ): Promise<ErpReportPush> {
    let row = await this.pushRepository.findOne({
      where: { reportType, clientReportId },
    });
    if (!row) {
      row = await this.pushRepository.save(
        this.pushRepository.create({
          reportType,
          clientReportId,
          snapshot,
        }),
      );
    } else if (row.status === ErpOrderPushStatus.SENT) {
      return row;
    } else {
      row.snapshot = snapshot;
      await this.pushRepository.save(row);
    }
    return row;
  }

  @Cron('*/2 * * * *')
  async retryPending(): Promise<void> {
    if (!this.config.erpSyncEnabled || !this.erpClient.isConfigured) return;

    const rows = await this.pushRepository.find({
      where: { status: In([ErpOrderPushStatus.PENDING, ErpOrderPushStatus.FAILED]) },
      order: { id: 'ASC' },
      take: 50,
    });

    const now = Date.now();
    for (const row of rows) {
      if (row.attempts >= ErpReportPushService.MAX_ATTEMPTS) continue;
      if (
        row.lastAttemptAt &&
        now - row.lastAttemptAt.getTime() < ErpReportPushService.backoffMs(row.attempts)
      ) {
        continue;
      }
      try {
        await this.pushRow(row.id);
      } catch (err) {
        this.logger.warn(`ERP report retry failed for ${row.id}: ${(err as Error).message}`);
      }
    }
  }

  async pushRow(id: number): Promise<void> {
    const row = await this.pushRepository.findOne({ where: { id } });
    if (!row || row.status === ErpOrderPushStatus.SENT) return;

    const payload: ErpReportPayload = {
      report_type: row.reportType,
      client_report_id: row.clientReportId,
      store_code: this.config.erpStoreCode || undefined,
      terminal_code: this.config.erpTerminalId || undefined,
      snapshot: row.snapshot,
    };

    row.attempts += 1;
    row.lastAttemptAt = new Date();

    try {
      const result = await this.erpClient.postReport(payload);
      if (result.ok) {
        row.status = ErpOrderPushStatus.SENT;
        row.sentAt = new Date();
        row.lastError = null;
        await this.pushRepository.save(row);
        this.logger.log(`Report ${row.reportType}/${row.clientReportId} pushed to ERP.`);
        return;
      }

      row.status = ErpOrderPushStatus.FAILED;
      row.lastError = (result.message ?? 'Unknown error').slice(0, 2000);
      if (result.permanent) row.attempts = ErpReportPushService.MAX_ATTEMPTS;
      await this.pushRepository.save(row);
    } catch (err) {
      row.status = ErpOrderPushStatus.FAILED;
      row.lastError = ((err as Error).message || 'Unknown error').slice(0, 2000);
      await this.pushRepository.save(row);
      throw err;
    }
  }

  async queueStatus() {
    const [pending, failed, sent] = await Promise.all([
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.PENDING } }),
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.FAILED } }),
      this.pushRepository.count({ where: { status: ErpOrderPushStatus.SENT } }),
    ]);
    return { pending, failed, sent };
  }
}
