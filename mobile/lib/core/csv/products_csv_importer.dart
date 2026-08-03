import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'csv_importer.dart';

/// Header row expected by this importer — matches the kiosk (Windows) app's
/// products CSV format exactly, so a file exported/prepared for one app can be
/// imported by the other without edits. `Product Image URL` is optional; files
/// without it (7 columns) are still accepted.
const kProductsCsvHeader =
    'Category,Category Description,Product Name,Product Description,'
    'Product Base Price,Variant Name,Variant Price,Product Image URL';

const _kExpectedHeaders = [
  'category',
  'category description',
  'product name',
  'product description',
  'product base price',
  'variant name',
  'variant price',
];
const _kImageHeader = 'product image url';

/// Import mode, mirrors the kiosk app's two options:
/// - [upsert]: adds new categories/products/variants and updates existing ones
///   by name. Nothing already in the catalog is touched otherwise.
/// - [replace]: treats the CSV as the full catalog — any category, product, or
///   variant NOT present in the file is removed from the local database so it
///   no longer appears in Inventory Management. A product (or its category)
///   is only kept — deactivated rather than deleted — when it has past sale
///   history, since removing it would corrupt transaction/report data;
///   variants never have this restriction (nothing references them).
enum ProductsCsvImportMode { upsert, replace }

/// Row-level counts from a products CSV import, mirroring the kiosk app's
/// `ImportProductsCsvResult` so the mobile import dialog can show the same
/// "N added, N updated, N removed" summary.
class ProductsCsvImportSummary {
  const ProductsCsvImportSummary({
    required this.categoriesInserted,
    required this.categoriesUpdated,
    required this.categoriesRemoved,
    required this.productsInserted,
    required this.productsUpdated,
    required this.productsRemoved,
    required this.productsKeptForHistory,
    required this.variantsInserted,
    required this.variantsUpdated,
    required this.variantsRemoved,
    required this.errors,
  });

  const ProductsCsvImportSummary.empty()
      : categoriesInserted = 0,
        categoriesUpdated = 0,
        categoriesRemoved = 0,
        productsInserted = 0,
        productsUpdated = 0,
        productsRemoved = 0,
        productsKeptForHistory = 0,
        variantsInserted = 0,
        variantsUpdated = 0,
        variantsRemoved = 0,
        errors = const [];

  final int categoriesInserted;
  final int categoriesUpdated;
  final int categoriesRemoved;
  final int productsInserted;
  final int productsUpdated;
  final int productsRemoved;
  /// Products that couldn't be deleted because they appear in past sales —
  /// disabled instead so they drop out of ordering but sales/reports still
  /// resolve their name.
  final int productsKeptForHistory;
  final int variantsInserted;
  final int variantsUpdated;
  final int variantsRemoved;
  final List<CsvRowError> errors;

  bool get hasErrors => errors.isNotEmpty;
}

class _GroupedProduct {
  _GroupedProduct({required this.category, required this.name, required this.basePrice});

  final String category;
  final String name;
  final double basePrice;
  String? imageUrl;
  final List<_VariantData> variants = [];
}

class _VariantData {
  const _VariantData(this.name, this.price);
  final String name;
  final double price;
}

class _RemovalCounts {
  const _RemovalCounts({
    required this.categoriesRemoved,
    required this.productsRemoved,
    required this.productsKeptForHistory,
    required this.variantsRemoved,
  });

  final int categoriesRemoved;
  final int productsRemoved;
  final int productsKeptForHistory;
  final int variantsRemoved;
}

/// Imports a products/categories/variants CSV using the same column layout and
/// row-grouping rules as the kiosk app's backend importer: rows sharing a
/// Category + Product Name accumulate into one product with many variants, and
/// a product with no variant rows gets a single "Regular" variant priced at its
/// Product Base Price. Existing categories/products/variants are matched by
/// name and updated in place. See [ProductsCsvImportMode] for how "replace"
/// handles rows the CSV no longer contains.
class ProductsCsvImporter implements CsvImporter {
  const ProductsCsvImporter(this._db);

  final AppDatabase _db;

