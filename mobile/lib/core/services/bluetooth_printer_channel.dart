import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('com.dpo.mobile/bt_printer');

/// Classic (SPP) Bluetooth connect/write/disconnect for thermal printers, replacing the
/// equivalent calls from `print_bluetooth_thermal` (that package's `pairedBluetooths` and
/// `bluetoothEnabled` are still used elsewhere and are unaffected).
///
/// print_bluetooth_thermal opens its socket via an SDP lookup for the standard SPP UUID,
/// which some printers don't expose a correct service record for — Android can then report
/// the socket as connected without the printer's print service ever binding to it, so
/// nothing prints despite a reported success. The native `BluetoothPrinterPlugin` behind
/// this channel connects directly on RFCOMM channel 1 instead, which is the channel most
/// classic-Bluetooth thermal printers actually listen on regardless of their SDP records.
abstract final class BluetoothPrinterChannel {
  static Future<bool> connect(String mac) async {
    return await _methodChannel.invokeMethod<bool>('connect', {'mac': mac}) ??
        false;
  }

  static Future<bool> writeBytes(List<int> bytes) async {
    return await _methodChannel.invokeMethod<bool>('writeBytes', bytes) ??
        false;
  }

  static Future<bool> disconnect() async {
    return await _methodChannel.invokeMethod<bool>('disconnect') ?? false;
  }
}
