import 'package:intl/intl.dart';

// No locale arg: DateFormat needs `initializeDateFormatting()` for anything
// other than the built-in default (en_US), which this app never calls.
// NumberFormat below doesn't have that requirement, so 'en_PH' is fine there.
final _timeFormat = DateFormat.jm();
final _pesoFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
final _genericAmountFormat = NumberFormat('#,##0.00', 'en_PH');

String formatOrderTime(DateTime dateTime) => _timeFormat.format(dateTime.toLocal());

/// Formats [amount] for the given order [currency] code. Assumes PHP when
/// unset or explicitly "PHP" (the only currency this kiosk has shipped
/// against so far); any other code falls back to `<CODE> <amount>` rather
/// than guessing a symbol.
String formatOrderMoney(num amount, String? currency) {
  if (currency == null || currency.toUpperCase() == 'PHP') {
    return _pesoFormat.format(amount);
  }
  return '${currency.toUpperCase()} ${_genericAmountFormat.format(amount)}';
}

String capitalizeWords(String value) {
  if (value.isEmpty) return value;
  return value.split(RegExp(r'[_\s]+')).map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
