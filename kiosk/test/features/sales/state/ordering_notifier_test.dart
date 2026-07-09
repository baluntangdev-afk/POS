import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_app/features/sales/entities/cashier.dart';
import 'package:pos_app/features/sales/entities/product.dart';
import 'package:pos_app/features/sales/entities/product_group.dart';
import 'package:pos_app/features/sales/entities/store.dart';
import 'package:pos_app/features/sales/repositories/cashier_repository.dart';
import 'package:pos_app/features/sales/repositories/product_group_repository.dart';
import 'package:pos_app/features/sales/repositories/product_repository.dart';
import 'package:pos_app/features/sales/repositories/store_repository.dart';
import 'package:pos_app/features/sales/state/ordering_notifier.dart';

class _FakeStoreRepository implements StoreRepository {
  @override
  Future<Store> getCurrent() async => const Store(
    legalName: 'Test Store',
    tin: '000',
    addressLine1: 'Addr 1',
    addressLine2: 'Addr 2',
  );
}

class _FakeCashierRepository implements CashierRepository {
  @override
  Future<Cashier> getCurrent() async => Cashier.unknown();
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<IList<Product>> getByGroup(ProductGroup group) async => const IList.empty();

  @override
  Future<Product> getById(int id) async => throw UnimplementedError();
}

class _FakeProductGroupRepository implements ProductGroupRepository {
  _FakeProductGroupRepository(this.groups);

  IList<ProductGroup> groups;

  @override
  Future<IList<ProductGroup>> getAll() async => groups;
}

ProductGroup _group(int id, String name) => ProductGroup(id: id, name: name, image: Uint8List(0));

void main() {
  test('refreshProductGroups picks up categories added after the initial load', () async {
    final groupRepo = _FakeProductGroupRepository(IList([_group(1, 'Drinks')]));

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWithValue(_FakeStoreRepository()),
        cashierRepositoryProvider.overrideWithValue(_FakeCashierRepository()),
        productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
        productGroupRepositoryProvider.overrideWithValue(groupRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(orderingProvider.future);
    expect(container.read(orderingProvider).value!.productGroups.length, 1);

    // Simulate a new category being added elsewhere (Catalog Management) while
    // the cashier is mid-sale on the ordering screen.
    groupRepo.groups = IList([_group(1, 'Drinks'), _group(2, 'Desserts')]);

    await container.read(orderingProvider.notifier).refreshProductGroups();

    final updated = container.read(orderingProvider).value!;
    expect(updated.productGroups.length, 2);
    expect(updated.productGroups.map((g) => g.name), contains('Desserts'));
  });
}
