import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/report_export_service.dart';
import 'package:mobile/features/reports/entities/report_data.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getTemporaryPath() async => tempDir;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_export_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('exportToCsv writes a CSV file with summary, payment breakdown, and top products sections', () async {
    final report = ReportData(
      totalSales: 250.0,
      transactionCount: 2,
      averageOrder: 125.0,
      paymentBreakdown: const [
        PaymentBreakdown(method: 'cash', total: 100, percentage: 40),
        PaymentBreakdown(method: 'card', total: 150, percentage: 60),
      ],
      topProducts: const [
        TopProductData(name: 'Latte', quantity: 1, total: 100),
        TopProductData(name: 'Burger', quantity: 1, total: 150),
      ],
      recentSales: const [],
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 1, 2),
    );

    final path = await ReportExportService.exportToCsv(report);

    expect(await File(path).exists(), isTrue);
    expect(path, endsWith('.csv'));

    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    final flat = rows.map((r) => r.join('|')).toList();

    expect(flat.any((r) => r.contains('Total Sales') && r.contains('250')), isTrue);
    expect(flat.any((r) => r.contains('Transaction Count') && r.contains('2')), isTrue);
    expect(flat.any((r) => r.contains('Payment Breakdown')), isTrue);
    expect(flat.any((r) => r.contains('Cash') && r.contains('100')), isTrue);
    expect(flat.any((r) => r.contains('Card') && r.contains('150')), isTrue);
    expect(flat.any((r) => r.contains('Top Products')), isTrue);
    expect(flat.any((r) => r.contains('Latte') && r.contains('100')), isTrue);
    expect(flat.any((r) => r.contains('Burger') && r.contains('150')), isTrue);
  });
}
