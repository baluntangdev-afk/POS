import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  test('migrating from schema v6 backfills so_number and refund_number', () async {
    final tempDir = await Directory.systemTemp.createTemp('mobile_pos_migration_test');
    final dbFile = File('${tempDir.path}/test.db');
    addTearDown(() => tempDir.delete(recursive: true));

    // Build a v6 database on disk, close it, then reopen at the current
    // schema (via a fresh NativeDatabase pointed at the same file) to
    // trigger onUpgrade.
    final v6db = _AppDatabaseAtV6(NativeDatabase(dbFile));
    await v6db.customStatement('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, role TEXT NOT NULL, pin_hash TEXT NOT NULL,
        employee_id TEXT, phone TEXT, avatar_url TEXT,
        is_pin_changed INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO users (id, name, role, pin_hash) VALUES (1, 'Cashier', 'cashier', 'x')",
    );
    await v6db.customStatement('''
      CREATE TABLE sales (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        cashier_id INTEGER NOT NULL REFERENCES users (id),
        total REAL NOT NULL, discount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL, type TEXT NOT NULL, created_at INTEGER NOT NULL
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO sales (id, cashier_id, total, status, type, created_at) "
      "VALUES (1, 1, 50, 'completed', 'dine_in', 0)",
    );
    await v6db.customStatement('''
      CREATE TABLE refunds (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL REFERENCES sales (id),
        reason TEXT NOT NULL, total REAL NOT NULL, created_at INTEGER NOT NULL
      )
    ''');
    await v6db.customStatement(
      "INSERT INTO refunds (id, sale_id, reason, total, created_at) "
      "VALUES (1, 1, 'Wrong item', 10, 0)",
    );
    await v6db.customStatement('''
      CREATE TABLE sale_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL REFERENCES sales (id),
        product_id INTEGER NOT NULL,
        variant_name TEXT NOT NULL, qty INTEGER NOT NULL, unit_price REAL NOT NULL
      )
    ''');
    await v6db.customStatement('PRAGMA user_version = 6');
    await v6db.close();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').getSingle(); // forces migration to run

    final sale = await db.customSelect('SELECT so_number FROM sales WHERE id = 1').getSingle();
    expect(sale.read<String>('so_number'), 'SO-000001');

    final refund = await db
        .customSelect('SELECT refund_number, method FROM refunds WHERE id = 1')
        .getSingle();
    expect(refund.read<String>('refund_number'), 'RF-000001');
    expect(refund.read<String>('method'), 'Cash Refund');

    // v8 adds nullable discount columns to sale_items; the column must exist
    // even though there are no rows for this fixture.
    final columns = await db.customSelect('PRAGMA table_info(sale_items)').get();
    final columnNames = columns.map((r) => r.read<String>('name')).toSet();
    expect(
      columnNames,
      containsAll(['discount_type', 'discount_beneficiary_id', 'discount_beneficiary_name',
          'discount_amount', 'vat_exempt_amount']),
    );
  });
}

class _AppDatabaseAtV6 extends AppDatabase {
  _AppDatabaseAtV6(super.executor);

  // The real AppDatabase.onCreate would call m.createAll(), building the full
  // v7 schema before we get a chance to write raw v6 DDL below. This test
  // manages table creation manually, so make onCreate a no-op here.
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) async {});
}
