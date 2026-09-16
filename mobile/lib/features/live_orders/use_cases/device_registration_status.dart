/// Normalised device-registration status buckets. `rejected` collapses into
/// [DeviceRegistrationStatus.deactivated]; anything unrecognised (or null) is
/// [DeviceRegistrationStatus.unknown].
enum DeviceRegistrationStatus { pending, approved, deactivated, unknown }

DeviceRegistrationStatus deviceRegistrationStatusFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pending':
      return DeviceRegistrationStatus.pending;
    case 'approved':
      return DeviceRegistrationStatus.approved;
    case 'deactivated':
    case 'rejected':
      return DeviceRegistrationStatus.deactivated;
    default:
      return DeviceRegistrationStatus.unknown;
  }
}
