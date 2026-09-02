import 'package:dart_mappable/dart_mappable.dart';

part 'device_transfer_dto.mapper.dart';

/// Metadata block from a `.posbackup` archive, echoed back by the import
/// endpoint. Parallels the backend `DeviceBackupManifestDto`.
@MappableClass()
class DeviceBackupManifestDto with DeviceBackupManifestDtoMappable {
  const DeviceBackupManifestDto({
    required this.formatVersion,
    required this.createdAt,
    required this.backendPackageVersion,
    required this.database,
    required this.migrations,
    required this.tableRowCounts,
    this.sourceKioskNo,
  });

  final int formatVersion;
  final String createdAt;
  final String backendPackageVersion;
  final String database;
  final String? sourceKioskNo;
  final List<String> migrations;
  final Map<String, int> tableRowCounts;

  int get totalRows => tableRowCounts.values.fold(0, (sum, n) => sum + n);

  static const fromJson = DeviceBackupManifestDtoMapper.fromJson;
}

/// A backup table that a partial restore did not import. Parallels the backend
/// `SkippedTableDto`.
@MappableClass()
class SkippedTableDto with SkippedTableDtoMappable {
  const SkippedTableDto({required this.name, required this.reason});

  final String name;
  final String reason;
}

/// A backup column that a partial restore did not import. Parallels the backend
/// `SkippedColumnDto`.
@MappableClass()
class SkippedColumnDto with SkippedColumnDtoMappable {
  const SkippedColumnDto({
    required this.table,
    required this.column,
    required this.reason,
  });

  final String table;
  final String column;
  final String reason;
}

/// What a partial restore left behind. Empty for a normal (strict) import.
/// Parallels the backend `ImportSkippedDto`.
@MappableClass()
class ImportSkippedDto with ImportSkippedDtoMappable {
  const ImportSkippedDto({this.tables = const [], this.columns = const []});

  final List<SkippedTableDto> tables;
  final List<SkippedColumnDto> columns;

  bool get isEmpty => tables.isEmpty && columns.isEmpty;
  bool get isNotEmpty => !isEmpty;

  static const fromJson = ImportSkippedDtoMapper.fromJson;
}

/// Result of a successful `POST /device-transfer/import`. Parallels the backend
/// `DeviceImportSummaryDto`.
@MappableClass()
class DeviceImportSummaryDto with DeviceImportSummaryDtoMappable {
  const DeviceImportSummaryDto({
    required this.restartRecommended,
    required this.manifest,
    required this.rowsRestored,
    required this.warnings,
    this.skipped = const ImportSkippedDto(),
  });

  final bool restartRecommended;
  final DeviceBackupManifestDto manifest;
  final Map<String, int> rowsRestored;
  final List<String> warnings;
  final ImportSkippedDto skipped;

  int get totalRowsRestored =>
      rowsRestored.values.fold(0, (sum, n) => sum + n);

  static const fromJson = DeviceImportSummaryDtoMapper.fromJson;
}
