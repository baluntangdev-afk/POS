import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/reports/entities/report_data.dart';

abstract final class ReportExportService {
  static Future<String> exportToCsv(ReportData report) async {
    final rows = <List<Object?>>[
      ['Sales Report'],
      ['From', report.from.toIso8601String()],
      ['To', report.to.toIso8601String()],
      ['Total Sales', report.totalSales],
      ['Transaction Count', report.transactionCount],
      ['Average Order', report.averageOrder],
      [],
      ['Payment Breakdown'],
      ['Method', 'Total', 'Percentage'],
      for (final p in report.paymentBreakdown) [p.displayName, p.total, p.percentage],
      [],
      ['Top Products'],
      ['Name', 'Quantity', 'Total'],
      for (final p in report.topProducts) [p.name, p.quantity, p.total],
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final dateLabel = report.from.toIso8601String().split('T').first;
    final path = '${dir.path}/sales_report_$dateLabel.csv';
    await File(path).writeAsString(csv);

    return path;
  }

  static Future<void> shareCsv(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'Sales report');
  }
}
