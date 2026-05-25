import 'modifier_group.dart';

class CatalogCategoryRef {
  const CatalogCategoryRef({required this.id, required this.name});

  final String id;
  final String name;

  factory CatalogCategoryRef.fromJson(Map<String, dynamic> json) {
    return CatalogCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.sortOrder,
    this.category,
    required this.modifierGroups,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;
  final CatalogCategoryRef? category;
  final List<CatalogModifierGroup> modifierGroups;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return CatalogProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool,
      sortOrder: json['sort_order'] as int,
      category: categoryJson != null
          ? CatalogCategoryRef.fromJson(categoryJson as Map<String, dynamic>)
          : null,
      modifierGroups: (json['modifier_groups'] as List<dynamic>)
          .map((mg) => CatalogModifierGroup.fromJson(mg as Map<String, dynamic>))
          .toList(),
    );
  }
}

