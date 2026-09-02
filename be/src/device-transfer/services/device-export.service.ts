import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ArchiveCryptoService } from './archive-crypto.service';
import { DbSnapshotService, TableSnapshot } from './db-snapshot.service';
import { ARCHIVE_FORMAT_VERSION } from '../device-transfer.constants';
import { DeviceBackupManifestDto } from '../dto/device-transfer-result.dto';

@Injectable()
export class DeviceExportService {
  private readonly logger = new Logger(DeviceExportService.name);

  constructor(
    private readonly snapshot: DbSnapshotService,
    private readonly crypto: ArchiveCryptoService,
    private readonly config: ConfigService,
  ) {}

  async export(passphrase: string): Promise<{ buffer: Buffer; manifest: DeviceBackupManifestDto }> {
    const tableNames = await this.snapshot.listTables();

    const tables: TableSnapshot[] = [];
    const tableRowCounts: Record<string, number> = {};
    for (const name of tableNames) {
      const snap = await this.snapshot.readTable(name);
      tables.push(snap);
      tableRowCounts[name] = snap.rows.length;
    }

    const manifest: DeviceBackupManifestDto = {
      formatVersion: ARCHIVE_FORMAT_VERSION,
      createdAt: new Date().toISOString(),
      backendPackageVersion: this.packageVersion(),
      database: this.config.get<string>('POSTGRES_DB', 'pos_db'),
      sourceKioskNo: this.config.get<string>('KIOSK_NO') ?? null,
      migrations: await this.snapshot.getMigrations(),
      tableRowCounts,
    };

    const payload = Buffer.from(JSON.stringify({ manifest, tables }));
    const buffer = await this.crypto.encrypt(payload, passphrase);

    const totalRows = Object.values(tableRowCounts).reduce((a, b) => a + b, 0);
    this.logger.log(
      `Exported ${tableNames.length} tables / ${totalRows} rows -> ${buffer.length} encrypted bytes`,
    );
    return { buffer, manifest };
  }

  private packageVersion(): string {
    try {
      const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf8')) as {
        version?: string;
      };
      return pkg.version ?? 'unknown';
    } catch {
      return 'unknown';
    }
  }
}
