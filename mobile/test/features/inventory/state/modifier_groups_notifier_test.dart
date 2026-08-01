import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
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
    productId = await db.productsDao
        .insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: 'Latte'));
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('allModifierGroupsProvider lists global groups with their options', () async {
    final actions = container.read(modifierGroupsManagementActionsProvider);
    await actions.createGroup(name: 'Size', isRequired: true, maxSelections: 1);

    final groups = await container.read(allModifierGroupsProvider.future);
    expect(groups, hasLength(1));
    expect(groups.single.group.name, 'Size');
    expect(groups.single.options, isEmpty);

    await actions.createOption(groupId: groups.single.group.id, name: 'Large', additionalPrice: 20);
    final refreshed = await container.read(allModifierGroupsProvider.future);
    expect(refreshed.single.options, hasLength(1));
  });

  test('toggleGroupActive / toggleOptionActive soft-disable instead of deleting', () async {
    final actions = container.read(modifierGroupsManagementActionsProvider);
    await actions.createGroup(name: 'Size', isRequired: false, maxSelections: 1);
    var groups = await container.read(allModifierGroupsProvider.future);
    final groupId = groups.single.group.id;

    await actions.createOption(groupId: groupId, name: 'Large', additionalPrice: 20);
    groups = await container.read(allModifierGroupsProvider.future);
    final optionId = groups.single.options.single.id;

    await actions.toggleGroupActive(groupId, isActive: false);
    await actions.toggleOptionActive(optionId, isActive: false);

    groups = await container.read(allModifierGroupsProvider.future);
    expect(groups.single.group.isActive, isFalse);
    expect(groups.single.options.single.isActive, isFalse);
  });

  test('attachedModifierGroupsProvider and attach/detach for a specific product', () async {
    final managementActions = container.read(modifierGroupsManagementActionsProvider);
    await managementActions.createGroup(name: 'Size', isRequired: false, maxSelections: 1);
    final groups = await container.read(allModifierGroupsProvider.future);
    final groupId = groups.single.group.id;

    var attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, isEmpty);

    final productActions = container.read(productModifierGroupActionsProvider(productId));
    await productActions.attach(groupId);
    attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, hasLength(1));
    expect(attached.single.id, groupId);

    await productActions.detach(groupId);
    attached = await container.read(attachedModifierGroupsProvider(productId).future);
    expect(attached, isEmpty);
  });
}
