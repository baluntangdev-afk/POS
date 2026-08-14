import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../../../data/backend_api/mappers/image_url_mapper.dart';

/// `dart_mappable` has no built-in support for [Decimal] or [Uint8List] —
/// both need a custom [SimpleMapper] registered globally before encoding or
/// decoding any customer-display entity that carries one. Shared by every
/// customer_display entity file so the registration only happens once.
class _DecimalMapper extends SimpleMapper<Decimal> {
  const _DecimalMapper();

  @override
  Decimal decode(Object value) => Decimal.parse(value as String);

  @override
  Object encode(Decimal self) => self.toString();
}

bool _customerDisplayMappersRegistered = false;

void ensureCustomerDisplayMappersRegistered() {
  if (_customerDisplayMappersRegistered) return;
  _customerDisplayMappersRegistered = true;
  MapperContainer.globals.use(const _DecimalMapper());
  // Reuses the same base64 Uint8List codec already used for
  // ProductGroupDto.imageUrl elsewhere in this app.
  MapperContainer.globals.use(const ImageUrlMapper());
}

/// `desktop_multi_window`'s IPC round-trips `invokeMethod` arguments through
/// Flutter's `StandardMethodCodec`. That codec decodes *nested* maps/lists as
/// `Map<Object?, Object?>`/`List<Object?>` — not `Map<String, dynamic>` — no
/// matter what was actually sent; only the outermost argument is directly
/// usable. `dart_mappable`'s decoder requires `Map<String, dynamic>` at every
/// nesting level, so every customer-display decode entrypoint normalizes the
/// whole structure through this first. Verified against a real production
/// failure (`MapperException`: "Expected a value of type
/// `Map<String, dynamic>`, but got type `_Map<Object?, Object?>`"), not
/// assumed — calling `toTransportMap()`/`fromTransportMap()` back-to-back in
/// the same isolate (as the earlier unit tests did) never exercises this
/// because it never actually crosses the channel.
Map<String, dynamic> normalizeChannelMap(Object? value) {
  return _deepConvert(value)! as Map<String, dynamic>;
}

Object? _deepConvert(Object? value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), _deepConvert(val)));
  }
  if (value is List) {
    return value.map(_deepConvert).toList();
  }
  return value;
}
