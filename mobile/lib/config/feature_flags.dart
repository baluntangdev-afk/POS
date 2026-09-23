/// When true, the app skips the merchant-device flow entirely: no
/// `POST /devices/register` on store save or login, no `/devices/token` mint,
/// and the live-orders socket connects without waiting for device approval
/// (and without a device bearer on the handshake).
///
/// Off by default. Enable per build/run with:
/// `flutter run --dart-define=SKIP_DEVICE_REGISTRATION=true`
const kSkipDeviceRegistration = bool.fromEnvironment(
  'SKIP_DEVICE_REGISTRATION',
);
