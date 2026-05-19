import 'package:flutter/material.dart';

import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import 'login_view.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight <= 500;
        final body = LoginView(isSmallHeight: isSmallHeight);

        if (isAndroid) {
          // Transparent status bar with light icons (gradient is behind it).
          return AndroidScaffold(
            statusBarIconBrightness: Brightness.light,
            extendBodyBehindAppBar: true,
            body: body,
          );
        }

        return WindowsScaffold(body: body);
      },
    );
  }
}
