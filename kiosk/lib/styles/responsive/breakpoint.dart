import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, kiosk }

/// Three distinct form factors the app targets.
///
/// Android is always treated as a tablet regardless of pixel width.
/// Windows is split between kiosk (>1440dp) and windowsTablet.
enum DeviceFormFactor { kiosk, windowsTablet, androidTablet }

class Breakpoint {
  const Breakpoint._(this.context);

  const Breakpoint.of(BuildContext context) : this._(context);

  final BuildContext context;

  DeviceType get deviceType {
    final screenSize = MediaQuery.sizeOf(context);
    return getDeviceTypeFromScreenSize(screenSize);
  }

  static DeviceType getDeviceTypeFromScreenSize(Size size) {
    final Size(:width, :height) = size;
    if (width > 1440 || height > 1440) return DeviceType.kiosk;
    // Spec: tablet = 600–1440dp (covers 7" Android tablets in portrait).
    if (width > 600) return DeviceType.tablet;
    return DeviceType.phone;
  }

  /// Returns the precise form factor, distinguishing Android from Windows tablet.
  DeviceFormFactor get formFactor {
    if (isAndroid) return DeviceFormFactor.androidTablet;
    if (deviceType == DeviceType.kiosk) return DeviceFormFactor.kiosk;
    return DeviceFormFactor.windowsTablet;
  }

  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// True on any Android device (all Android targets are tablets per spec).
  bool get isAndroidTablet => isAndroid;

  /// True on Windows when the window width is in the 600–1440dp tablet range.
  bool get isWindowsTablet => isWindows && deviceType == DeviceType.tablet;

  bool get isPhone => deviceType == DeviceType.phone;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isKiosk => deviceType == DeviceType.kiosk;
}

extension BreakpointContext on BuildContext {
  Breakpoint get breakpoint => Breakpoint.of(this);
}
