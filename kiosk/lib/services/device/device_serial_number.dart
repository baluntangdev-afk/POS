import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The physical Windows device's BIOS/motherboard serial number, printed on receipts as "S/N".
/// Cached for the lifetime of the app since it never changes without a hardware swap.
final deviceSerialNumberProvider = FutureProvider<String?>((ref) async {
  if (!Platform.isWindows) return null;
  try {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      '(Get-CimInstance -ClassName Win32_BIOS).SerialNumber',
    ]);
    final serial = (result.stdout as String).trim();
    return serial.isEmpty ? null : serial;
  } catch (_) {
    return null;
  }
}, name: 'deviceSerialNumberProvider');
