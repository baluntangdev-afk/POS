import 'package:flutter/foundation.dart';

import '../entities/customer_display_catalog.dart';

/// One screen's worth of the menu showcase: a fixed-size window of
/// [columns] * [rows] cells from a single category. A category with more
/// products than that capacity is split across multiple [MenuSlide]s (same
/// [category], increasing [pageIndex]) instead of shrinking its cards to fit
/// — every slide in the whole rotation has exactly the same cell count, so
/// card size never depends on how many products happen to be in a category.
@immutable
class MenuSlide {
  const MenuSlide({
    required this.category,
    required this.categoryIndex,
    required this.categoryCount,
    required this.pageIndex,
    required this.pageCount,
    required this.products,
  });

  final CustomerDisplayCategory category;
  final int categoryIndex;
  final int categoryCount;
  final int pageIndex;
  final int pageCount;

  /// Exactly `columns * rows` entries; `null` marks a trailing empty cell on
  /// a partially-filled slide.
  final List<CustomerDisplayProduct?> products;
}

/// Splits every category's products into fixed-capacity (`columns * rows`)
/// pages, flattened into one rotation-order list of slides.
List<MenuSlide> buildMenuSlides({
  required List<CustomerDisplayCategory> categories,
  required int columns,
  required int rows,
}) {
  final capacity = columns * rows;
  final slides = <MenuSlide>[];

  for (var categoryIndex = 0; categoryIndex < categories.length; categoryIndex++) {
    final category = categories[categoryIndex];
    final products = category.products;
    final pageCount = products.isEmpty ? 1 : (products.length / capacity).ceil();

    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final start = pageIndex * capacity;
      final end = (start + capacity < products.length) ? start + capacity : products.length;
      final pageProducts = <CustomerDisplayProduct?>[
        for (var i = start; i < end; i++) products[i],
      ];
      while (pageProducts.length < capacity) {
        pageProducts.add(null);
      }

      slides.add(
        MenuSlide(
          category: category,
          categoryIndex: categoryIndex,
          categoryCount: categories.length,
          pageIndex: pageIndex,
          pageCount: pageCount,
          products: pageProducts,
        ),
      );
    }
  }

  return slides;
}
