import 'package:flutter/material.dart';

import 'breakpoint.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.kiosk, this.tablet, this.phone});

  final WidgetBuilder kiosk;
  final WidgetBuilder? tablet;
  final WidgetBuilder? phone;

  @override
  Widget build(BuildContext context) {
    final Breakpoint(:deviceType) = context.breakpoint;
    if (deviceType == DeviceType.phone) return (phone ?? tablet ?? kiosk)(context);
    if (deviceType == DeviceType.tablet) return (tablet ?? kiosk)(context);
    return kiosk(context);
  }
}

/// Switches layout by [DeviceFormFactor], distinguishing Android tablet from
/// Windows tablet in addition to kiosk.
///
/// Use this instead of [ResponsiveBuilder] when Android requires different
/// chrome (safe area, Material ripple, bottom nav, gesture zones, etc.).
class FormFactorBuilder extends StatelessWidget {
  const FormFactorBuilder({
    super.key,
    required this.kiosk,
    required this.windowsTablet,
    required this.androidTablet,
  });

  final WidgetBuilder kiosk;
  final WidgetBuilder windowsTablet;
  final WidgetBuilder androidTablet;

  @override
  Widget build(BuildContext context) {
    return switch (context.breakpoint.formFactor) {
      DeviceFormFactor.kiosk => kiosk(context),
      DeviceFormFactor.windowsTablet => windowsTablet(context),
      DeviceFormFactor.androidTablet => androidTablet(context),
    };
  }
}
