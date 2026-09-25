import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../entities/inventory_product.dart';

enum InventoryStatusFilter { all, onMenu, hidden }

class InventoryState {
  final List<InventoryGroup> groups;
  final List<InventoryProduct> products;
  final int? selectedGroupId;
  final String? search;
  final InventoryStatusFilter statusFilter;

  const InventoryState({
    this.groups = const [],
    this.products = const [],
    this.selectedGroupId,
    this.search,
    this.statusFilter = InventoryStatusFilter.all,
  });

  int get availableCount => products.where((p) => p.isAvailable).length;

  /// Keeps the DAO's sort order — rows must not jump when an item is
  /// toggled; the status filter is how users isolate hidden items.
  List<InventoryProduct> get filtered {
    final q = search?.trim().toLowerCase();
    return products.where((p) {
      if (selectedGroupId != null && p.groupId != selectedGroupId) return false;
      if (statusFilter == InventoryStatusFilter.onMenu && !p.isAvailable) return false;
      if (statusFilter == InventoryStatusFilter.hidden && p.isAvailable) return false;
      return q == null || q.isEmpty || p.name.toLowerCase().contains(q);
    }).toList();
  }

  InventoryState copyWith({
    List<InventoryGroup>? groups,
    List<InventoryProduct>? products,
    int? Function()? selectedGroupId,
    String? Function()? search,
    InventoryStatusFilter? statusFilter,
  }) =>
      InventoryState(
        groups: groups ?? this.groups,
        products: products ?? this.products,
        selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        search: search != null ? search() : this.search,
        statusFilter: statusFilter ?? this.statusFilter,
      );
}

class InventoryNotifier extends AsyncNotifier<InventoryState> {
  @override
  Future<InventoryState> build() => _load();

