import 'package:flutter/material.dart';

import 'breakpoint.dart';

class ResponsiveValue {
  const ResponsiveValue._(this.context);

  const ResponsiveValue.of(BuildContext context) : this._(context);

  final BuildContext context;

  static const double _ratioTablet = 0.75;
  static const double _ratioPhone = 0.5;

  T value<T>({required T kiosk, T? tablet, T? phone}) {
    final Breakpoint(:deviceType) = context.breakpoint;
    if (deviceType == DeviceType.phone) return phone ?? tablet ?? kiosk;
    if (deviceType == DeviceType.tablet) return tablet ?? kiosk;
    return kiosk;
  }

  double scale(double value) {
    final Breakpoint(:deviceType) = context.breakpoint;
    if (deviceType == DeviceType.phone) return value * _ratioPhone;
    if (deviceType == DeviceType.tablet) return value * _ratioTablet;
    return value;
  }
}

extension ResponsiveValueContext on BuildContext {
  ResponsiveValue get responsive => ResponsiveValue.of(this);
}
