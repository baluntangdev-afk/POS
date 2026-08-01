import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  test('schemaVersion is at least 2 and new tables exist', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // >= rather than == so this test doesn't need updating on every future
    // schema bump — its real intent is "the Phase 2 tables exist," not
    // "the version is exactly 2."
    expect(db.schemaVersion, greaterThanOrEqualTo(2));

    await db.into(db.xReadingsTable).insert(XReadingsTableCompanion.insert(
          cashierId: 1,
          cashierName: 'Test Cashier',
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 2),
          generatedAt: DateTime(2026, 1, 2),
          totalSales: 100,
          transactionCount: 1,
          voidedCount: 0,
          refundedCount: 0,
          paymentBreakdownJson: '[]',
          topProductsJson: '[]',
        ));
    final xReadings = await db.select(db.xReadingsTable).get();
    expect(xReadings, hasLength(1));
  });
}
