import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

/// Detects whether a real, physical keyboard — USB, PS/2, or a 2-in-1's
/// built-in keyboard — is currently attached to this Windows machine.
///
/// [TextBoxFormField] uses this to decide, per field, whether typing can go
/// straight through Flutter's normal text-input connection (physical
/// keyboard attached — the field behaves like an ordinary desktop text
/// field) or whether it must fall back to [OnScreenKeyboard] driving input
/// entirely on its own (touch-only — see that class's docs for why the field
/// is marked `readOnly` in that case). The app's own on-screen keyboard
/// panel stays available either way; this only controls whether the field
/// also accepts real key presses.
///
/// ## How detection works
///
/// Windows doesn't hand Flutter a "keyboard plugged in" event, and the
/// obvious-looking `GetSystemMetrics(SM_CONVERTIBLESLATEMODE)` signal (what
/// Windows itself uses to decide whether to auto-invoke the touch keyboard)
/// is ambiguous on a plain desktop kiosk PC: on chassis that don't support
/// the convertible/slate concept at all, it returns 0 — indistinguishable
/// from "no keyboard attached". So this instead enumerates raw input
/// devices via `GetRawInputDeviceList`, the same enumeration the input stack
/// itself uses, and checks for a device of type `RIM_TYPEKEYBOARD`.
///
/// One device is filtered out: Windows always reports a phantom "Terminal
/// Server Keyboard" (device name containing `RDP_KBD`) for the RDP
/// redirector, present even with nothing physically attached and even
/// outside of an actual remote session. Without filtering it, every machine
/// would look like it has a keyboard.
///
/// ## Why polling instead of an event
///
/// The precise live signal for this is `WM_INPUT_DEVICE_CHANGE`, delivered
/// only to a window that registered for raw input device notifications —
/// which would mean hooking Flutter's native message pump in
/// `windows/runner`, mirroring what `touch_keyboard_guard.cpp` already does
/// for the OS touch keyboard window. That's a bigger native surface than
/// this warrants; polling `GetRawInputDeviceList` on an interval gets the
/// same practical result (a keyboard plugged/unplugged mid-session is
/// noticed within one interval) without it.
class PhysicalKeyboardDetector {
  PhysicalKeyboardDetector._();

  /// Whether a real keyboard is currently attached. Starts `false`
  /// (touch-only assumed) until the first poll completes: a spurious
  /// on-screen keyboard is a minor annoyance, while wrongly assuming a
  /// keyboard is present would strand a touch-only kiosk with no way to
  /// type.
  static final ValueNotifier<bool> attached = ValueNotifier<bool>(false);

  static Timer? _timer;

  /// Starts polling. Call once at app startup; safe to call more than once.
  static void startPolling({Duration interval = const Duration(seconds: 3)}) {
    if (!Platform.isWindows || _timer != null) return;
    _poll();
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  static void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  static void _poll() {
    try {
      attached.value = _detect();
    } on Object {
      // Leave the last known value in place rather than flipping fields
      // into an inconsistent state over a transient FFI/OS failure.
    }
  }

  /// Enumerates raw input devices and returns whether any is a real
  /// (non-phantom) keyboard. On any error mid-enumeration this fails open
  /// (returns `true`) — misreporting "keyboard attached" merely leaves a
  /// field behaving like a normal text field, whereas misreporting
  /// "touch-only" on a machine that does have a keyboard would silently
  /// break typing in it.
  static bool _detect() {
    final countPtr = calloc<Uint32>();
    try {
      final structSize = sizeOf<RAWINPUTDEVICELIST>();
      var status = GetRawInputDeviceList(nullptr, countPtr, structSize);
      if (status == 0xFFFFFFFF) return true;

      final count = countPtr.value;
      if (count == 0) return false;

      final listPtr = calloc<RAWINPUTDEVICELIST>(count);
      try {
        status = GetRawInputDeviceList(listPtr, countPtr, structSize);
        if (status == 0xFFFFFFFF) return true;

        for (var i = 0; i < status; i++) {
          final device = listPtr[i];
          if (device.dwType == RIM_TYPEKEYBOARD && !_isPhantomKeyboard(device.hDevice)) {
            return true;
          }
        }
        return false;
      } finally {
        calloc.free(listPtr);
      }
    } finally {
      calloc.free(countPtr);
    }
  }

  static bool _isPhantomKeyboard(int hDevice) {
    final sizePtr = calloc<Uint32>();
    try {
      var status = GetRawInputDeviceInfo(hDevice, RIDI_DEVICENAME, nullptr, sizePtr);
      if (status == 0xFFFFFFFF) return false;

      // RIDI_DEVICENAME is the one GetRawInputDeviceInfo command whose size
      // is reported in characters rather than bytes.
      final nameLength = sizePtr.value;
      if (nameLength == 0) return false;

      final namePtr = calloc<Uint16>(nameLength);
      try {
        status = GetRawInputDeviceInfo(hDevice, RIDI_DEVICENAME, namePtr.cast(), sizePtr);
        if (status == 0xFFFFFFFF) return false;

        final name = namePtr.cast<Utf16>().toDartString().toUpperCase();
        return name.contains('RDP_KBD');
      } finally {
        calloc.free(namePtr);
      }
    } finally {
      calloc.free(sizePtr);
    }
  }
}
