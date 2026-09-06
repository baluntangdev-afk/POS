class OrderItemDto {
  const OrderItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double price;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) => OrderItemDto(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        price: (json['price'] as num).toDouble(),
      );
}
