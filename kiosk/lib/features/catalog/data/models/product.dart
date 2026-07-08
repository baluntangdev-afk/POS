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

class CatalogProductVariant {
  const CatalogProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.isDefault,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final bool isActive;

  factory CatalogProductVariant.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['displayPrice'];
    return CatalogProductVariant(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: double.parse(rawPrice.toString()),
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  CatalogProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
    bool? isActive,
  }) {
    return CatalogProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
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
    this.variants = const [],
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
  final List<CatalogProductVariant> variants;

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

  factory CatalogProduct.draft() {
    return const CatalogProduct(
      id: '',
      name: '',
      description: null,
      price: 0,
      imageUrl: null,
      isAvailable: true,
      sortOrder: 0,
      category: null,
      modifierGroups: [],
      variants: [],
    );
  }

  CatalogProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    int? sortOrder,
    CatalogCategoryRef? category,
    List<CatalogModifierGroup>? modifierGroups,
    List<CatalogProductVariant>? variants,
  }) {
    return CatalogProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      category: category ?? this.category,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      variants: variants ?? this.variants,
    );
  }
}
