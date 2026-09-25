import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_env.dart';

const _prefsKey = 'orders_server_base_url';

/// Reads the on-device override saved from the login screen's server
/// settings dialog, or `null` when none has been saved. Called once in
/// `main()` (and in background workers) to seed
/// [savedOrdersServerUrlProvider] before any Dio client is built.
Future<String?> loadSavedOrdersServerUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefsKey)?.trim();
  return (saved == null || saved.isEmpty) ? null : saved;
}

/// Seed for [ordersServerUrlProvider]; overridden with
/// [loadSavedOrdersServerUrl]'s result. `null` falls back to `.env`.
final savedOrdersServerUrlProvider = Provider<String?>((_) => null);

/// The orders-events server base URL every client should use: the address
/// saved on the device, else `ORDERS_EVENTS_API_BASE_URL` from `.env` (which
/// is compiled in and can't be written at runtime).
final ordersServerUrlProvider =
    NotifierProvider<OrdersServerUrlNotifier, String>(
      OrdersServerUrlNotifier.new,
      name: 'ordersServerUrlProvider',
    );

class OrdersServerUrlNotifier extends Notifier<String> {
  @override
  String build() =>
      ref.watch(savedOrdersServerUrlProvider) ??
      ref.watch(appEnvProvider).ordersEventsApiBaseUrl;

  String get _defaultUrl => ref.read(appEnvProvider).ordersEventsApiBaseUrl;

  /// Persists [url] and swaps it in; watchers (API clients, the live feed)
  /// rebuild against it. Saving the `.env` default clears the override.
  Future<void> save(String url) async {
    final trimmed = url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed == _defaultUrl) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, trimmed);
    }
    state = trimmed;
  }
}
