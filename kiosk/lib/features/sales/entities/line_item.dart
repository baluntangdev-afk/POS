import 'dart:typed_data';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../utils/tax_calculator.dart';
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
    this.discount,
  });

  final String id;
  final int productId;
  final String productName;
  final Uint8List productImage;
  final int quantity;
  final SelectedVariant variant;
  final IList<SelectedModifier> modifiers;
  final Discount? discount;

  Decimal get grossAmount {
    final modifiersPrice = modifiers.fold(
      Decimal.zero,
      (total, modifier) => total + modifier.price,
    );
    return Decimal.fromInt(quantity) * (variant.price + modifiersPrice);
  }

  bool get isVatExempt => discount?.isVatExempt ?? false;

  Decimal get discountAmount => discount?.calculateAmount(grossAmount) ?? Decimal.zero;

  Decimal get totalAmount {
    if (isVatExempt) {
      final vatable = grossAmount.vatableAmount;
      return vatable - discountAmount;
    }
    return grossAmount - discountAmount;
  }
}
