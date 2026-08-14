import 'dart:io';

import 'package:flutter/material.dart';

import 'onscreen_keyboard.dart';

/// Properties that make a raw [TextField]/[TextFormField] use the app's own
/// [OnScreenKeyboard] instead of the Windows touch keyboard.
///
/// [TextBoxFormField] applies this internally, so fields built on that wrapper
/// need nothing. These helpers are for the call sites that construct a
/// [TextField]/[TextFormField] directly with their own decoration, where
/// switching to the wrapper would mean rewriting the visuals.
///
/// Apply all four at each site:
///
/// ```dart
/// TextFormField(
///   readOnly: KeyboardSuppress.readOnly,
///   showCursor: KeyboardSuppress.showCursor,
///   keyboardType: KeyboardSuppress.type(TextInputType.text),
///   onTap: KeyboardSuppress.onTap,
///   ...
/// )
/// ```
///
/// [readOnly] is the load-bearing one — see [OnScreenKeyboard] for why it, and
/// not any amount of window-poking, is what actually keeps the OS keyboard
/// away. The others make the field usable once it's read-only: a visible caret,
/// and a tap that opens our panel.
///
/// Note there's no `canRequestFocus` here: unlike [TextBoxFormField] (which
/// derives it from its own `readOnly` prop), a raw [TextField] defaults
/// `canRequestFocus` to true regardless of `readOnly`, so a suppressed field can
/// still be focused and typed into.
abstract class KeyboardSuppress {
  /// Windows only — Android's system soft keyboard works correctly and should
  /// keep being used there.
  static final bool active = Platform.isWindows;

  static bool get readOnly => active;

  /// Read-only fields hide the caret by default; a field being typed into needs
  /// it visible. Null on Android so [TextField]'s own default applies.
  static bool? get showCursor => active ? true : null;

  /// Belt-and-braces alongside [readOnly]: signals "no system keyboard" even
  /// where an input connection does get opened (Android, web).
  static TextInputType? type(TextInputType? original) =>
      active ? TextInputType.none : original;

  static VoidCallback? get onTap => active ? OnScreenKeyboard.show : null;
}
