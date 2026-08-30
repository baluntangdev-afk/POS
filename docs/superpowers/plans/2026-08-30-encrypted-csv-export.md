# Encrypted CSV Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add AES-256-CBC encrypted CSV export to X-Reading, Z-Reading, and Daily Report screens, with a key-management tile in Settings.

**Architecture:** `CsvEncryptionKeyStore` manages a per-device 32-byte key in `FlutterSecureStorage`. `ReportCsvBuilder` (pure) builds the CSV string from typed report data + fetched transactions. `CsvEncrypter` encrypts the string. `ReportCsvExporter` orchestrates the pipeline and saves via `MediaStore` (existing Downloads pattern). `ExportCsvButton` is a reusable `HookConsumerWidget` that calls the exporter and shows loading/result feedback.

**Tech Stack:** `encrypt ^5.0.3` (AES-256-CBC), `media_store_plus` (Downloads write), `flutter_secure_storage`, `drift` (new DAO query), `hooks_riverpod`

---

## File Map

| Action | Path |
|---|---|
| Create | `mobile/lib/core/crypto/csv_encryption_key_store.dart` |
| Create | `mobile/lib/core/crypto/csv_encrypter.dart` |
| Create | `mobile/lib/core/csv/transaction_export_row.dart` |
| Create | `mobile/lib/core/csv/report_csv_builder.dart` |
| Create | `mobile/lib/core/csv/report_csv_exporter.dart` |
| Create | `mobile/lib/features/cashier_accounting/shared/export_csv_button.dart` |
| Create | `mobile/lib/features/settings/view/csv_export_key_screen.dart` |
| Create | `mobile/test/core/csv/report_csv_builder_test.dart` |
| Create | `mobile/test/core/crypto/csv_encrypter_test.dart` |
| Create | `mobile/test/core/crypto/csv_encryption_key_store_test.dart` |
| Modify | `mobile/pubspec.yaml` — add `encrypt: ^5.0.3` |
| Modify | `mobile/lib/core/database/daos/sales_dao.dart` — add `getTransactionsForExport` |
| Modify | `mobile/lib/features/cashier_accounting/x_reading/view/x_reading_screen.dart` |
| Modify | `mobile/lib/features/cashier_accounting/x_reading/view/x_reading_history_screen.dart` |
| Modify | `mobile/lib/features/cashier_accounting/z_reading/view/z_reading_screen.dart` |
| Modify | `mobile/lib/features/cashier_accounting/z_reading/view/z_reading_history_screen.dart` |
| Modify | `mobile/lib/features/cashier_accounting/daily_report/view/daily_report_screen.dart` |
| Modify | `mobile/lib/features/cashier_accounting/daily_report/view/daily_report_history_screen.dart` |
| Modify | `mobile/lib/features/settings/view/settings_screen.dart` |
| Modify | `mobile/lib/core/navigation/router.dart` |

---

## Task 1: Add `encrypt` package

**Files:**
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1: Add dependency**

In `mobile/pubspec.yaml`, under `# Auth / Security`, add:
```yaml
  encrypt: ^5.0.3
```

- [ ] **Step 2: Install**

```bash
cd mobile && flutter pub get
```

Expected: resolves without conflicts (PointyCastle is a transitive dep already used).

---

## Task 2: CsvEncryptionKeyStore

