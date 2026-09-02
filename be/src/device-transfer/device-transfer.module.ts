import { Module } from '@nestjs/common';
import { ConfigModule } from '../config/config.module';
import { DeviceTransferController } from './device-transfer.controller';
import { ArchiveCryptoService } from './services/archive-crypto.service';
import { DbSnapshotService } from './services/db-snapshot.service';
import { DeviceExportService } from './services/device-export.service';
import { DeviceImportService } from './services/device-import.service';

/**
 * Full-device export / import (kiosk migration).
 *
 * `POST /api/v1/device-transfer/export` streams an encrypted archive of the
 * whole `public` schema; `POST /api/v1/device-transfer/import` restores one,
 * replacing all existing data. Both are admin/supervisor only.
 *
 * Relies on the app-wide TypeORM `DataSource` (registered by `DatabaseModule`)
 * and the global JWT guard for authentication.
 */
@Module({
  imports: [ConfigModule],
  controllers: [DeviceTransferController],
  providers: [ArchiveCryptoService, DbSnapshotService, DeviceExportService, DeviceImportService],
})
export class DeviceTransferModule {}
