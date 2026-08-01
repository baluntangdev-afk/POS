import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../../../utils/decimal_rounding.dart';
import '../../../utils/tax_calculator.dart';

part 'discount.mapper.dart';

@MappableClass()
sealed class Discount with DiscountMappable {
  const Discount();

  bool get isVatExempt;

  String get code;

  Decimal calculateAmount(Decimal originalAmount);
}

@MappableClass()
class SeniorPwdDiscount extends Discount with SeniorPwdDiscountMappable {
  const SeniorPwdDiscount({required this.beneficiaryId, required this.beneficiaryName});

  @override
  bool get isVatExempt => true;

  @override
  String get code => 'Senior Citizen / PWD';

  Decimal get rate => Decimal.fromInt(20);

  final String beneficiaryId;
  final String beneficiaryName;

  @override
  Decimal calculateAmount(Decimal originalAmount) {
    return (originalAmount.vatableAmount * rate / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 2)
        .toPrecision(2);
  }
}

@MappableClass()
class PercentageDiscount extends Discount with PercentageDiscountMappable {
  const PercentageDiscount({required this.code, required this.rate});

  @override
  bool get isVatExempt => false;

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
  bool get isVatExempt => false;

  @override
  final String code;

  final Decimal amount;

  @override
  Decimal calculateAmount(Decimal originalAmount) => amount;
}