  /// Generic single-entity-list import, required by [CsvImporter] so this
  /// importer can still appear in the app's bundled "Import CSV" screen
  /// alongside Modifiers/Users/Store Info. Always runs in upsert mode; use
  /// [importCsv] directly for mode selection and the richer summary.
  @override
  Future<ImportResult> importFile(File file) async {
    final summary = await importCsv(file, mode: ProductsCsvImportMode.upsert);
    return ImportResult(
      successCount: summary.productsInserted + summary.productsUpdated,
      skippedCount: 0,
      errors: summary.errors,
    );
  }

  Future<ProductsCsvImportSummary> importCsv(
    File file, {
    required ProductsCsvImportMode mode,
  }) async {
    final rows = _parse(await file.readAsString());
    if (rows.isEmpty) return const ProductsCsvImportSummary.empty();

    final headerError = _validateHeader(rows.first);
    if (headerError != null) {
      return ProductsCsvImportSummary(
        categoriesInserted: 0,
        categoriesUpdated: 0,
        categoriesRemoved: 0,
        productsInserted: 0,
        productsUpdated: 0,
        productsRemoved: 0,
        productsKeptForHistory: 0,
        variantsInserted: 0,
        variantsUpdated: 0,
        variantsRemoved: 0,
        errors: [CsvRowError(1, headerError)],
      );
    }

    final dataRows = rows.skip(1).toList();
    final errors = <CsvRowError>[];

    final groupedProducts = <_GroupedProduct>[];
    final groupedByKey = <String, _GroupedProduct>{};

    for (var i = 0; i < dataRows.length; i++) {
      final rowNum = i + 2;
      final row = dataRows[i];

      final category = _cell(row, 0);
      final productName = _cell(row, 2);
      final basePriceStr = _cell(row, 4);
      final variantName = _cell(row, 5);
      final variantPriceStr = _cell(row, 6);
      final imageUrl = _cell(row, 7);

      if (category.isEmpty) {
        errors.add(CsvRowError(rowNum, 'Category is required'));
        continue;
      }
      if (productName.isEmpty) {
        errors.add(CsvRowError(rowNum, 'Product Name is required'));
        continue;
      }
      final basePrice = double.tryParse(basePriceStr);
      if (basePrice == null || basePrice < 0) {
        errors.add(CsvRowError(rowNum, 'Product Base Price must be a valid number >= 0'));
        continue;
      }
      double? variantPrice;
      if (variantName.isNotEmpty) {
        variantPrice = double.tryParse(variantPriceStr);
        if (variantPrice == null || variantPrice < 0) {
          errors.add(CsvRowError(
            rowNum,
            'Variant Price must be a valid number >= 0 when Variant Name is present',
          ));
          continue;
        }
      }

      final key = '$category::$productName';
      final grouped = groupedByKey.putIfAbsent(key, () {
        final g = _GroupedProduct(category: category, name: productName, basePrice: basePrice);
        groupedProducts.add(g);
        return g;
      });
      if ((grouped.imageUrl == null || grouped.imageUrl!.isEmpty) && imageUrl.isNotEmpty) {
        grouped.imageUrl = imageUrl;
      }
      if (variantName.isNotEmpty) {
        grouped.variants.add(_VariantData(variantName, variantPrice!));
      }
    }

    for (final g in groupedProducts) {
      if (g.variants.isEmpty) {
        g.variants.add(_VariantData('Regular', g.basePrice));
      }
    }

    var categoriesInserted = 0;
    var categoriesUpdated = 0;
    var productsInserted = 0;
    var productsUpdated = 0;
    var variantsInserted = 0;
    var variantsUpdated = 0;

    final groupIdByName = <String, int>{};
    final csvCategoryNames = groupedProducts.map((g) => g.category).toSet();
    final csvProductKeys = <String>{};
    final csvVariantKeys = <String>{};

    final existingProducts = await _db.productsDao.getAllProducts();
    final productIdByKey = {
      for (final p in existingProducts) '${p.groupId}::${p.name}': p.id,
    };

    for (final g in groupedProducts) {
      try {
        final key = '${g.category}::${g.name}';
        csvProductKeys.add(key);

        int groupId;
        if (groupIdByName.containsKey(g.category)) {
          groupId = groupIdByName[g.category]!;
        } else {
          final (id, wasInserted) = await _ensureGroup(g.category);
          groupId = id;
          groupIdByName[g.category] = id;
          if (wasInserted) {
            categoriesInserted++;
          } else {
            categoriesUpdated++;
          }
        }

        final productKey = '$groupId::${g.name}';
        final existingProductId = productIdByKey[productKey];
        final int productId;
        if (existingProductId != null) {
          productId = existingProductId;
          await _syncProduct(productId, groupId, g);
          productsUpdated++;
        } else {
          productId = await _insertProduct(groupId, g);
          productIdByKey[productKey] = productId;
          productsInserted++;
        }

        for (final variant in g.variants) {
          csvVariantKeys.add('$productId::${variant.name}');
        }

        final (inserted, updated) = await _syncVariants(productId, g.variants);
        variantsInserted += inserted;
        variantsUpdated += updated;
      } catch (e) {
        errors.add(CsvRowError(0, '${g.category} / ${g.name}: $e'));
      }
    }

    var categoriesRemoved = 0;
    var productsRemoved = 0;
    var productsKeptForHistory = 0;
    var variantsRemoved = 0;
    if (mode == ProductsCsvImportMode.replace) {
      final removal = await _removeMissing(
        csvCategoryNames: csvCategoryNames,
        csvProductKeys: csvProductKeys,
        csvVariantKeys: csvVariantKeys,
      );
      categoriesRemoved = removal.categoriesRemoved;
      productsRemoved = removal.productsRemoved;
      productsKeptForHistory = removal.productsKeptForHistory;
      variantsRemoved = removal.variantsRemoved;
    }

    return ProductsCsvImportSummary(
      categoriesInserted: categoriesInserted,
      categoriesUpdated: categoriesUpdated,
      categoriesRemoved: categoriesRemoved,
      productsInserted: productsInserted,
      productsUpdated: productsUpdated,
      productsRemoved: productsRemoved,
      productsKeptForHistory: productsKeptForHistory,
      variantsInserted: variantsInserted,
      variantsUpdated: variantsUpdated,
      variantsRemoved: variantsRemoved,
      errors: errors,
    );
  }

