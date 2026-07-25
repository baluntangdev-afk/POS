import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/payment_methods_table.dart';
import 'package:mobile/core/database/tables/store_info_table.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('schemaVersion is at least 4', () {
    expect(db.schemaVersion, greaterThanOrEqualTo(4));
  });

  test('tin and terminalName columns round-trip on store_info', () async {
    await db.storeInfoDao.ensureStoreInfoExists();
    await db.storeInfoDao.upsertStoreInfo(
      const StoreInfoTableCompanion(
        id: Value(1),
        tin: Value('123-456-789-000'),
        terminalName: Value('Front Counter'),
      ),
    );

    final info = await db.storeInfoDao.getStoreInfo();
    expect(info!.tin, '123-456-789-000');
    expect(info.terminalName, 'Front Counter');
  });

  test('payment methods can be inserted, listed, updated, and deleted', () async {
    final id = await db.storeInfoDao.insertPaymentMethod(
      PaymentMethodsTableCompanion.insert(
        label: 'GCash',
        accountName: const Value('Store Name'),
        accountNumber: const Value('09171234567'),
        sortOrder: const Value(5),
      ),
    );

    var methods = await db.storeInfoDao.getAllPaymentMethods();
    expect(methods, hasLength(1));
    expect(methods.first.label, 'GCash');

    // Partial update: only accountNumber changes. sortOrder isn't passed —
    // this must NOT reset sortOrder to its column default (proves the DAO
    // uses a partial .write(), not a full-row .replace()).
    await db.storeInfoDao.updatePaymentMethod(
      id,
      const PaymentMethodsTableCompanion(accountNumber: Value('09179999999')),
    );
    methods = await db.storeInfoDao.getAllPaymentMethods();
    expect(methods.first.accountNumber, '09179999999');
    expect(methods.first.label, 'GCash');
    expect(methods.first.sortOrder, 5);

    await db.storeInfoDao.deletePaymentMethod(id);
    methods = await db.storeInfoDao.getAllPaymentMethods();
    expect(methods, isEmpty);
  });
}
