import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/auth.dart';
import 'setup_pin_view.dart';

class SetupPinScreen extends StatelessWidget {
  const SetupPinScreen({super.key, required this.auth});

  final Auth auth;

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight <= 500;
        final body = SizedBox.expand(
          child: Container(
            decoration: const BoxDecoration(color: ColorSet.background),
            child: SetupPinView(isSmallHeight: isSmallHeight, auth: auth),
          ),
        );

        if (isAndroid) {
          return AndroidScaffold(
            resizeToAvoidBottomInset: false,
            body: body,
          );
        }

        return WindowsScaffold(body: body);
      },
    );
  }
}