  /// Deletes categories, products, and variants absent from the imported CSV
  /// — "Replace Entire Menu" means those rows disappear from Inventory
  /// Management, not just get dimmed out. Variants are always safe to delete
  /// outright (nothing references them). A product is only deleted when it
  /// has no sale history; otherwise it's disabled (kept for report/receipt
  /// integrity) and doesn't count toward `categoriesRemoved`/`productsRemoved`.
  /// A category is only deleted once every one of its products is gone.
  Future<_RemovalCounts> _removeMissing({
    required Set<String> csvCategoryNames,
    required Set<String> csvProductKeys,
    required Set<String> csvVariantKeys,
  }) async {
    var categoriesRemoved = 0;
    var productsRemoved = 0;
    var productsKeptForHistory = 0;
    var variantsRemoved = 0;

    final groups = await _db.productsDao.getAllGroups();
    final groupNameById = {for (final g in groups) g.id: g.name};

    final products = await _db.productsDao.getAllProducts();
    final remainingProductCountByGroup = <int, int>{};
    for (final p in products) {
      remainingProductCountByGroup[p.groupId] = (remainingProductCountByGroup[p.groupId] ?? 0) + 1;
    }

    for (final product in products) {
      final categoryName = groupNameById[product.groupId];
      final key = categoryName != null ? '$categoryName::${product.name}' : null;
      final keepProduct = key != null && csvProductKeys.contains(key);

      final variants = await _db.productsDao.getVariantsForProduct(product.id);
      for (final variant in variants) {
        final variantKey = '${product.id}::${variant.name}';
        if (!keepProduct || !csvVariantKeys.contains(variantKey)) {
          await _db.productsDao.deleteVariant(variant.id);
          variantsRemoved++;
        }
      }

      if (keepProduct) continue;

      if (await _db.productsDao.productHasSaleHistory(product.id)) {
        if (product.isAvailable) {
          await _db.productsDao.toggleProductAvailability(product.id, isAvailable: false);
        }
        productsKeptForHistory++;
        continue;
      }

      await _db.productsDao.deleteModifierGroupLinksForProduct(product.id);
      await _db.productsDao.deleteProduct(product.id);
      productsRemoved++;
      remainingProductCountByGroup[product.groupId] =
          (remainingProductCountByGroup[product.groupId] ?? 1) - 1;
    }

    for (final group in groups) {
      if (csvCategoryNames.contains(group.name)) continue;
      if ((remainingProductCountByGroup[group.id] ?? 0) > 0) {
        // Some of this category's products survive (sale history), so the
        // category itself must survive too — just hide it from active use.
        if (group.isActive) {
          await _db.productsDao.updateProductGroup(group.id, name: group.name, isActive: false);
        }
        continue;
      }
      await _db.productsDao.deleteProductGroup(group.id);
      categoriesRemoved++;
    }

    return _RemovalCounts(
      categoriesRemoved: categoriesRemoved,
      productsRemoved: productsRemoved,
      productsKeptForHistory: productsKeptForHistory,
      variantsRemoved: variantsRemoved,
    );
  }

