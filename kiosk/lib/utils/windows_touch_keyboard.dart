import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

/// Full manual control over the Windows on-screen touch keyboard.
///
/// Flutter's Windows text-input plugin doesn't integrate with the Text
/// Services Framework the way native Win32/WinRT controls do, so Windows'
/// own "auto-invoke the touch keyboard" heuristic is guessing based on
/// incomplete signals and ends up showing/hiding it unpredictably —
/// including on screens with no text field at all. This is a real,
/// long-standing gap in Flutter's Windows engine
/// ([flutter#99050](https://github.com/flutter/flutter/issues/99050) and
/// several open duplicates), not something app code can perfectly patch by
/// reacting to it after the fact — closing the keyboard window each time
/// Windows decides to show it is always racing a heuristic we don't
/// control, which is why the previous close-after-the-fact attempts
/// (`ShowWindow`/`SW_HIDE`, then `SC_CLOSE`, then a polling guard) kept
/// getting undermined.
///
/// The reliable fix real touch-kiosk apps use is to stop relying on that
/// heuristic altogether: disable it, and drive the keyboard entirely from
/// our own focus state instead. [startGuard] does exactly that — it turns
/// off `EnableDesktopModeAutoInvoke` for this Windows account (so the OS
/// never shows/hides it on its own again) and shows/closes the keyboard
/// itself the instant Flutter's focus changes, so it only ever appears
/// when a real text field is focused. (This app's own [NumericKeypad] /
/// `cash_payment_dialog.dart` already avoids the OS keyboard entirely for
/// the same underlying reason — that's the same idea applied here to
/// every other text field instead of a bespoke widget per field.)
///
/// Focus alone isn't the full story, though: a touch that lands on empty
/// space — nothing focusable there — never changes Flutter's focus tree, so
/// this class's own focus listener never fires, yet Windows can still decide
/// to auto-invoke the keyboard off that same touch. That gap is invisible
/// from Dart. `windows/runner/touch_keyboard_guard.cpp` closes it natively:
/// it watches the OS-level "a window became visible" event for the touch
/// keyboard's own window and closes it on the spot whenever [_nativeChannel]
/// says no text field is focused, regardless of what triggered the show.
///
/// There's a mirror-image gap on the way down, too: tapping the keyboard's
/// own close button is native OS chrome that Flutter's focus tree never
/// finds out about, so the text field stays logically focused after the
/// keyboard is gone. Every later tap anywhere in the app then re-triggers
/// Windows' auto-invoke, and this class waves it through — as far as it
/// knows, a field is still focused, so showing is still allowed. The native
/// watcher catches this too: it also watches for the keyboard window being
/// hidden by anything other than itself and calls back over
/// [_nativeChannel] (`externallyClosed`) so [_onExternallyClosed] can drop
/// focus and resync.
class WindowsTouchKeyboard {
  WindowsTouchKeyboard._();

  /// Tells the native runner (`windows/runner/touch_keyboard_guard.cpp`)
  /// whether a real text field is currently focused. Flutter's own focus
  /// listener can only react to changes in Flutter's focus tree, but Windows
  /// invokes the touch keyboard off raw touch input on the native window —
  /// including taps that land on empty space and never touch Flutter's focus
  /// tree at all. The native side watches for the touch keyboard window
  /// itself being shown and closes it on the spot whenever this flag is
  /// false, which is the only way to reliably close that gap.
  static const MethodChannel _nativeChannel = MethodChannel('pos_kiosk/touch_keyboard');

  static FocusNode? _focusSink;
  static bool _started = false;

  static set focusSink(FocusNode? node) => _focusSink = node;

  static void unregisterFocusSink(FocusNode node) {
    if (identical(_focusSink, node)) {
      _focusSink = null;
    }
  }

  /// Disables Windows' automatic touch-keyboard invocation for this user
  /// account and starts driving the keyboard entirely from Flutter's own
  /// focus state. Call once at app startup; safe to call more than once.
  static void startGuard() {
    if (!Platform.isWindows || _started) return;
    _started = true;
    _nativeChannel.setMethodCallHandler(_handleNativeCall);
    FocusManager.instance.addListener(_syncKeyboardToFocus);
    _syncKeyboardToFocus();
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'externallyClosed') {
      _onExternallyClosed();
    }
  }

  /// The touch keyboard was closed by something other than us — almost
  /// always the user tapping its own close button. Flutter's focus tree has
  /// no idea that happened, so without this the text field stays "focused"
  /// and every later tap anywhere in the app re-opens the keyboard. Drop
  /// focus so [_syncKeyboardToFocus] sees it as unfocused from here on.
  static void _onExternallyClosed() {
    FocusManager.instance.primaryFocus?.unfocus();
    dismiss();
  }

  /// The OS touch keyboard is never wanted any more: the app draws its own
  /// keyboard ([OnScreenKeyboard]) and every text field is marked read-only on
  /// Windows so Flutter never opens a text-input connection for the OS to
  /// react to. So this no longer shows the OS keyboard under any condition —
  /// it only ever tells the native guard "never allowed" and closes anything
  /// that still manages to appear.
  ///
  /// Previously this called `_showOsTouchKeyboardWindow()` whenever a field was
  /// focused, which launched `TabTip.exe` — meaning the app itself was one of
  /// the things making the keyboard appear.
  static void _syncKeyboardToFocus() {
    _nativeChannel.invokeMethod<void>('setAllowed', false);
    _closeOsTouchKeyboardWindow();
  }

  /// Hide the OS touch keyboard and move focus to the non-text sink.
  /// [_syncKeyboardToFocus] normally beats callers to it already — this
  /// stays as a belt-and-suspenders backstop for the existing route
  /// observer / onTapOutside call sites.
  static void dismiss() {
    if (!Platform.isWindows) return;
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _nativeChannel.invokeMethod<void>('setAllowed', false);
    _closeOsTouchKeyboardWindow();
    final sink = _focusSink;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tapping straight from one field to the next (common in multi-field
      // forms) requests focus on the new field in the same frame this
      // callback was queued from — before the callback itself runs. Taking
      // the sink here regardless would yank focus straight back off that
      // field and hide the keyboard panel that had just opened for it, so
      // back off whenever a real text field already holds focus by now.
      final current = FocusManager.instance.primaryFocus;
      final currentIsTextField =
          current?.context?.findAncestorStateOfType<EditableTextState>() != null;
      if (currentIsTextField) return;

      if (sink != null && sink.canRequestFocus) {
        sink.requestFocus();
      } else {
        // No sink registered for the current screen (or it can't take
        // focus) — still drop primary focus directly so a stale-focused
        // text field doesn't keep reporting "allowed" after this.
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  /// Closes the native "IPTip_Main_Window" (TabTip.exe) via
  /// WM_SYSCOMMAND/SC_CLOSE — the technique that tells the touch keyboard
  /// to actually retract, rather than `ShowWindow(SW_HIDE)`, which only
  /// hides the window while leaving TabTip's own "should be shown" state
  /// intact so it re-paints itself on the next trigger.
  static void _closeOsTouchKeyboardWindow() {
    final classNamePtr = 'IPTip_Main_Window'.toNativeUtf16();
    try {
      final hwnd = FindWindow(classNamePtr, nullptr);
      if (hwnd != 0 && IsWindowVisible(hwnd) != 0) {
        SendMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
      }
    } finally {
      calloc.free(classNamePtr);
    }
  }
}