**Files:**
- Create: `mobile/lib/core/crypto/csv_encryption_key_store.dart`
- Create: `mobile/test/core/crypto/csv_encryption_key_store_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// mobile/test/core/crypto/csv_encryption_key_store_test.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/csv_encryption_key_store.dart';

void main() {
  test('generates a 32-byte hex key on first call', () async {
    final storage = _FakeStorage();
    final store = CsvEncryptionKeyStore(storage);
    final key = await store.getOrCreate();
    expect(key.length, 64); // 32 bytes → 64 hex chars
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
  });

  test('returns the same key on subsequent calls', () async {
    final storage = _FakeStorage();
    final store = CsvEncryptionKeyStore(storage);
    final first = await store.getOrCreate();
    final second = await store.getOrCreate();
    expect(first, equals(second));
  });

  test('regenerate() replaces the stored key', () async {
    final storage = _FakeStorage();
    final store = CsvEncryptionKeyStore(storage);
    final old = await store.getOrCreate();
    final fresh = await store.regenerate();
    final after = await store.getOrCreate();
    expect(fresh, equals(after));
    expect(fresh, isNot(equals(old)));
  });
}

class _FakeStorage implements FlutterSecureStorage {
  final _map = <String, String>{};

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _map[key];

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _map.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
cd mobile && flutter test test/core/crypto/csv_encryption_key_store_test.dart
```

Expected: compile error (class doesn't exist yet).

- [ ] **Step 3: Implement**

```dart
// mobile/lib/core/crypto/csv_encryption_key_store.dart
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/secure_storage/secure_storage.dart';

final csvEncryptionKeyStoreProvider = Provider<CsvEncryptionKeyStore>((ref) {
  return CsvEncryptionKeyStore(ref.watch(secureStorageProvider));
});

class CsvEncryptionKeyStore {
  CsvEncryptionKeyStore(this._storage);

  static const _storageKey = 'csv_export_aes_key';
  final FlutterSecureStorage _storage;

  Future<String> getOrCreate() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null) return stored;
    return _generate();
  }

  Future<String> regenerate() async {
    final key = _generate();
    await _storage.write(key: _storageKey, value: await key);
    return key;
  }

  String _hexKey(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Future<String> _generate() async {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    final hex = _hexKey(bytes);
    await _storage.write(key: _storageKey, value: hex);
    return hex;
  }
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
cd mobile && flutter test test/core/crypto/csv_encryption_key_store_test.dart
```

Expected: All 3 tests pass.

---

## Task 3: CsvEncrypter

**Files:**
- Create: `mobile/lib/core/crypto/csv_encrypter.dart`
- Create: `mobile/test/core/crypto/csv_encrypter_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// mobile/test/core/crypto/csv_encrypter_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/csv_encrypter.dart';

void main() {
  final hexKey = '0' * 64; // 32 zero bytes
  final encrypter = CsvEncrypter(hexKey);

  test('encrypt returns [16-byte IV][cipher bytes]', () async {
    final result = await encrypter.encrypt('hello');
    expect(result.length, greaterThan(16));
  });

  test('round-trip: decrypt recovers original plaintext', () async {
    const plaintext = 'Field,Value\nReport Type,X-Reading\n';
    final blob = await encrypter.encrypt(plaintext);
    final iv = enc.IV(blob.sublist(0, 16));
    final cipherBytes = blob.sublist(16);
    final key = enc.Key.fromBase16(hexKey);
    final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = e.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    expect(utf8.decode(decrypted), equals(plaintext));
  });

  test('different calls produce different ciphertexts (fresh IV)', () async {
    final a = await encrypter.encrypt('same');
    final b = await encrypter.encrypt('same');
    expect(a, isNot(equals(b)));
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
cd mobile && flutter test test/core/crypto/csv_encrypter_test.dart
```

- [ ] **Step 3: Implement**

```dart
// mobile/lib/core/crypto/csv_encrypter.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

class CsvEncrypter {
  CsvEncrypter(String hexKey) : _key = enc.Key.fromBase16(hexKey);

  final enc.Key _key;
  final _rng = Random.secure();

  Future<Uint8List> encrypt(String plaintext) async {
    final iv = enc.IV(Uint8List.fromList(List.generate(16, (_) => _rng.nextInt(256))));
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(utf8.encode(plaintext), iv: iv);
    return Uint8List(16 + encrypted.bytes.length)
      ..setAll(0, iv.bytes)
      ..setAll(16, encrypted.bytes);
  }
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
cd mobile && flutter test test/core/crypto/csv_encrypter_test.dart
```

---

## Task 4: TransactionExportRow + `getTransactionsForExport`

**Files:**
- Create: `mobile/lib/core/csv/transaction_export_row.dart`
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`

- [ ] **Step 1: Create data class**

```dart
// mobile/lib/core/csv/transaction_export_row.dart
class TransactionExportRow {
  final int id;
  final String? soNumber;
  final String cashierName;
  final DateTime createdAt;
  final double total;
  final double discount;
  final String status;
  final String type;
  final double refundedAmount;
  final String? voidReason;
  final List<String> paymentMethods;

  const TransactionExportRow({
    required this.id,
    this.soNumber,
    required this.cashierName,
    required this.createdAt,
    required this.total,
    required this.discount,
    required this.status,
    required this.type,
    required this.refundedAmount,
    this.voidReason,
    required this.paymentMethods,
  });

  String get invoiceNumber => soNumber ?? '#${id.toString().padLeft(6, '0')}';

  String get displayType => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };

  String get displayStatus => switch (status) {
        'completed' => 'Completed',
        'voided' => 'Voided',
        'refunded' => 'Refunded',
        _ => status,
      };

  double get netTotal => (total - discount - refundedAmount).clamp(0.0, double.infinity);
}
```

- [ ] **Step 2: Add DAO method to `sales_dao.dart`**

At the end of the `SalesDao` class body (before the closing `}`), add:

```dart
  Future<List<TransactionExportRow>> getTransactionsForExport({
    required DateTime from,
    required DateTime to,
    int? cashierId,
  }) async {
    final q = select(salesTable).join([
      leftOuterJoin(usersTable, usersTable.id.equalsExp(salesTable.cashierId)),
    ]);
    q.where(salesTable.createdAt.isBetweenValues(from, to));
    if (cashierId != null) q.where(salesTable.cashierId.equals(cashierId));
    q.orderBy([OrderingTerm.asc(salesTable.createdAt)]);

    final rows = await q.get();
    final saleIds = rows.map((r) => r.readTable(salesTable).id).toList();

    final refundedByIds = await _refundedAmountsBySaleIds(saleIds);

    final paymentsByIds = <int, List<String>>{};
    if (saleIds.isNotEmpty) {
      final payments = await (select(paymentsTable)
            ..where((t) => t.saleId.isIn(saleIds)))
          .get();
      for (final p in payments) {
        paymentsByIds.putIfAbsent(p.saleId, () => []).add(p.method);
      }
    }

    return rows.map((row) {
      final sale = row.readTable(salesTable);
      final user = row.readTableOrNull(usersTable);
      return TransactionExportRow(
        id: sale.id,
        soNumber: sale.soNumber,
        cashierName: user?.name ?? 'Unknown',
        createdAt: sale.createdAt,
        total: sale.total,
        discount: sale.discount,
        status: sale.status,
        type: sale.type,
        refundedAmount: refundedByIds[sale.id] ?? 0,
        voidReason: sale.voidReason,
        paymentMethods: paymentsByIds[sale.id] ?? [],
      );
    }).toList();
  }