  Future<(int, bool)> _ensureGroup(String name) async {
    final groups = await _db.productsDao.getAllGroups();
    final existing = groups.firstWhereOrNull((g) => g.name == name);
    if (existing != null) {
      if (!existing.isActive) {
        await _db.productsDao.updateProductGroup(existing.id, name: existing.name, isActive: true);
      }
      return (existing.id, false);
    }
    final id = await _db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
    return (id, true);
  }

  Future<int> _insertProduct(int groupId, _GroupedProduct g) {
    return _db.productsDao.insertProduct(
      ProductsTableCompanion.insert(
        groupId: groupId,
        name: g.name,
        imageUrl: Value(g.imageUrl),
      ),
    );
  }

  Future<void> _syncProduct(int productId, int groupId, _GroupedProduct g) {
    return _db.productsDao.upsertProduct(
      ProductsTableCompanion(
        id: Value(productId),
        groupId: Value(groupId),
        name: Value(g.name),
        isAvailable: const Value(true),
        imageUrl: g.imageUrl != null ? Value(g.imageUrl) : const Value.absent(),
      ),
    );
  }

  Future<(int, int)> _syncVariants(int productId, List<_VariantData> variants) async {
    await _db.productsDao.clearDefaultVariant(productId);
    final existingByName = {
      for (final v in await _db.productsDao.getVariantsForProduct(productId)) v.name: v,
    };

    var inserted = 0;
    var updated = 0;
    for (var i = 0; i < variants.length; i++) {
      final variant = variants[i];
      final isDefault = i == 0;
      final existing = existingByName[variant.name];
      if (existing != null) {
        await _db.productsDao.updateVariant(
          existing.id,
          name: variant.name,
          price: variant.price,
          isDefault: isDefault,
          isActive: true,
        );
        updated++;
      } else {
        await _db.productsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            productId: productId,
            name: variant.name,
            price: variant.price,
            isDefault: Value(isDefault),
          ),
        );
        inserted++;
      }
    }
    return (inserted, updated);
  }

  /// Returns a human-readable error when the header row doesn't match the
  /// expected column layout (7 columns, or 8 with the optional image column),
  /// so a mismatched file (e.g. a different app's export) fails fast with one
  /// clear message instead of a wall of per-row errors.
  String? _validateHeader(List<String> header) {
    final normalized = header.map((h) => h.trim().toLowerCase()).toList();
    final expectedWithImage = [..._kExpectedHeaders, _kImageHeader];

    final matchesBase = normalized.length == _kExpectedHeaders.length &&
        const ListEquality<String>().equals(normalized, _kExpectedHeaders);
    final matchesWithImage = normalized.length == expectedWithImage.length &&
        const ListEquality<String>().equals(normalized, expectedWithImage);

    if (matchesBase || matchesWithImage) return null;

    return 'Header row does not match the expected products CSV format. '
        'Expected: $kProductsCsvHeader';
  }

  String _cell(List<String> row, int index) => index < row.length ? row[index].trim() : '';

  /// Splits CSV text into header + data rows, honouring double-quoted fields
  /// (which may contain commas) and escaped quotes (`""`) — mirrors the
  /// desktop kiosk backend's parser so the same file behaves identically on
  /// both apps.
  List<List<String>> _parse(String content) {
    if (content.isNotEmpty && content.codeUnitAt(0) == 0xfeff) {
      content = content.substring(1);
    }
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
    return lines.map(_parseLine).toList();
  }

  List<String> _parseLine(String line) {
    final fields = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        fields.add(current.toString().trim());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    fields.add(current.toString().trim());
    return fields;
  }
}
