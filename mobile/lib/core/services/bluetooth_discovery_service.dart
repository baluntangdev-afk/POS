import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

const _methodChannel = MethodChannel('com.dpo.mobile/bt_discovery');
const _eventChannel = EventChannel('com.dpo.mobile/bt_discovery_events');

// Android 12 (API 31) introduced BLUETOOTH_SCAN/BLUETOOTH_CONNECT, which — with the
// `neverForLocation` flag this app declares on BLUETOOTH_SCAN in AndroidManifest.xml —
// need no location permission or Location Services at all. Below API 31, classic
// Bluetooth discovery still relies on ACCESS_FINE_LOCATION + Location Services being on,
// a long-standing OS quirk unrelated to what this feature actually uses location for
// (nothing — it's purely an OS discovery-API restriction).
const _androidBluetoothPermissionSdk = 31;

enum BluetoothPermissionState { granted, denied, permanentlyDenied }

sealed class BluetoothDiscoveryEvent {
  const BluetoothDiscoveryEvent();
}

class DeviceFoundEvent extends BluetoothDiscoveryEvent {
  const DeviceFoundEvent({required this.name, required this.mac});
  final String name;
  final String mac;
}

class DiscoveryFinishedEvent extends BluetoothDiscoveryEvent {
  const DiscoveryFinishedEvent();
}

class BondStateChangedEvent extends BluetoothDiscoveryEvent {
  const BondStateChangedEvent({required this.mac, required this.bonded});
  final String mac;
  final bool bonded;
}

/// Live discovery, pairing, and the Bluetooth-enable prompt for classic (SPP) Bluetooth
/// thermal printers. Permission/location-service checks go through `permission_handler`;
/// discovery and pairing go through the native `BluetoothDiscoveryPlugin` channel, since
/// no maintained package covers classic-Bluetooth discovery/pairing. `print_bluetooth_thermal`
/// is untouched and still handles listing paired devices, connecting, and printing.
abstract final class BluetoothDiscoveryService {
  static int? _sdkIntCache;
  static Stream<BluetoothDiscoveryEvent>? _eventStream;

  static Future<int> _androidSdkInt() async {
    return _sdkIntCache ??= await _methodChannel.invokeMethod<int>('sdkInt') ?? 0;
  }

  static Future<bool> isBluetoothEnabled() => PrintBluetoothThermal.bluetoothEnabled;

  /// Fires the system "Turn on Bluetooth?" dialog. This intent has no result callback,
  /// so callers should re-check [isBluetoothEnabled] when the app resumes.
  static Future<void> requestEnableBluetooth() async {
    const intent = AndroidIntent(
      action: 'android.bluetooth.adapter.action.REQUEST_ENABLE',
    );
    await intent.launch();
  }

  /// Whether discovery on this device needs Location Services on (pre-Android-12 only).
  static Future<bool> needsLocationServices() async {
    return await _androidSdkInt() < _androidBluetoothPermissionSdk;
  }

  static Future<bool> isLocationServicesEnabled() {
    return Permission.locationWhenInUse.serviceStatus.isEnabled;
  }

  static Future<BluetoothPermissionState> checkPermissions() async {
    final permissions = await _requiredPermissions();
    final statuses = await Future.wait(permissions.map((p) => p.status));
    return _resolve(statuses);
  }

  static Future<BluetoothPermissionState> requestPermissions() async {
    final permissions = await _requiredPermissions();
    final statuses = await permissions.request();
    return _resolve(statuses.values.toList());
  }

  static Future<List<Permission>> _requiredPermissions() async {
    final sdkInt = await _androidSdkInt();
    return [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      if (sdkInt < _androidBluetoothPermissionSdk) Permission.locationWhenInUse,
    ];
  }

  static BluetoothPermissionState _resolve(List<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted)) return BluetoothPermissionState.granted;
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return BluetoothPermissionState.permanentlyDenied;
    }
    return BluetoothPermissionState.denied;
  }

  static Future<bool> openAppSettingsPage() => openAppSettings();

  /// Opens the system Location Settings screen (not this app's settings) — used when
  /// pre-Android-12 discovery is blocked by Location Services being off system-wide.
  static Future<void> openLocationSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  static Stream<BluetoothDiscoveryEvent> get _events {
    return _eventStream ??= _eventChannel.receiveBroadcastStream().map(_decodeEvent);
  }

  static BluetoothDiscoveryEvent _decodeEvent(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    return switch (map['type']) {
      'deviceFound' => DeviceFoundEvent(
        name: map['name'] as String,
        mac: map['mac'] as String,
      ),
      'bondStateChanged' => BondStateChangedEvent(
        mac: map['mac'] as String,
        bonded: map['bonded'] as bool,
      ),
      _ => const DiscoveryFinishedEvent(),
    };
  }

  /// Starts native discovery and returns the shared event stream. Callers must have
  /// already confirmed Bluetooth is on and permissions are granted — this call does not
  /// re-check either, so failures surface as a plain "no devices found" rather than a
  /// specific error.
  static Stream<BluetoothDiscoveryEvent> startDiscovery() {
    final stream = _events;
    unawaited(_methodChannel.invokeMethod<bool>('startDiscovery'));
    return stream;
  }

  static Future<void> stopDiscovery() async {
    await _methodChannel.invokeMethod<bool>('stopDiscovery');
  }

  /// Initiates pairing with [mac] and waits for the resulting bond-state change (Android
  /// pairing is asynchronous — a system PIN/confirm dialog may appear in between). Returns
  /// false if pairing fails, is rejected, or doesn't resolve within [timeout].
  static Future<bool> pairAndWait(
    String mac, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final completer = Completer<bool>();
    final subscription = _events.listen((event) {
      if (event is BondStateChangedEvent &&
          event.mac == mac &&
          !completer.isCompleted) {
        completer.complete(event.bonded);
      }
    });

    final started =
        await _methodChannel.invokeMethod<bool>('pairDevice', {'mac': mac}) ??
        false;
    if (!started) {
      await subscription.cancel();
      return false;
    }

    final result = await completer.future.timeout(timeout, onTimeout: () => false);
    await subscription.cancel();
    return result;
  }
}
