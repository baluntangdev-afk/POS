import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/catalog_product.dart';

class CatalogState {
  final List<CatalogGroup> groups;
  final List<CatalogProduct> products;
  final int? selectedGroupId;
  final String? search;

  const CatalogState({
    this.groups = const [],
    this.products = const [],
    this.selectedGroupId,
    this.search,
  });

  List<CatalogProduct> get filtered {
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

  CatalogState copyWith({
    List<CatalogGroup>? groups,
    List<CatalogProduct>? products,
    int? Function()? selectedGroupId,
    String? Function()? search,
  }) =>
      CatalogState(
        groups: groups ?? this.groups,
        products: products ?? this.products,
        selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        search: search != null ? search() : this.search,
      );
}

class CatalogNotifier extends AsyncNotifier<CatalogState> {
  @override
  Future<CatalogState> build() => _load();

  Future<CatalogState> _load() async {
    final db = ref.watch(databaseProvider);
    final groupRows = await db.productsDao.getAllActiveGroups();
    final productRows = await db.productsDao.getAllProducts();

    final groupCounts = <int, int>{};
    for (final p in productRows) {
      groupCounts[p.groupId] = (groupCounts[p.groupId] ?? 0) + 1;
    }

    final groups = groupRows
        .map((g) => CatalogGroup(id: g.id, name: g.name, productCount: groupCounts[g.id] ?? 0))
        .toList();

    final groupById = {for (final g in groups) g.id: g};

    final products = productRows
        .map((p) => CatalogProduct(
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

    return CatalogState(groups: groups, products: products);
  }

  void selectGroup(int? groupId) {
    state = state.whenData((s) => s.copyWith(selectedGroupId: () => groupId));
  }

  void setSearch(String? query) {
    state = state.whenData((s) => s.copyWith(search: () => query?.isEmpty == true ? null : query));
  }

  Future<void> toggleAvailability(CatalogProduct product) async {
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
}

final catalogNotifierProvider =
    AsyncNotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);
