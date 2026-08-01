import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/auth.dart';
import 'setup_pin_view.dart';

class SetupPinScreen extends HookWidget {
  const SetupPinScreen({super.key, required this.auth});

  final Auth auth;

  @override
  Widget build(BuildContext context) {
    final pinType = useState(PinType.setup);
    final isAndroid = context.breakpoint.isAndroid;

    void handleBack() {
      switch (pinType.value) {
        case PinType.setup:
          const LoginRoute().go(context);
        case PinType.confirm:
          pinType.value = PinType.setup;
      }
    }

    Widget buildBackButton() {
      return Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(POSRadius.full),
        child: InkWell(
          onTap: handleBack,
          borderRadius: BorderRadius.circular(POSRadius.full),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: context.responsive.iconBack,
            ),
          ),
        ),
      );
    }

    if (isAndroid) {
      return AndroidScaffold(
        statusBarIconBrightness: Brightness.light,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallHeight = constraints.maxHeight <= 500;
              final bottomPad = MediaQuery.of(context).viewPadding.bottom;
              return Column(
                children: [
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: ColorSet.gradientBg,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Center(
                            child: Icon(Icons.lock_rounded, color: Colors.white, size: 48),
                          ),
                          Align(alignment: Alignment.centerLeft, child: buildBackButton()),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        child: SetupPinView(
                          isSmallHeight: isSmallHeight,
                          auth: auth,
                          pinTypeNotifier: pinType,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return WindowsScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight <= 500;
          final isPortrait = constraints.maxHeight > constraints.maxWidth;

          if (isPortrait) {
            return Column(
              children: [
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: ColorSet.gradientBg,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Icon(Icons.lock_rounded, color: Colors.white, size: 40),
                      ),
                      Align(alignment: Alignment.centerLeft, child: buildBackButton()),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SetupPinView(
                      isSmallHeight: isSmallHeight,
                      auth: auth,
                      pinTypeNotifier: pinType,
                    ),
                  ),
                ),
              ],
            );
          }

          // Landscape: left gradient panel + right white card
          final panelWidth =
              context.responsive.value<double>(kiosk: 400, tablet: 320, phone: 240);
          return Row(
            children: [
              Container(
                width: panelWidth,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ColorSet.gradientBg,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: panelWidth * 0.3,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Setup PIN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: context.responsive.value<double>(
                                kiosk: 20,
                                tablet: 16,
                                phone: 14,
                              ),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 24,
                      left: 16,
                      child: buildBackButton(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.white,
                  child: SetupPinView(
                    isSmallHeight: isSmallHeight,
                    auth: auth,
                    pinTypeNotifier: pinType,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
