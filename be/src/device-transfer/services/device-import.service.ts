import { Injectable, Logger, BadRequestException, ConflictException } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryRunner } from 'typeorm';
import { ArchiveCryptoService } from './archive-crypto.service';
import { DbSnapshotService, TableSnapshot } from './db-snapshot.service';
import { ARCHIVE_FORMAT_VERSION } from '../device-transfer.constants';
import { DeviceBackupManifestDto, DeviceImportSummaryDto } from '../dto/device-transfer-result.dto';

interface ArchivePayload {
  manifest: DeviceBackupManifestDto;
  tables: TableSnapshot[];
}

@Injectable()
export class DeviceImportService {
  private readonly logger = new Logger(DeviceImportService.name);

  constructor(
    @InjectDataSource() private readonly ds: DataSource,
    private readonly snapshot: DbSnapshotService,
    private readonly crypto: ArchiveCryptoService,
  ) {}

  async import(
    file: Buffer,
    passphrase: string,
    partial = false,
  ): Promise<DeviceImportSummaryDto> {
    const payload = await this.parse(file, passphrase);
    await this.assertCompatible(payload.manifest, partial);

    const warnings = await this.collectWarnings(payload.tables);

    const qr = this.ds.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();

    let result: Awaited<ReturnType<typeof this.snapshot.restore>>;
    try {
      result = await this.snapshot.restore({ tables: payload.tables }, qr, { partial });
      if (partial) {
        const stamped = await this.backfillSaleStoreIds(payload.tables, qr);
        if (stamped > 0) {
          warnings.push(
            `${stamped} restored sale${stamped === 1 ? '' : 's'} had no merchant and ` +
              "were assigned to this device's Kiosk ID so they sync.",
          );
        }
      }
      await qr.commitTransaction();
    } catch (err) {
      await qr.rollbackTransaction();
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`Import rolled back: ${message}`);
      throw new BadRequestException(`Import failed and no data was changed: ${message}`);
    } finally {
      await qr.release();
    }

    const total = Object.values(result.counts).reduce((a, b) => a + b, 0);
    this.logger.warn(
      `Device data replaced from backup (${payload.manifest.createdAt}) — ${total} rows restored` +
        (partial ? ' (partial restore)' : ''),
    );

    return {
      restartRecommended: true,
      manifest: payload.manifest,
      rowsRestored: result.counts,
      warnings,
      skipped: result.skipped,
    };
  }

  private async parse(file: Buffer, passphrase: string): Promise<ArchivePayload> {
    const json = await this.crypto.decrypt(file, passphrase);

    let payload: ArchivePayload;
    try {
      payload = JSON.parse(json.toString()) as ArchivePayload;
    } catch {
      throw new BadRequestException('The backup archive is unreadable.');
    }

    if (
      !payload ||
      typeof payload !== 'object' ||
      !payload.manifest ||
      !Array.isArray(payload.tables)
    ) {
      throw new BadRequestException('The backup archive is missing required sections.');
    }
    return payload;
  }

  private async assertCompatible(
    manifest: DeviceBackupManifestDto,
    partial: boolean,
  ): Promise<void> {
    if (manifest.formatVersion !== ARCHIVE_FORMAT_VERSION) {
      throw new ConflictException(
        `This backup uses archive format v${manifest.formatVersion}; this device supports v${ARCHIVE_FORMAT_VERSION}. Update both devices to the same app version.`,
      );
    }

    // Partial restore deliberately tolerates a differing schema — it imports
    // only what lines up — so the migration-history gate is skipped.
    if (partial) return;

    const current = await this.snapshot.getMigrations();
    const incoming = Array.isArray(manifest.migrations) ? manifest.migrations : [];
    if (current.join('|') !== incoming.join('|')) {
      throw new ConflictException(
        'This backup was made on an incompatible app version (database migration history differs). ' +
          'Update both devices to the same version, or retry as a partial restore.',
      );
    }
  }

  /**
   * A partial restore keeps this device's own migration history, so the
   * `store_id` backfill in `TransactionSyncState1785200000000` never runs over
   * sales from a pre-sync backup. Left NULL they are invisible to transaction
   * sync, so stamp them the same way that migration does: with the (single)
   * terminal's Kiosk ID. Returns the number of sales stamped.
   */
  private async backfillSaleStoreIds(tables: TableSnapshot[], qr: QueryRunner): Promise<number> {
    const archived = tables.find((t) => t.name === 'sales_orders');
    if (!archived || archived.columns.some((c) => c.name === 'store_id')) return 0;

    const [{ exists }] = (await qr.query(
      `SELECT EXISTS (
         SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'sales_orders' AND column_name = 'store_id'
       ) AS "exists"`,
    )) as { exists: boolean }[];
    if (!exists) return 0;

    const [, affected] = (await qr.query(
      `UPDATE "sales_orders"
          SET "store_id" = (SELECT "kiosk_id" FROM "pos_terminals" ORDER BY "id" ASC LIMIT 1)
        WHERE "store_id" IS NULL
          AND EXISTS (SELECT 1 FROM "pos_terminals")`,
    )) as [unknown, number];
    return affected ?? 0;
  }

  /** Warn about target tables the archive did not carry — they end up empty. */
  private async collectWarnings(tables: TableSnapshot[]): Promise<string[]> {
    const archived = new Set(tables.map((t) => t.name));
    const warnings: string[] = [];
    for (const name of await this.snapshot.listTables()) {
      if (!archived.has(name)) {
        warnings.push(`Table "${name}" was not present in the backup and is now empty.`);
      }
    }
    return warnings;
  }
}
