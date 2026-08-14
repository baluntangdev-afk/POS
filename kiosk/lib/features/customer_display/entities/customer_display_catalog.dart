import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../../sales/entities/product.dart';
import '../../sales/entities/product_group.dart';
import '../../sales/entities/store.dart';
import 'customer_display_mappers.dart';

part 'customer_display_catalog.mapper.dart';

/// The full menu, pushed from the cashier engine to the customer-display
/// engine on a timer (see `CustomerDisplayHost`) rather than on cart
/// changes, since it reflects admin/catalog edits that can happen at any
/// time, not just while an order is in progress.
@MappableClass()
class CustomerDisplayCatalog with CustomerDisplayCatalogMappable {
  const CustomerDisplayCatalog({
    required this.storeName,
    this.storeLogoUrl,
    required this.categories,
  });

  factory CustomerDisplayCatalog.build({
    required Store store,
    required List<CustomerDisplayCategory> categories,
  }) {
    return CustomerDisplayCatalog(
      storeName: store.legalName,
      storeLogoUrl: store.logo,
      categories: categories,
    );
  }

  Map<String, dynamic> toTransportMap() {
    ensureCustomerDisplayMappersRegistered();
    return toMap();
  }

  /// Takes the raw `call.arguments` from the platform channel directly (not
  /// pre-cast) — see [normalizeChannelMap] for why that matters.
  static CustomerDisplayCatalog fromTransportMap(Object? channelArguments) {
    ensureCustomerDisplayMappersRegistered();
    return CustomerDisplayCatalogMapper.fromMap(normalizeChannelMap(channelArguments));
  }

  final String storeName;
  final String? storeLogoUrl;
  final List<CustomerDisplayCategory> categories;
}

@MappableClass()
class CustomerDisplayCategory with CustomerDisplayCategoryMappable {
  const CustomerDisplayCategory({
    required this.id,
    required this.name,
    this.image,
    required this.products,
  });

  factory CustomerDisplayCategory.build({
    required ProductGroup group,
    required List<Product> products,
  }) {
    return CustomerDisplayCategory(
      id: group.id,
      name: group.name,
      image: group.image.isEmpty ? null : group.image,
      products: products.map(CustomerDisplayProduct.fromProduct).toList(),
    );
  }

  final int id;
  final String name;
  final Uint8List? image;
  final List<CustomerDisplayProduct> products;
}

@MappableClass()
class CustomerDisplayProduct with CustomerDisplayProductMappable {
  const CustomerDisplayProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory CustomerDisplayProduct.fromProduct(Product product) {
    return CustomerDisplayProduct(
      id: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.image.isEmpty ? null : product.image,
    );
  }

  final int id;
  final String name;
  final Decimal price;
  final String? imageUrl;
}