  Future<InventoryState> _load() async {
    final db = ref.watch(databaseProvider);
    final groupRows = await db.productsDao.getAllActiveGroups();
    final productRows = await db.productsDao.getAllProductsWithPrice();

    final groupCounts = <int, int>{};
    for (final p in productRows) {
      groupCounts[p.product.groupId] = (groupCounts[p.product.groupId] ?? 0) + 1;
    }

    final groups = groupRows
        .map((g) => InventoryGroup(id: g.id, name: g.name, productCount: groupCounts[g.id] ?? 0))
        .toList();

    final groupById = {for (final g in groups) g.id: g};

    final products = productRows
        .map((p) => InventoryProduct(
              id: p.product.id,
              groupId: p.product.groupId,
              name: p.product.name,
              price: p.price,
              isAvailable: p.product.isAvailable,
              imageUrl: p.product.imageUrl,
              sortOrder: p.product.sortOrder,
              group: groupById[p.product.groupId],
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

  void setStatusFilter(InventoryStatusFilter filter) {
    state = state.whenData((s) => s.copyWith(statusFilter: filter));
  }

  Future<void> toggleAvailability(InventoryProduct product) =>
      setAvailability([product.id], isAvailable: !product.isAvailable);

  /// Applied optimistically so the switch flips instantly and the list keeps
  /// its scroll position; a failed write reloads the true DB state.
  Future<void> setAvailability(List<int> productIds, {required bool isAvailable}) async {
    if (productIds.isEmpty) return;
    final ids = productIds.toSet();
    state = state.whenData((s) => s.copyWith(
          products: [
            for (final p in s.products)
              ids.contains(p.id) ? p.copyWith(isAvailable: isAvailable) : p,
          ],
        ));
    try {
      final db = ref.read(databaseProvider);
      await db.productsDao.setProductsAvailability(ids.toList(), isAvailable: isAvailable);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }

  /// Moves products to another category. Refuses the whole move when any
  /// name would collide inside the target category (names are unique per
  /// category — see [createProduct]).
  Future<void> moveToCategory(List<int> productIds, int groupId) async {
    final current = state.value;
    if (current == null || productIds.isEmpty) return;
    final ids = productIds.toSet();
    final moving = current.products.where((p) => ids.contains(p.id) && p.groupId != groupId);

    final db = ref.read(databaseProvider);
    final seen = <String>{};
    final conflicts = <String>[];
    for (final p in moving) {
      final key = p.name.toLowerCase();
      if (!seen.add(key) || await db.productsDao.isProductNameTaken(groupId, p.name)) {
        conflicts.add(p.name);
      }
    }
    if (conflicts.isNotEmpty) {
      throw StateError('Target category already has: ${conflicts.join(', ')}');
    }

    await db.productsDao.moveProductsToGroup(moving.map((p) => p.id).toList(), groupId);
    await refresh();
  }

  /// Reloads from the DB without flashing a loading state, keeping the
  /// user's search / category / status filters.
  Future<void> refresh() async {
    final prev = state.value;
    if (prev == null) state = const AsyncValue.loading();
    final next = await AsyncValue.guard(_load);
    state = next.whenData((s) {
      if (prev == null) return s;
      final groupStillExists = s.groups.any((g) => g.id == prev.selectedGroupId);
      return s.copyWith(
        selectedGroupId: () => groupStillExists ? prev.selectedGroupId : null,
        search: () => prev.search,
        statusFilter: prev.statusFilter,
      );
    });
  }

  /// Creates the product row only (no variants) and returns its new id — the
  /// caller (`ProductFormDialog`) follows up with [saveVariants] once the user
  /// has entered at least one variant.
  Future<int> createProduct({
    required int groupId,
    required String name,
    String? imageUrl,
  }) async {
    final db = ref.read(databaseProvider);
    if (await db.productsDao.isProductNameTaken(groupId, name)) {
      throw StateError('A product named "$name" already exists in this category');
    }
    final id = await db.productsDao.insertProduct(ProductsTableCompanion.insert(
      groupId: groupId,
      name: name,
      imageUrl: Value(imageUrl),
    ));
    await refresh();
    return id;
  }

  Future<void> updateProduct({
    required int id,
    required int groupId,
    required String name,
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
      imageUrl: Value(imageUrl),
    ));
    await refresh();
  }

  /// Validates and persists a product's full variant list (kiosk's business
  /// rules: at least one active variant, unique case-insensitive names among
  /// active variants, price >= 0.01, exactly one active default).
  Future<void> saveVariants(int productId, List<VariantInput> variants) async {
    final active = variants.where((v) => v.isActive).toList();
    if (active.isEmpty) {
      throw StateError('At least one active variant is required');
    }
    final names = active.map((v) => v.name.trim().toLowerCase()).toList();
    if (names.toSet().length != names.length) {
      throw StateError('Variant names must be unique');
    }
    if (active.any((v) => v.price < 0.01)) {
      throw StateError('Each active variant needs a price of at least 0.01');
    }
    final defaultCount = active.where((v) => v.isDefault).length;
    if (defaultCount != 1) {
      throw StateError('Exactly one active variant must be marked default');
    }

    final db = ref.read(databaseProvider);
    await db.productsDao.clearDefaultVariant(productId);
    for (final v in variants) {
      if (v.id == null) {
        await db.productsDao.insertVariant(ProductVariantsTableCompanion.insert(
          productId: productId,
          name: v.name.trim(),
          price: v.price,
          isDefault: Value(v.isDefault),
          isActive: Value(v.isActive),
        ));
      } else {
        await db.productsDao.updateVariant(
          v.id!,
          name: v.name.trim(),
          price: v.price,
          isDefault: v.isDefault,
          isActive: v.isActive,
        );
      }
    }
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
}

final inventoryNotifierProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

/// Loads a single product's variants — used by [ProductFormDialog] to seed
/// its editable rows in edit mode.
final productVariantsProvider =
    FutureProvider.family<List<ProductVariantsTableData>, int>((ref, productId) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.getVariantsForProduct(productId);
});
