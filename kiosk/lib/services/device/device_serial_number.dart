import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Placeholder values OEMs leave in BIOS/board serial fields when they never
/// programmed a real one (case-insensitive, trailing punctuation ignored).
const _placeholderSerials = {
  'default string',
  'to be filled by o.e.m.',
  'system serial number',
  'not specified',
  'none',
  'invalid',
  'n/a',
  '0123456789',
  'serial number',
  '00000000',
};

bool _isPlaceholder(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[!.]+$'), '');
  return normalized.isEmpty || _placeholderSerials.contains(normalized);
}

Future<String?> _runPowershell(String command) async {
  try {
    final result = await Process.run('powershell', ['-NoProfile', '-Command', command]);
    final output = (result.stdout as String).trim();
    return output.isEmpty ? null : output;
  } catch (_) {
    return null;
  }
}

/// The physical Windows device's hardware identifier, printed on receipts as "S/N".
/// Cached for the lifetime of the app since it never changes without a hardware swap.
///
/// Tries the BIOS serial first, then the motherboard serial, then the SMBIOS UUID —
/// some OEMs never program a real BIOS/board serial and leave a placeholder string
/// like "Default string" or "To Be Filled By O.E.M." instead. Returns null (hiding
/// the S/N field) if every source is empty or a known placeholder.
final deviceSerialNumberProvider = FutureProvider<String?>((ref) async {
  if (!Platform.isWindows) return null;

  final biosSerial = await _runPowershell('(Get-CimInstance -ClassName Win32_BIOS).SerialNumber');
  if (biosSerial != null && !_isPlaceholder(biosSerial)) return biosSerial;

  final boardSerial = await _runPowershell(
    '(Get-CimInstance -ClassName Win32_BaseBoard).SerialNumber',
  );
  if (boardSerial != null && !_isPlaceholder(boardSerial)) return boardSerial;

  final uuid = await _runPowershell('(Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID');
  if (uuid != null && !_isPlaceholder(uuid)) return uuid;

  return null;
}, name: 'deviceSerialNumberProvider');
