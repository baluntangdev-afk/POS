import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, kiosk }

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
    if (width > 1440 || height > 1440) {
      return DeviceType.kiosk;
    }
    if (width > 768) {
      return DeviceType.tablet;
    }
    return DeviceType.phone;
  }

  bool get isPhone {
    return deviceType == DeviceType.phone;
  }

  bool get isTablet {
    return deviceType == DeviceType.tablet;
  }

  bool get isKiosk {
    return deviceType == DeviceType.kiosk;
  }
}

extension BreakpointContext on BuildContext {
  Breakpoint get breakpoint => Breakpoint.of(this);
}
