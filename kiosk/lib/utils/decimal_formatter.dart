import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

extension DecimalFormatter on Decimal {
  static final _noCommasFormat = NumberFormat('###0.##', 'en_PH');
  static final _withCommasFormat = NumberFormat('#,##0.00', 'en_PH');
  static final _pesoFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  String get noCommas {
    return _noCommasFormat.format(toDouble());
  }

  String get withCommas {
    return _withCommasFormat.format(toDouble());
  }

  String get pesoFormatted {
    return _pesoFormat.format(toDouble());
  }
}
