import 'package:dart_mappable/dart_mappable.dart';

class DateTimeWithOffsetMapper extends SimpleMapper<DateTime> {
  const DateTimeWithOffsetMapper();

  @override
  DateTime decode(Object value) {
    if (value is String) {
      return DateTime.parse(value);
    }
    throw MapperException.unexpectedType(
      value.runtimeType,
      'String (ISO 8601 subset/RFC 3339 format)',
    );
  }

  @override
  String encode(DateTime self) {
    if (self.isUtc) return self.toIso8601String();

    final offset = self.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';

    return '${self.toIso8601String()}$sign$hours:$minutes';
  }
}
