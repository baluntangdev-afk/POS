/// Well-known device-enrollment status values returned by
/// `POST /devices/register`. Compared as strings so an unrecognised value from
/// a newer backend degrades gracefully (treated as "not active").
class DeviceStatus {
  const DeviceStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String deactivated = 'deactivated';
}

/// Outcome of the once-per-launch device check (see
/// `MerchantNotifier.syncOnStartup`).
class DeviceStartupResult {
  const DeviceStartupResult({
    required this.status,
    required this.justApproved,
    this.reviewNote,
    this.deviceId,
    this.deviceSecret,
  });

  /// Token minting (`POST /auth/token`) failed, so `/devices/register` was
  /// never called. The existing error paths surface the failure.
  const DeviceStartupResult.tokenUnavailable()
      : status = null,
        justApproved = false,
        reviewNote = null,
        deviceId = null,
        deviceSecret = null;

  /// `null` when [tokenUnavailable]; otherwise the raw backend status string.
  final String? status;

  /// The status transitioned into `approved` on this launch (was previously
  /// stored as something other than `approved`).
  final bool justApproved;

  /// Optional admin review note, shown in the status dialog when present.
  final String? reviewNote;

  /// `device_id` from the `/devices/register` response. Set only when
  /// [isApproved]; used as the `POST /devices/token` request body.
  final String? deviceId;

  /// `device_secret` from the `/devices/register` response. Set only when
  /// [isApproved], and may still be null (a `200` duplicate match need not
  /// echo it) — the caller then falls back to the stored secret.
  final String? deviceSecret;

  bool get tokenUnavailable => status == null;

  bool get isApproved => status == DeviceStatus.approved;
}
