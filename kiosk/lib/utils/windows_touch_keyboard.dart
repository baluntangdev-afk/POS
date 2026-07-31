import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Helpers for the Windows touch-keyboard sticky-focus bug
/// ([flutter#99050](https://github.com/flutter/flutter/issues/99050)).
///
/// [WindowsScaffold] registers an invisible [ElevatedButton] focus sink.
/// Call [dismiss] after closing dialogs / leaving text fields so the OS
/// keyboard retracts and later taps don't reopen it.
class WindowsTouchKeyboard {
  WindowsTouchKeyboard._();

  static FocusNode? _focusSink;

  static set focusSink(FocusNode? node) => _focusSink = node;

  static void unregisterFocusSink(FocusNode node) {
    if (identical(_focusSink, node)) {
      _focusSink = null;
    }
  }

  /// Hide the OS touch keyboard and move focus to the non-text sink.
  static void dismiss() {
    if (!Platform.isWindows) return;
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    final sink = _focusSink;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sink != null && sink.canRequestFocus) {
        sink.requestFocus();
      }
    });
  }
}
