import '../../database/app_database.dart';

/// All 18 tables, in an order that respects foreign-key dependencies
/// (parents before children). Used for JSON dump keys, restore insert
/// order, and — reversed — restore delete order.
const List<String> kBackupTableOrder = [
  'store_info',
  'users',
  'product_groups',
  'products',
  'product_variants',
  'modifier_groups',
  'modifier_options',
  'product_modifier_groups',
  'payment_methods',
  'sales',
  'sale_items',
  'sale_item_modifiers',
  'payments',
  'refunds',
  'refund_items',
  'x_readings',
  'z_readings',
  'daily_reports',
];

abstract final class BackupDataSerializer {
  static Future<Map<String, List<Map<String, Object?>>>> dumpAllTables(
    AppDatabase db,
  ) async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in kBackupTableOrder) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      result[table] = [for (final row in rows) Map<String, Object?>.from(row.data)];
    }
    return result;
  }

  static Future<void> restoreAllTables(
    AppDatabase db,
    Map<String, List<Map<String, Object?>>> data,
  ) async {
    await db.transaction(() async {
      for (final table in kBackupTableOrder.reversed) {
        await db.customStatement('DELETE FROM $table');
      }
      for (final table in kBackupTableOrder) {
        final rows = data[table] ?? const [];
        for (final row in rows) {
          final columns = row.keys.toList();
          final placeholders = List.filled(columns.length, '?').join(', ');
          await db.customStatement(
            'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)',
            [for (final c in columns) row[c]],
          );
        }
      }
    });
  }
}