```

Also add this import at the top of `sales_dao.dart`:
```dart
import '../../../core/csv/transaction_export_row.dart';
```

---

## Task 5: ReportCsvBuilder

**Files:**
- Create: `mobile/lib/core/csv/report_csv_builder.dart`
- Create: `mobile/test/core/csv/report_csv_builder_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// mobile/test/core/csv/report_csv_builder_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/csv/report_csv_builder.dart';
import 'package:mobile/core/csv/transaction_export_row.dart';
import 'package:mobile/features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import 'package:mobile/features/reports/entities/report_data.dart';

void main() {
  final sampleTxns = [
    TransactionExportRow(
      id: 1,
      soNumber: 'SO-001-2026-0001',
      cashierName: 'John Doe',
      createdAt: DateTime(2026, 8, 29, 8, 5),
      total: 500.0,
      discount: 0.0,
      status: 'completed',
      type: 'dine_in',
      refundedAmount: 0.0,
      voidReason: null,
      paymentMethods: ['cash'],
    ),
    TransactionExportRow(
      id: 2,
      soNumber: null,
      cashierName: 'John Doe',
      createdAt: DateTime(2026, 8, 29, 9, 0),
      total: 200.0,
      discount: 50.0,
      status: 'voided',
      type: 'take_out',
      refundedAmount: 0.0,
      voidReason: 'Customer cancelled',
      paymentMethods: ['cash', 'card'],
    ),
  ];

  final sampleData = XReadingData(
    id: null,
    cashierName: 'John Doe',
    periodStart: DateTime(2026, 8, 29, 8, 0),
    periodEnd: DateTime(2026, 8, 29, 17, 30),
    generatedAt: DateTime(2026, 8, 29, 17, 35),
    totalSales: 700.0,
    transactionCount: 2,
    voidedCount: 1,
    refundedCount: 0,
    paymentBreakdown: [PaymentBreakdown(method: 'cash', total: 700.0, percentage: 100.0)],
    topProducts: [],
    paymentLedgers: [],
    discounts: [],
    totalDiscounts: 50.0,
    vatableSales: 625.0,
    vatAmount: 75.0,
    vatExemptSales: 0.0,
    averageSale: 350.0,
    highestSale: 500.0,
    lowestSale: 200.0,
    cashCollected: 700.0,
  );

  test('CSV has three sections separated by blank lines', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    final lines = csv.split('\n');
    final blankCount = lines.where((l) => l.trim().isEmpty).length;
    expect(blankCount, greaterThanOrEqualTo(2));
  });

  test('header section contains Report Type row', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Report Type,X-Reading'));
  });

  test('payment breakdown section contains method and amount', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Payment Method,Amount,Count'));
    expect(csv, contains('Cash,700.00,'));
  });

  test('transaction detail rows ordered by ascending date', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    final idx1 = csv.indexOf('SO-001-2026-0001');
    final idx2 = csv.indexOf('#000002');
    expect(idx1, lessThan(idx2));
  });

  test('invoice number falls back to padded id when soNumber is null', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('#000002'));
  });

  test('void reason appears in voided row', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Customer cancelled'));
  });

  test('payment methods are comma-joined within the cell', () {
    final csv = ReportCsvBuilder.buildXReading(sampleData, sampleTxns);
    expect(csv, contains('Cash, Card'));
  });
}
```

- [ ] **Step 2: Run test — expect failure**

```bash
cd mobile && flutter test test/core/csv/report_csv_builder_test.dart
```

- [ ] **Step 3: Implement**

```dart
// mobile/lib/core/csv/report_csv_builder.dart
import 'package:intl/intl.dart';

