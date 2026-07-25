import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/product_groups_table.dart';
import 'package:mobile/core/database/tables/products_table.dart';
import 'package:mobile/core/database/tables/modifier_groups_table.dart';
import 'package:mobile/core/database/tables/modifier_options_table.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/inventory/state/modifier_groups_notifier.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int productId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

    final groupId = await db.productsDao
        .insertProductGroup(ProductGroupsTableCompanion.insert(name: 'Drinks'));
    productId = await db.productsDao.insertProduct(
        ProductsTableCompanion.insert(groupId: groupId, name: 'Latte', price: 100));
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('returns modifier groups paired with their options', () async {
    final modGroupId = await db.productsDao.insertModifierGroup(
        ModifierGroupsTableCompanion.insert(productId: productId, name: 'Size'));
    await db.productsDao.insertModifierOption(
        ModifierOptionsTableCompanion.insert(groupId: modGroupId, name: 'Large'));

    final result = await container.read(modifierGroupsProvider(productId).future);

    expect(result, hasLength(1));
    expect(result.single.group.name, 'Size');
    expect(result.single.options, hasLength(1));
    expect(result.single.options.single.name, 'Large');
  });

  test('create/update/delete group and option mutates state accordingly', () async {
    final actions = container.read(modifierGroupsActionsProvider(productId));

    await container.read(modifierGroupsProvider(productId).future);
    await actions.createGroup(name: 'Size', isRequired: true, maxSelections: 1);

    var state = await container.read(modifierGroupsProvider(productId).future);
    expect(state, hasLength(1));
    final groupId = state.single.group.id;

    await actions.createOption(groupId: groupId, name: 'Small', additionalPrice: 0);
    await actions.createOption(groupId: groupId, name: 'Large', additionalPrice: 20);

    state = await container.read(modifierGroupsProvider(productId).future);
    expect(state.single.options, hasLength(2));
    final smallOptionId = state.single.options.firstWhere((o) => o.name == 'Small').id;
    final largeOptionId = state.single.options.firstWhere((o) => o.name == 'Large').id;

    await actions.updateOption(optionId: smallOptionId, name: 'Small', additionalPrice: 5);
    state = await container.read(modifierGroupsProvider(productId).future);
    expect(state.single.options.firstWhere((o) => o.id == smallOptionId).additionalPrice, 5);

    await actions.deleteOption(largeOptionId);
    state = await container.read(modifierGroupsProvider(productId).future);
    expect(state.single.options, hasLength(1));

    await actions.updateGroup(
        groupId: groupId, name: 'Sizes', isRequired: false, maxSelections: 2);
    state = await container.read(modifierGroupsProvider(productId).future);
    expect(state.single.group.name, 'Sizes');
    expect(state.single.group.isRequired, isFalse);
    expect(state.single.group.maxSelections, 2);

    await actions.deleteGroup(groupId);
    state = await container.read(modifierGroupsProvider(productId).future);
    expect(state, isEmpty);
  });
}
