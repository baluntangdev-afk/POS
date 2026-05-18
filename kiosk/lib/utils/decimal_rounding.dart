import 'package:decimal/decimal.dart';

extension DecimalRounding on Decimal {
  Decimal toPrecision(int places) {
    final modifier = Decimal.fromInt(10).pow(places).toDecimal();
    final shifted = this * modifier;
    final roundedBigInt = shifted.round();
    return (roundedBigInt / modifier).toDecimal();
  }
}
