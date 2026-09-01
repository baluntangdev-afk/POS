import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/daos/sales_dao.dart';
import '../providers/database_provider.dart';
import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import 'report_csv_builder.dart';

final reportCsvExporterProvider = Provider<ReportCsvExporter>((ref) {
  return ReportCsvExporter(ref.watch(databaseProvider).salesDao);
});

class ReportCsvExporter {
  ReportCsvExporter(this._salesDao);

  final SalesDao _salesDao;

  Future<String> exportXReading(XReadingData data, {int? cashierId}) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
      cashierId: cashierId,
    );
    final saleIds = txns.map((t) => t.id).toList();
    final items = await _salesDao.getSaleItemsForExport(saleIds);
    final csv = ReportCsvBuilder.buildXReading(data, txns, items);
    final filename = _filename('xreading', data.generatedAt, _cashierSlug(data.cashierName));
    return _saveAsCsv(csv, filename);
  }

  Future<String> exportZReading(ZReadingData data) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
    );
    final saleIds = txns.map((t) => t.id).toList();
    final items = await _salesDao.getSaleItemsForExport(saleIds);
    final csv = ReportCsvBuilder.buildZReading(data, txns, items);
    final filename = _filename('zreading', data.generatedAt, 'store');
    return _saveAsCsv(csv, filename);
  }

  Future<String> exportDailyReport(DailyReportData data, {int? cashierId}) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
      cashierId: cashierId,
    );
    final saleIds = txns.map((t) => t.id).toList();
    final items = await _salesDao.getSaleItemsForExport(saleIds);
    final csv = ReportCsvBuilder.buildDailyReport(data, txns, items);
    final filename =
        _filename('dailyreport', data.generatedAt, _cashierSlug(data.cashierName));
    return _saveAsCsv(csv, filename);
  }

  Future<String> _buildTransactionsCsv(DateTime from, DateTime to) async {
    final txns = await _salesDao.getTransactionsForExport(from: from, to: to);
    final saleIds = txns.map((t) => t.id).toList();
    final items = await _salesDao.getSaleItemsForExport(saleIds);
    return ReportCsvBuilder.buildTransactions(
      from: from,
      to: to,
      generatedAt: DateTime.now(),
      txns: txns,
      items: items,
    );
  }

  /// Saves an all-cashier transactions CSV for [from]..[to] to Downloads.
  /// Returns the saved filename.
  Future<String> exportTransactions({
    required DateTime from,
    required DateTime to,
  }) async {
    final csv = await _buildTransactionsCsv(from, to);
    return _saveAsCsv(csv, _transactionsFilename(from, to));
  }

  /// Writes the same CSV to a temp file (for emailing as an attachment).
  /// Returns the temp [File].
  Future<File> writeTransactionsTempFile({
    required DateTime from,
    required DateTime to,
  }) async {
    final csv = await _buildTransactionsCsv(from, to);
    return _writeTempCsv(csv, _transactionsFilename(from, to));
  }

  Future<File> _writeTempCsv(String csvString, String filename) async {
    final bytes = utf8.encode(csvString);
    final tmp = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmp.path, filename));
    await tmpFile.writeAsBytes(bytes, flush: true);
    return tmpFile;
  }

  Future<String> _saveAsCsv(String csvString, String filename) async {
    final tmpFile = await _writeTempCsv(csvString, filename);

    final mediaStore = MediaStore();
    await mediaStore.saveFile(
      tempFilePath: tmpFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    return filename;
  }

  static String _filename(String type, DateTime at, String slug) {
    final local = at.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}${local.minute.toString().padLeft(2, '0')}';
    return '${type}_${date}_${time}_$slug.csv';
  }

  static String _transactionsFilename(DateTime from, DateTime to) {
    String d(DateTime x) {
      final l = x.toLocal();
      return '${l.year.toString().padLeft(4, '0')}'
          '${l.month.toString().padLeft(2, '0')}'
          '${l.day.toString().padLeft(2, '0')}';
    }

    return 'transactions_${d(from)}_${d(to)}.csv';
  }

  static String _cashierSlug(String name) =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
