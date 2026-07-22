import 'cart_item.dart';

class OrderGroup {
  final int id;
  final String name;
  const OrderGroup({required this.id, required this.name});
}

class OrderProduct {
  final int id;
  final int groupId;
  final String name;
  final double price;
  final bool isAvailable;
  final String? imageUrl;

  const OrderProduct({
    required this.id,
    required this.groupId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
  });
}

class CartState {
  final List<OrderGroup> groups;
  final List<OrderProduct> allProducts;
  final int? selectedGroupId;
  final List<CartItem> items;
  final String saleType;
  final double orderDiscount;

  const CartState({
    required this.groups,
    required this.allProducts,
    this.selectedGroupId,
    this.items = const [],
    this.saleType = 'dine_in',
    this.orderDiscount = 0,
  });

  List<OrderProduct> get filteredProducts {
    var list = allProducts.where((p) => p.isAvailable).toList();
    if (selectedGroupId != null) {
      list = list.where((p) => p.groupId == selectedGroupId).toList();
    }
    return list;
  }

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);
  double get itemDiscounts => items.fold(0.0, (s, i) => s + (i.discountAmount ?? 0));
  double get totalDiscount => itemDiscounts + orderDiscount;
  double get total => subtotal - totalDiscount;
  int get totalQuantity => items.fold(0, (s, i) => s + i.quantity);

  CartState copyWith({
    List<OrderGroup>? groups,
    List<OrderProduct>? allProducts,
    int? Function()? selectedGroupId,
    List<CartItem>? items,
    String? saleType,
    double? orderDiscount,
  }) =>
      CartState(
        groups: groups ?? this.groups,
        allProducts: allProducts ?? this.allProducts,
        selectedGroupId:
            selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
        items: items ?? this.items,
        saleType: saleType ?? this.saleType,
        orderDiscount: orderDiscount ?? this.orderDiscount,
      );
}
