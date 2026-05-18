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