import '../database/daos/sales_dao.dart';
import '../../features/cashier_accounting/daily_report/entities/daily_report_data.dart';
import '../../features/cashier_accounting/x_reading/entities/x_reading_data.dart';
import '../../features/cashier_accounting/z_reading/entities/z_reading_data.dart';
import '../../features/reports/entities/report_data.dart';
import 'transaction_export_row.dart';

abstract final class ReportCsvBuilder {
  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _timeFmt = DateFormat('HH:mm');
  static final _moneyFmt = NumberFormat('0.00');

  static String buildXReading(XReadingData d, List<TransactionExportRow> txns) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'X-Reading',
      'Store Name': '',
      'Cashier': d.cashierName,
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.totalSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.transactionCount - d.voidedCount - d.refundedCount}',
      'Voided': '${d.voidedCount}',
      'Refunded': '${d.refundedCount}',
      'Total Discounts': _moneyFmt.format(d.totalDiscounts),
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashCollected),
    });
    buf.writeln();
    _writePaymentBreakdown(buf, d.paymentBreakdown);
    buf.writeln();
    _writeTransactions(buf, txns);
    return buf.toString();
  }

  static String buildZReading(ZReadingData d, List<TransactionExportRow> txns) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'Z-Reading',
      'Store Name': '',
      'Cashier': 'store',
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.totalSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.completedCount}',
      'Voided': '${d.voidedCount}',
      'Refunded': '${d.refundedCount}',
      'Total Discounts': _moneyFmt.format(d.discountTotal),
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashCollected),
    });
    // Z-Reading cashier breakdown sub-table
    buf.writeln();
    buf.writeln('Cashier Breakdown');
    buf.writeln('Cashier Name,Sales Total,Transaction Count');
    for (final c in d.salesByCashier) {
      buf.writeln('${_esc(c.cashierName)},${_moneyFmt.format(c.total)},${c.transactionCount}');
    }
    buf.writeln();
    _writePaymentBreakdown(buf, d.paymentBreakdown);
    buf.writeln();
    _writeTransactions(buf, txns);
    return buf.toString();
  }

  static String buildDailyReport(DailyReportData d, List<TransactionExportRow> txns) {
    final buf = StringBuffer();
    _writeHeader(buf, {
      'Report Type': 'Daily Report',
      'Store Name': '',
      'Cashier': d.cashierName,
      'Period Start': d.periodStart != null ? _fmtDateTime(d.periodStart!) : '',
      'Period End': _fmtDateTime(d.periodEnd),
      'Generated At': _fmtDateTime(d.generatedAt),
      'Total Sales': _moneyFmt.format(d.grossSales),
      'Total Transactions': '${d.transactionCount}',
      'Completed': '${d.transactionCount}',
      'Voided': '0',
      'Refunded': '0',
      'Total Discounts': '0.00',
      'Vatable Sales': _moneyFmt.format(d.vatableSales),
      'VAT Amount': _moneyFmt.format(d.vatAmount),
      'VAT Exempt Sales': _moneyFmt.format(d.vatExemptSales),
      'Cash Collected': _moneyFmt.format(d.cashSalesTotal),
    });
    buf.writeln();
    // Daily report has no payment breakdown in the data model; skip section 2
    buf.writeln('Payment Method,Amount,Count');
    buf.writeln();
    _writeTransactions(buf, txns);
    return buf.toString();
  }

  static void _writeHeader(StringBuffer buf, Map<String, String> fields) {
    buf.writeln('Field,Value');
    for (final entry in fields.entries) {
      buf.writeln('${_esc(entry.key)},${_esc(entry.value)}');
    }
  }

  static void _writePaymentBreakdown(StringBuffer buf, List<PaymentBreakdown> breakdown) {
    buf.writeln('Payment Method,Amount,Count');
    for (final p in breakdown) {
      buf.writeln('${_esc(p.displayName)},${_moneyFmt.format(p.total)},');
    }
  }

  static void _writeTransactions(StringBuffer buf, List<TransactionExportRow> txns) {
    buf.writeln('Invoice No,Date,Time,Cashier,Type,Status,Payment Method,Gross Total,Discount,Refunded,Net Total,Void Reason');
    final sorted = [...txns]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final t in sorted) {
      final local = t.createdAt.toLocal();
      final methods = t.paymentMethods
          .map((m) => _methodDisplay(m))
          .join(', ');
      buf.writeln([
        _esc(t.invoiceNumber),
        _dateFmt.format(local),
        _timeFmt.format(local),
        _esc(t.cashierName),
        _esc(t.displayType),
        _esc(t.displayStatus),
        _esc(methods),
        _moneyFmt.format(t.total),
        _moneyFmt.format(t.discount),
        _moneyFmt.format(t.refundedAmount),
        _moneyFmt.format(t.netTotal),
        _esc(t.voidReason ?? ''),
      ].join(','));
    }
  }

  static String _fmtDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_dateFmt.format(local)} ${_timeFmt.format(local)}';
  }

  static String _methodDisplay(String method) => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };

  // Wrap in quotes if value contains comma, quote, or newline
  static String _esc(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
cd mobile && flutter test test/core/csv/report_csv_builder_test.dart
```

---

## Task 6: ReportCsvExporter

**Files:**
- Create: `mobile/lib/core/csv/report_csv_exporter.dart`

No unit test (it's pure I/O; tested via manual/integration).

- [ ] **Step 1: Implement**

```dart
// mobile/lib/core/csv/report_csv_exporter.dart
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
  final db = ref.watch(databaseProvider);
  final keyStore = ref.watch(csvEncryptionKeyStoreProvider);
  return ReportCsvExporter(db.salesDao, keyStore);
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
    final slug = _cashierSlug(data.cashierName);
    final filename = _filename('xreading', data.generatedAt, slug);
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
    final slug = _cashierSlug(data.cashierName);
    final filename = _filename('dailyreport', data.generatedAt, slug);
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
    final time = '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}';
    return '${type}_${date}_${time}_$slug.enc';
  }

  static String _cashierSlug(String name) =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
}
```

---

## Task 7: ExportCsvButton widget

**Files:**
- Create: `mobile/lib/features/cashier_accounting/shared/export_csv_button.dart`

- [ ] **Step 1: Implement**

```dart
// mobile/lib/features/cashier_accounting/shared/export_csv_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/csv/report_csv_exporter.dart';

