import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../widgets/windows_scaffold.dart';
import 'login_view.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight <= 500;
          return SizedBox.expand(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ColorSet.gradientBg,
                ),
              ),
              child: LoginView(isSmallHeight: isSmallHeight),
            ),
          );
        },
      ),
    );
  }
}
