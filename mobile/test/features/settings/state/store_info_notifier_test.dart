import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/settings/state/store_info_notifier.dart';

void main() {
  test('save persists tin alongside the other store info fields', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(storeInfoProvider.future);
    await container.read(storeInfoProvider.notifier).save(
          storeName: 'My Store',
          address: '123 Main St',
          taxRate: 12.0,
          currency: 'PHP',
          receiptFooter: 'Thanks!',
          tin: '123-456-789-000',
          terminalName: 'Front Counter',
        );

    final info = await container.read(storeInfoProvider.future);
    expect(info!.tin, '123-456-789-000');
    expect(info.storeName, 'My Store');
    expect(info.terminalName, 'Front Counter');
  });

  test('payment methods can be created, edited, and deleted through the notifier', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(() {
      container.dispose();
      db.close();
    });

    await container.read(paymentMethodsProvider.future);
    await container.read(paymentMethodsProvider.notifier).create(
          label: 'GCash',
          accountName: 'My Store',
          accountNumber: '09171234567',
        );

    var methods = await container.read(paymentMethodsProvider.future);
    expect(methods, hasLength(1));
    final id = methods.first.id;

    await container.read(paymentMethodsProvider.notifier).edit(
          id: id,
          label: 'GCash',
          accountName: 'My Store',
          accountNumber: '09179999999',
        );
    methods = await container.read(paymentMethodsProvider.future);
    expect(methods.first.accountNumber, '09179999999');

    await container.read(paymentMethodsProvider.notifier).delete(id);
    methods = await container.read(paymentMethodsProvider.future);
    expect(methods, isEmpty);
  });
}
