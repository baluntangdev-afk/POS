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

/// Shortens a full order id (e.g. `ORD_D95A44C1-85CC-494E-B93D-25680D4CF6A1`)
/// down to a display-friendly tail like `#4CF6A1` — enough to eyeball-match
/// against a printed receipt without a wall of hex eating the whole card
/// width. The full id is still shown wherever it matters (order details).
String formatOrderId(String id) {
  final digits = id.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  final tail = digits.length > 6 ? digits.substring(digits.length - 6) : digits;
  return '#${tail.toUpperCase()}';
}

String capitalizeWords(String value) {
  if (value.isEmpty) return value;
  return value.split(RegExp(r'[_\s]+')).map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
