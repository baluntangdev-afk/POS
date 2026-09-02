import { ApiProperty } from '@nestjs/swagger';

export class DeviceBackupManifestDto {
  @ApiProperty({ example: 1 })
  formatVersion: number;

  @ApiProperty({ example: '2026-09-02T12:00:00.000Z' })
  createdAt: string;

  @ApiProperty({ example: '0.0.1' })
  backendPackageVersion: string;

  @ApiProperty({ example: 'pos_db' })
  database: string;

  @ApiProperty({ nullable: true, example: '1' })
  sourceKioskNo: string | null;

  @ApiProperty({ type: [String] })
  migrations: string[];

  @ApiProperty({
    type: 'object',
    additionalProperties: { type: 'number' },
    example: { users: 4, sales_orders: 120 },
  })
  tableRowCounts: Record<string, number>;
}

export class SkippedTableDto {
  @ApiProperty({ example: 'loyalty_accounts' })
  name: string;

  @ApiProperty({ example: 'not present on this device' })
  reason: string;
}

export class SkippedColumnDto {
  @ApiProperty({ example: 'products' })
  table: string;

  @ApiProperty({ example: 'image_url' })
  column: string;

  @ApiProperty({ example: 'type changed (bytea → text)' })
  reason: string;
}

export class ImportSkippedDto {
  @ApiProperty({ type: [SkippedTableDto] })
  tables: SkippedTableDto[];

  @ApiProperty({ type: [SkippedColumnDto] })
  columns: SkippedColumnDto[];
}

export class DeviceImportSummaryDto {
  @ApiProperty({
    description: 'True when the backend process should be restarted to drop cached state',
  })
  restartRecommended: boolean;

  @ApiProperty({ type: DeviceBackupManifestDto })
  manifest: DeviceBackupManifestDto;

  @ApiProperty({
    type: 'object',
    additionalProperties: { type: 'number' },
    description: 'Rows restored per table',
  })
  rowsRestored: Record<string, number>;

  @ApiProperty({ type: [String] })
  warnings: string[];

  @ApiProperty({
    type: ImportSkippedDto,
    description:
      'Tables and columns from the backup that were not imported. Always empty unless the ' +
      'import ran in partial-restore mode.',
  })
  skipped: ImportSkippedDto;
}
