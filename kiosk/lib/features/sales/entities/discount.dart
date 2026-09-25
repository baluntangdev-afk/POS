import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../../../utils/decimal_rounding.dart';

part 'discount.mapper.dart';

@MappableClass()
sealed class Discount with DiscountMappable {
  const Discount();

  String get code;

  Decimal calculateAmount(Decimal originalAmount);
}

@MappableClass()
/// Senior Citizen / PWD: a flat 20% off the full (VAT-inclusive) price. It is
/// *not* VAT-exempt — VAT is carried by what the customer pays, e.g.
/// ₱112.00 − ₱22.40 = ₱89.60 (VATable ₱80.00 + VAT ₱9.60).
class SeniorPwdDiscount extends Discount with SeniorPwdDiscountMappable {
  const SeniorPwdDiscount({required this.beneficiaryId, required this.beneficiaryName});

  @override
  String get code => 'Senior Citizen / PWD';

  Decimal get rate => Decimal.fromInt(20);

  final String beneficiaryId;
  final String beneficiaryName;

  @override
  Decimal calculateAmount(Decimal originalAmount) {
    return (originalAmount * rate / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toPrecision(2);
  }
}

@MappableClass()
class PercentageDiscount extends Discount with PercentageDiscountMappable {
  const PercentageDiscount({required this.code, required this.rate});

  @override
  final String code;

  final Decimal rate;

  @override
  Decimal calculateAmount(Decimal originalAmount) {
    return (originalAmount * rate / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toPrecision(2);
  }
}

@MappableClass()
class FixedAmountDiscount extends Discount with FixedAmountDiscountMappable {
  const FixedAmountDiscount({required this.code, required this.amount});

  @override
  final String code;

  final Decimal amount;

  @override
  Decimal calculateAmount(Decimal originalAmount) => amount;
}
