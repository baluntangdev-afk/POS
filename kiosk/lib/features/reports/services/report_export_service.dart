// kiosk/lib/features/reports/services/report_export_service.dart
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../entities/exportable_report.dart';
import '../entities/sales_data_item.dart';
import '../entities/sales_report_type.dart';
import '../entities/sales_summary.dart';
import '../repositories/reports_repository.dart';

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService(repository: ref.watch(reportsRepositoryProvider));
});

class ReportExportService {
  const ReportExportService({required ReportsRepository repository})
      : _repository = repository;

  final ReportsRepository _repository;

  Future<String> exportDay(DateTime date) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final data = await _repository.getExportable(
      startDate: startDate,
      endDate: endDate,
    );

    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(excel, data, date);
    _buildHourlySheet(excel, data.hourlyBreakdown);
    _buildGroupedSheet(excel, 'By Product', 'Product', data.byProduct);
    _buildGroupedSheet(excel, 'By Product Group', 'Product Group', data.byProductGroup);
    _buildGroupedSheet(excel, 'By Payment Method', 'Payment Method', data.byPayment);
    _buildGroupedSheet(excel, 'By Cashier', 'Cashier', data.byCashier);

    final dateStr = _formatDate(date);
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final downloadsPath = '$userProfile\\Downloads';
    final savePath = Directory(downloadsPath).existsSync() ? downloadsPath : '.';
    final filePath = '$savePath\\sales_report_$dateStr.xlsx';

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode XLSX');
    await File(filePath).writeAsBytes(bytes);

    await _repository.markExported(date);

    return filePath;
  }

  void _buildSummarySheet(Excel excel, ExportableReport data, DateTime date) {
    final sheet = excel['Summary'];
    final money = NumberFormat('#,##0.00');
    final s = data.summary;
    final netSales = s.totalSales - s.totalDiscount - s.totalRefunds;

    final rows = [
      ['Report Date', DateFormat('MMM d, yyyy').format(date)],
      ['Generated At', DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())],
      ['', ''],
      ['Gross Sales', 'P${money.format(s.totalSales)}'],
      ['Total Discounts', 'P${money.format(s.totalDiscount)}'],
      ['Net Sales', 'P${money.format(netSales)}'],
      ['Total Refunds', 'P${money.format(s.totalRefunds)}'],
      ['Voided Transactions', s.totalVoidedTransactions.toString()],
      ['Voided Amount', 'P${money.format(s.totalVoidedAmount)}'],
      ['Total Transactions', s.totalTransactions.toString()],
      ['Total Items Sold', s.totalItems.toString()],
    ];

    for (final row in rows) {
      sheet.appendRow([TextCellValue(row[0]), TextCellValue(row[1])]);
    }

    sheet.setColWidth(0, 24);
    sheet.setColWidth(1, 20);
  }

  void _buildHourlySheet(Excel excel, List<SalesReportType> rows) {
    final sheet = excel['Hourly Breakdown'];
    final money = NumberFormat('#,##0.00');
    const headers = ['Hour', 'Gross Sales', 'Discounts', 'Transactions', 'Items'];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _styleHeaderRow(sheet, 0, headers.length);

    double totalSales = 0, totalDiscount = 0;
    int totalTx = 0, totalItems = 0;

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.hour),
        TextCellValue('P${money.format(row.total)}'),
        TextCellValue('P${money.format(row.discount)}'),
        IntCellValue(row.transactions),
        IntCellValue(row.items),
      ]);
      totalSales += row.total;
      totalDiscount += row.discount;
      totalTx += row.transactions;
      totalItems += row.items;
    }

    final totalRow = rows.length + 1;
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue('P${money.format(totalSales)}'),
      TextCellValue('P${money.format(totalDiscount)}'),
      IntCellValue(totalTx),
      IntCellValue(totalItems),
    ]);
    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRow))
          .cellStyle = CellStyle(bold: true);
    }

    sheet.setColWidth(0, 12);
    sheet.setColWidth(1, 16);
    sheet.setColWidth(2, 16);
    sheet.setColWidth(3, 14);
    sheet.setColWidth(4, 12);
  }

  void _buildGroupedSheet(
    Excel excel,
    String sheetName,
    String labelHeader,
    List<SalesDataItem> items,
  ) {
    final sheet = excel[sheetName];
    final money = NumberFormat('#,##0.00');
    final headers = [labelHeader, 'Total Sales', '% Share'];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    _styleHeaderRow(sheet, 0, headers.length);

    final total = items.fold<double>(0.0, (sum, i) => sum + i.totalSales);

    for (final item in items) {
      final pct = total > 0 ? item.totalSales / total * 100 : 0.0;
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue('P${money.format(item.totalSales)}'),
        TextCellValue('${pct.toStringAsFixed(1)}%'),
      ]);
    }

    sheet.setColWidth(0, 28);
    sheet.setColWidth(1, 16);
    sheet.setColWidth(2, 10);
  }

  void _styleHeaderRow(Sheet sheet, int rowIndex, int colCount) {
    for (int col = 0; col < colCount; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B7A8C'),
        fontColorHex: ExcelColor.white,
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
