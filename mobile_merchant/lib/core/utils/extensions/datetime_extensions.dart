import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String format([String pattern = 'MMM d, y']) =>
      DateFormat(pattern).format(this);

  String get relative {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 7) return format();
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