/// Reusable AppBar action that triggers an encrypted CSV export.
/// Hidden when [periodStart] is null (no transactions in period yet).
class ExportCsvButton extends HookConsumerWidget {
  const ExportCsvButton({
    super.key,
    required this.periodStart,
    required this.onExport,
  });

  final DateTime? periodStart;
  // Receives the exporter and returns the saved filename.
  final Future<String> Function(ReportCsvExporter exporter) onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (periodStart == null) return const SizedBox.shrink();

    final isExporting = useState(false);
    final exporter = ref.read(reportCsvExporterProvider);

    return IconButton(
      icon: isExporting.value
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      tooltip: 'Export CSV',
      onPressed: isExporting.value
          ? null
          : () async {
              isExporting.value = true;
              try {
                final filename = await onExport(exporter);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to Downloads/$filename')),
                  );
                }
              } on Exception {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export failed — check storage space')),
                  );
                }
              } finally {
                isExporting.value = false;
              }
            },
    );
  }
}
```

---

## Task 8: Wire ExportCsvButton into the 6 screens

For each screen, the pattern is: add `ExportCsvButton` to `AppBar.actions`, passing the relevant report data and cashier ID.

### 8a: X-Reading live screen (`x_reading_screen.dart`)

- [ ] Add import and button to AppBar actions in `XReadingScreen.build()`:

In the `actions:` list of the AppBar, add before the existing icons:
```dart
ExportCsvButton(
  periodStart: dataAsync.value?.periodStart,
  onExport: (exp) => exp.exportXReading(
    dataAsync.value!,
    cashierId: ref.read(authNotifierProvider).maybeWhen(
      authenticated: (u) => u.id,
      orElse: () => null,
    ),
  ),
),
```

Add imports:
```dart
import '../shared/export_csv_button.dart';
import '../../../../features/auth/state/auth_providers.dart';
import '../../../../features/auth/state/auth_state.dart';
```

### 8b: X-Reading history screen (`x_reading_history_screen.dart`)

- [ ] In `XReadingReprintScreen.build()`, the row data is already computed via `_toXReadingData`. Add to AppBar actions alongside the print button:

```dart
ExportCsvButton(
  periodStart: rowAsync.value?.periodStart,
  onExport: (exp) => exp.exportXReading(_toXReadingData(rowAsync.value!)),
),
```

Add import:
```dart
import '../shared/export_csv_button.dart';
```

### 8c: Z-Reading live screen (`z_reading_screen.dart`)

- [ ] Add to AppBar actions:

```dart
ExportCsvButton(
  periodStart: dataAsync.value?.periodStart,
  onExport: (exp) => exp.exportZReading(dataAsync.value!),
),
```

### 8d: Z-Reading history screen (`z_reading_history_screen.dart`)

- [ ] Add to AppBar actions:

```dart
ExportCsvButton(
  periodStart: rowAsync.value?.periodStart,
  onExport: (exp) => exp.exportZReading(_toZReadingData(rowAsync.value!)),
),
```

### 8e: Daily Report live screen (`daily_report_screen.dart`)

- [ ] Add to AppBar actions:

```dart
ExportCsvButton(
  periodStart: dataAsync.value?.periodStart,
  onExport: (exp) => exp.exportDailyReport(
    dataAsync.value!,
    cashierId: ref.read(authNotifierProvider).maybeWhen(
      authenticated: (u) => u.id,
      orElse: () => null,
    ),
  ),
),
```

### 8f: Daily Report history screen (`daily_report_history_screen.dart`)

- [ ] Add to AppBar actions:

```dart
ExportCsvButton(
  periodStart: rowAsync.value?.periodStart,
  onExport: (exp) => exp.exportDailyReport(_toDailyReportData(rowAsync.value!)),
),
```

---

## Task 9: CSV Export Key Settings UI

**Files:**
- Create: `mobile/lib/features/settings/view/csv_export_key_screen.dart`
- Modify: `mobile/lib/features/settings/view/settings_screen.dart`
- Modify: `mobile/lib/core/navigation/router.dart`

- [ ] **Step 1: Create the key management screen**

```dart
// mobile/lib/features/settings/view/csv_export_key_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/crypto/csv_encryption_key_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CsvExportKeyScreen extends HookConsumerWidget {
  const CsvExportKeyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyStore = ref.watch(csvEncryptionKeyStoreProvider);
    final keyAsync = useFuture(useMemoized(keyStore.getOrCreate));
    final isVisible = useState(false);

    Future<void> handleRegenerate() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Regenerate Export Key?'),
          content: const Text(
            'Existing .enc files cannot be decrypted with the new key. '
            'Make sure you have saved copies of any exports you need.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await keyStore.regenerate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New export key generated')),
        );
      }
    }

    final key = keyAsync.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CSV Export Key'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This key decrypts your exported .enc report files. '
              'Share it with whoever needs to open the exports (e.g., via CyberChef or Python).',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (key == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isVisible.value ? key : '•' * 32,
                        style: AppTextStyles.bodySmall.copyWith(fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(isVisible.value ? Icons.visibility_off : Icons.visibility),
                      tooltip: isVisible.value ? 'Hide key' : 'Show key',
                      onPressed: () => isVisible.value = !isVisible.value,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy key',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: key));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Key copied to clipboard')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate Key'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: handleRegenerate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add tile to settings_screen.dart**

Inside the `if (isAdmin) ...[ ... ]` block, after the Backup & Restore tile, add:

```dart
              const SizedBox(height: AppSpacing.sm),
              _SettingsTile(
                icon: Icons.key_rounded,
                title: 'CSV Export Key',
                subtitle: 'View or regenerate the encryption key for exported reports',
                onTap: () => context.push('/settings/csv-export-key'),
              ),
```

- [ ] **Step 3: Add route to router.dart**

Add import at top of `router.dart`:
```dart
import '../../features/settings/view/csv_export_key_screen.dart';
```

Inside the `/settings` routes list, add:
```dart
          GoRoute(
            path: 'csv-export-key',
            builder: (context, state) => const CsvExportKeyScreen(),
          ),
```

---

## Task 10: Run all tests

- [ ] **Run full test suite**

```bash
cd mobile && flutter test test/core/
```

Expected: All tests in `test/core/csv/` and `test/core/crypto/` pass.

- [ ] **Analyze for errors**

```bash
cd mobile && dart analyze
```

Expected: No errors (warnings for unused imports in generated files are OK).
