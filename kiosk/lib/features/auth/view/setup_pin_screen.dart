import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/auth.dart';
import 'setup_pin_view.dart';

class SetupPinScreen extends StatelessWidget {
  const SetupPinScreen({super.key, required this.auth});

  final Auth auth;

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight <= 500;
          return SizedBox.expand(
            child: Container(
              decoration: const BoxDecoration(color: ColorSet.background),
              child: SetupPinView(isSmallHeight: isSmallHeight, auth: auth),
            ),
          );
        },
      ),
    );
  }
}
