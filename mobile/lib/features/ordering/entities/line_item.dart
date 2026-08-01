import 'discount.dart';

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

class LineItem {
  final String id;
  final int productId;
  final String productName;
  final String groupName;
  final String? imageUrl;
  final double basePrice;
  final int quantity;
  final List<SelectedModifierGroup> modifiers;
  final String? notes;
  final Discount? discount;
  final String variantName;

  const LineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.groupName,
    required this.imageUrl,
    required this.basePrice,
    required this.quantity,
    required this.modifiers,
    this.notes,
    this.discount,
    this.variantName = '',
  });

  double get modifierTotal =>
      modifiers.expand((g) => g.selected).fold(0.0, (s, o) => s + o.additionalPrice);

  double get unitPrice => basePrice + modifierTotal;
  double get lineSubtotal => unitPrice * quantity;
  double get discountAmount => discount?.calculateAmount(lineSubtotal) ?? 0;

  bool get isVatExempt => discount?.isVatExempt ?? false;
  double get vatExclusiveAmount => lineSubtotal.vatExclusiveAmount;
  double get vatAmount => isVatExempt ? 0 : lineSubtotal.vatAmount;

  double get lineTotal => vatExclusiveAmount + vatAmount - discountAmount;

  LineItem copyWith({
    String? id,
    int? quantity,
    String? notes,
    Discount? Function()? discount,
  }) =>
      LineItem(
        id: id ?? this.id,
        productId: productId,
        productName: productName,
        groupName: groupName,
        imageUrl: imageUrl,
        basePrice: basePrice,
        quantity: quantity ?? this.quantity,
        modifiers: modifiers,
        notes: notes ?? this.notes,
        discount: discount != null ? discount() : this.discount,
        variantName: variantName,
      );
}
