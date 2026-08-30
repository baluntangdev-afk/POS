import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/csv_encrypter.dart';
import '../crypto/csv_encryption_key_store.dart';
import '../database/daos/sales_dao.dart';
import '../providers/database_provider.dart';
import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import 'report_csv_builder.dart';

final reportCsvExporterProvider = Provider<ReportCsvExporter>((ref) {
  return ReportCsvExporter(
    ref.watch(databaseProvider).salesDao,
    ref.watch(csvEncryptionKeyStoreProvider),
  );
});

class ReportCsvExporter {
  ReportCsvExporter(this._salesDao, this._keyStore);

  final SalesDao _salesDao;
  final CsvEncryptionKeyStore _keyStore;

  Future<String> exportXReading(XReadingData data, {int? cashierId}) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
      cashierId: cashierId,
    );
    final csv = ReportCsvBuilder.buildXReading(data, txns);
    final filename = _filename('xreading', data.generatedAt, _cashierSlug(data.cashierName));
    return _encryptAndSave(csv, filename);
  }

  Future<String> exportZReading(ZReadingData data) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
    );
    final csv = ReportCsvBuilder.buildZReading(data, txns);
    final filename = _filename('zreading', data.generatedAt, 'store');
    return _encryptAndSave(csv, filename);
  }

  Future<String> exportDailyReport(DailyReportData data, {int? cashierId}) async {
    final txns = await _salesDao.getTransactionsForExport(
      from: data.periodStart!,
      to: data.periodEnd,
      cashierId: cashierId,
    );
    final csv = ReportCsvBuilder.buildDailyReport(data, txns);
    final filename =
        _filename('dailyreport', data.generatedAt, _cashierSlug(data.cashierName));
    return _encryptAndSave(csv, filename);
  }

  Future<String> _encryptAndSave(String csvString, String filename) async {
    final hexKey = await _keyStore.getOrCreate();
    final encrypter = CsvEncrypter(hexKey);
    final bytes = await encrypter.encrypt(csvString);

    final tmp = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmp.path, filename));
    await tmpFile.writeAsBytes(bytes, flush: true);

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
    return '${type}_${date}_${time}_$slug.enc';
  }

  static String _cashierSlug(String name) =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
