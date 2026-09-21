import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with an instance from [AppClock.load] once the
/// cached offset (if any) has been read from disk.
final appClockProvider = Provider<AppClock>((ref) {
  throw UnimplementedError('appClockProvider must be overridden in main()');
});

/// Corrects for a device clock that's been set to the wrong date/time.
///
/// A device's hardware clock ticks at the correct *rate* even when it's been
/// set to the wrong moment, so a fixed offset captured against the backend's
/// clock (see the `date` response header read in `api_clients.dart`) stays
/// accurate for as long as nobody manually changes the date again — no need
/// to track elapsed/monotonic time separately. [isVerified] is false until
/// that offset has been captured at least once (e.g. brand-new offline
/// device), so callers can warn the cashier instead of silently trusting an
/// unverified device clock.
class AppClock {
  AppClock._(this._offset);

  Duration? _offset;

  static const _prefsKey = 'app_clock_offset_millis';

  static Future<AppClock> load() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_prefsKey);
    return AppClock._(millis == null ? null : Duration(milliseconds: millis));
  }

  bool get isVerified => _offset != null;

  DateTime now() {
    final offset = _offset;
    return offset == null ? DateTime.now() : DateTime.now().add(offset);
  }

  Future<void> recordServerTime(DateTime serverTime) async {
    final offset = serverTime.difference(DateTime.now());
    _offset = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, offset.inMilliseconds);
  }
}
