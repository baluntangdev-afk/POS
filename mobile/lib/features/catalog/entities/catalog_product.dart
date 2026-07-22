class CatalogGroup {
  final int id;
  final String name;
  final int productCount;
  const CatalogGroup({required this.id, required this.name, required this.productCount});
}

class CatalogProduct {
  final int id;
  final int groupId;
  final String name;
  final double price;
  final bool isAvailable;
  final String? imageUrl;
  final int sortOrder;
  final CatalogGroup? group;

  const CatalogProduct({
    required this.id,
    required this.groupId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    required this.sortOrder,
    this.group,
  });

  CatalogProduct copyWith({bool? isAvailable}) => CatalogProduct(
        id: id,
        groupId: groupId,
        name: name,
        price: price,
        isAvailable: isAvailable ?? this.isAvailable,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        group: group,
      );
}
