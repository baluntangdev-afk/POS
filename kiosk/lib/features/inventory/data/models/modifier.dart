class InventoryModifier {
  const InventoryModifier({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isAvailable,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final double priceAdjustment;
  final bool isAvailable;
  final int sortOrder;

  factory InventoryModifier.fromJson(Map<String, dynamic> json) {
    return InventoryModifier(
      id: json['id'] as String,
      name: json['name'] as String,
      priceAdjustment: double.parse(json['price_adjustment'].toString()),
      isAvailable: json['is_available'] as bool,
      sortOrder: json['sort_order'] as int,
    );
  }
}
