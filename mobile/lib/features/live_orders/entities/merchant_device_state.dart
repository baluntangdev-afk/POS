import '../../../data/backend_api/schemas/device_registration_dto.dart';
import '../use_cases/device_registration_error.dart';

/// Local view of this device's registration with the backend.
///
/// [deviceId] is hydrated from secure storage on startup; [registration] is
/// only populated after a live `POST /devices/register` call this session.
class MerchantDeviceState {
  const MerchantDeviceState({
    this.deviceId,
    this.registeredStoreId,
    this.registration,
    this.persistedStatus,
    this.persistedMerchantName,
    this.isRegistering = false,
    this.error,
    this.errorMessage,
  });

  /// The `device_id` persisted in secure storage, if the device has been
  /// registered before.
  final String? deviceId;

  /// The `store_id` the persisted registration belongs to. Used to decide
  /// whether a store-id change requires re-registration.
  final String? registeredStoreId;

  /// The full record from the most recent registration call this session.
  final DeviceRegistrationDto? registration;

  /// The `status` from the last register response, rehydrated from secure
  /// storage on startup. Used when [registration] is null this session.
  final String? persistedStatus;

  /// The `merchant_name` from the last register response, rehydrated from
  /// secure storage on startup.
  final String? persistedMerchantName;

  /// True while a registration request is in flight.
  final bool isRegistering;

  /// Reason the last registration attempt failed, if it did. Cleared when a
  /// new attempt starts or one succeeds.
  final DeviceRegistrationError? error;

  /// User-facing text for [error] — the backend's own `message` from the
  /// failed response when it sent one, otherwise the mapped copy for [error].
  /// `null` whenever [error] is `null`.
  final String? errorMessage;

  bool get isRegistered => deviceId != null;

  /// Review state from the last registration response, falling back to the
  /// value persisted from a previous session.
  String? get status => registration?.status ?? persistedStatus;

  /// Human-readable merchant name from the last registration response,
  /// falling back to the persisted value.
  String? get merchantName =>
      registration?.merchantName ?? persistedMerchantName;

  MerchantDeviceState copyWith({
    String? deviceId,
    String? registeredStoreId,
    DeviceRegistrationDto? registration,
    String? persistedStatus,
    String? persistedMerchantName,
    bool? isRegistering,
    DeviceRegistrationError? error,
    String? errorMessage,
  }) {
    return MerchantDeviceState(
      deviceId: deviceId ?? this.deviceId,
      registeredStoreId: registeredStoreId ?? this.registeredStoreId,
      registration: registration ?? this.registration,
      persistedStatus: persistedStatus ?? this.persistedStatus,
      persistedMerchantName:
          persistedMerchantName ?? this.persistedMerchantName,
      isRegistering: isRegistering ?? this.isRegistering,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
