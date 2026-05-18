import 'package:decimal/decimal.dart';

extension TaxCalculator on Decimal {
  Decimal get vatableAmount {
    final netAmount = this / Decimal.parse('1.12');
    final netAmountInCents = (netAmount.toDouble() * 100).round();
    final roundedAmount = Decimal.fromInt(netAmountInCents) / Decimal.fromInt(100);
    return roundedAmount.toDecimal();
  }

  Decimal get vatAmount {
    return this - vatableAmount;
  }
}
