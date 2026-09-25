import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../enums/sale_type.dart';
import 'discount.dart';
import 'selected_modifier.dart';
import 'selected_variant.dart';

part 'line_item.mapper.dart';

@MappableClass()
class LineItem with LineItemMappable {
  const LineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.variant,
    required this.modifiers,
    required this.categoryName,
    this.discount,
    this.itemSaleType,
    this.notes,
  });

  final String id;
  final int productId;
  final String productName;
  final String categoryName;
  final String productImage;
  final int quantity;
  final SelectedVariant variant;
  final IList<SelectedModifier> modifiers;
  final Discount? discount;
  final SaleType? itemSaleType;
  final String? notes;

  Decimal get grossAmount {
    final modifiersPrice = modifiers.fold(
      Decimal.zero,
      (total, modifier) => total + modifier.price,
    );
    return Decimal.fromInt(quantity) * (variant.price + modifiersPrice);
  }

  /// The main item and each add-on option are discounted (and rounded)
  /// separately, the same way the receipt and backend split them; a fixed
  /// amount applies once, to the main item.
  Decimal get discountAmount {
    final discount = this.discount;
    if (discount == null) return Decimal.zero;
    if (discount is FixedAmountDiscount) return discount.calculateAmount(grossAmount);

    final qty = Decimal.fromInt(quantity);
    return modifiers
        .expand((modifier) => modifier.options)
        .fold(
          discount.calculateAmount(qty * variant.price),
          (total, option) => total + discount.calculateAmount(qty * option.price),
        );
  }

  /// What the customer pays for this line: [grossAmount] − [discountAmount].
  Decimal get totalAmount => grossAmount - discountAmount;
}
