import 'package:dart_mappable/dart_mappable.dart';

part 'device_registration_dto.mapper.dart';

/// Response of the webhook-receiver's `POST /devices/register`.
///
/// The endpoint has two success shapes and this DTO covers both:
///  * **202** (new enrollment recorded / replayed for a known
///    `Idempotency-Key`) — carries [deviceSecret] but none of the review
///    metadata.
///  * **200** (a pending device already exists, matched on `install_id` /
///    hardware fingerprint) — carries [merchantId] / [requestedAt] etc. but
///    no [deviceSecret] (the original was shown only once).
///
/// Only [deviceId] and [status] are guaranteed present; everything else is
/// nullable.
@MappableClass(caseStyle: CaseStyle.snakeCase)
class DeviceRegistrationDto with DeviceRegistrationDtoMappable {
  const DeviceRegistrationDto({
    required this.deviceId,
    required this.status,
    this.deviceSecret,
    this.merchantId,
    this.requestedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  /// Opaque device identifier issued by the backend (`dev_...`).
  final String deviceId;

  /// Review state: `pending`, `approved`, `rejected`, ... — kept as a raw
  /// string for forward compatibility with unrecognised states.
  final String status;

  /// Returned **once**, only on the 202 response. Must be persisted
  /// immediately — it is never shown again.
  final String? deviceSecret;

  final String? merchantId;

  final DateTime? requestedAt;

  /// Set once a merchant reviewer acts on the request.
  final DateTime? reviewedAt;

  /// Optional note left by the reviewer.
  final String? reviewNote;

  static const fromJson = DeviceRegistrationDtoMapper.fromJson;
}
