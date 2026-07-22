class SelectedModifierOption {
  final int optionId;
  final String name;
  final double additionalPrice;

  const SelectedModifierOption({
    required this.optionId,
    required this.name,
    required this.additionalPrice,
  });
}

class SelectedModifierGroup {
  final int groupId;
  final String groupName;
  final List<SelectedModifierOption> selected;

  const SelectedModifierGroup({
    required this.groupId,
    required this.groupName,
    required this.selected,
  });
}

class CartItem {
  final String cartId;
  final int productId;
  final String productName;
  final String groupName;
  final String? imageUrl;
  final double basePrice;
  final int quantity;
  final List<SelectedModifierGroup> modifiers;
  final String? notes;
  final double? discountAmount;

  const CartItem({
    required this.cartId,
    required this.productId,
    required this.productName,
    required this.groupName,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    required this.modifiers,
    this.notes,
    this.discountAmount,
  });

  double get modifierTotal =>
      modifiers.expand((g) => g.selected).fold(0.0, (s, o) => s + o.additionalPrice);

  double get unitPrice => basePrice + modifierTotal;
  double get lineSubtotal => unitPrice * quantity;
  double get lineTotal => lineSubtotal - (discountAmount ?? 0);

  CartItem copyWith({
    int? quantity,
    String? notes,
    double? Function()? discountAmount,
  }) =>
      CartItem(
        cartId: cartId,
        productId: productId,
        productName: productName,
        groupName: groupName,
        imageUrl: imageUrl,
        basePrice: basePrice,
        quantity: quantity ?? this.quantity,
        modifiers: modifiers,
        notes: notes ?? this.notes,
        discountAmount: discountAmount != null ? discountAmount() : this.discountAmount,
      );
}
