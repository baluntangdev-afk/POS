import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/inventory_product.dart';

class InventoryState {
  final List<InventoryGroup> groups;
  final List<InventoryProduct> products;
  final int? selectedGroupId;
  final String? search;

  const InventoryState({
    this.groups = const [],
    this.products = const [],
    this.selectedGroupId,
    this.search,
  });

  List<InventoryProduct> get filtered {
    var list = products;
    if (selectedGroupId != null) {
      list = list.where((p) => p.groupId == selectedGroupId).toList();
    }
    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  InventoryState copyWith({
    List<InventoryGroup>? groups,
    List<InventoryProduct>? products,
    int? Function()? selectedGroupId,
    String? Function()? search,
  }) =>
      InventoryState(
        groups: groups ?? this.groups,
        products: products ?? this.products,
        selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        search: search != null ? search() : this.search,
      );
}

class InventoryNotifier extends AsyncNotifier<InventoryState> {
  @override
  Future<InventoryState> build() => _load();

  Future<InventoryState> _load() async {
    final db = ref.watch(databaseProvider);
    final groupRows = await db.productsDao.getAllActiveGroups();
    final productRows = await db.productsDao.getAllProducts();

    final groupCounts = <int, int>{};
    for (final p in productRows) {
      groupCounts[p.groupId] = (groupCounts[p.groupId] ?? 0) + 1;
    }

    final groups = groupRows
        .map((g) => InventoryGroup(id: g.id, name: g.name, productCount: groupCounts[g.id] ?? 0))
        .toList();

    final groupById = {for (final g in groups) g.id: g};

    final products = productRows
        .map((p) => InventoryProduct(
              id: p.id,
              groupId: p.groupId,
              name: p.name,
              price: p.price,
              isAvailable: p.isAvailable,
              imageUrl: p.imageUrl,
              sortOrder: p.sortOrder,
              group: groupById[p.groupId],
            ))
        .toList();

    return InventoryState(groups: groups, products: products);
  }

  void selectGroup(int? groupId) {
    state = state.whenData((s) => s.copyWith(selectedGroupId: () => groupId));
  }

  void setSearch(String? query) {
    state = state.whenData((s) => s.copyWith(search: () => query?.isEmpty == true ? null : query));
  }

  Future<void> toggleAvailability(InventoryProduct product) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.toggleProductAvailability(product.id, isAvailable: !product.isAvailable);
    state = state.whenData((s) {
      final updated = s.products.map((p) => p.id == product.id ? p.copyWith(isAvailable: !product.isAvailable) : p).toList();
      return s.copyWith(products: updated);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createProduct({
    required int groupId,
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    await db.productsDao.insertProduct(ProductsTableCompanion.insert(
      groupId: groupId,
      name: name,
      price: price,
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  Future<void> updateProduct({
    required int id,
    required int groupId,
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name, excludeId: id)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    await db.productsDao.upsertProduct(ProductsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      price: Value(price),
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  Future<void> deleteProduct(int id) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.deleteProduct(id);
    await refresh();
  }

  Future<void> createCategory({required String name}) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
    await refresh();
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required bool isActive,
  }) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.updateProductGroup(id, name: name, isActive: isActive);
    await refresh();
  }

  Future<void> deleteCategory(int id) async {
    final db = ref.read(databaseProvider);
    await db.productsDao.deleteProductGroup(id);
    await refresh();
  }
}

final inventoryNotifierProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);
