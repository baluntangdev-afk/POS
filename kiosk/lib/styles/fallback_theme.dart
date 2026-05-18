import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'color_set.dart';

/// Provides fallback theme for iOS.
///
/// This app's themes do not follow Material design.
/// Yet, fallback themes should be provided to set default colors to widgets
/// which color properties cannot be explicitly set, particularly on iOS.
///
/// For example, [TextSelectionThemeData.selectionHandleColor].
final fallbackTheme = ThemeData(
  useMaterial3: true,
  cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: ColorSet.primary),
);
