class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.productCount,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int productCount;

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
      productCount: json['product_count'] as int,
    );
  }

  factory InventoryCategory.draft() {
    return const InventoryCategory(
      id: '',
      name: '',
      description: null,
      imageUrl: null,
      sortOrder: 0,
      isActive: true,
      productCount: 0,
    );
  }

  InventoryCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    int? productCount,
  }) {
    return InventoryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
    );
  }
}
