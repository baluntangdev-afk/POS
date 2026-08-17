import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import 'cartivo_register_view.dart';

class CartivoRegisterScreen extends StatelessWidget {
  const CartivoRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return AndroidScaffold(
        statusBarIconBrightness: Brightness.light,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomPad = MediaQuery.of(context).viewPadding.bottom;
              return Column(
                children: [
                  _CartivoBrandPanel(height: 130, isLandscape: false),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        child: const CartivoRegisterView(),
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
          final isPortrait = constraints.maxHeight > constraints.maxWidth;

          if (isPortrait) {
            return Column(
              children: [
                _CartivoBrandPanel(height: 110, isLandscape: false),
                Expanded(
                  child: Container(color: Colors.white, child: const CartivoRegisterView()),
                ),
              ],
            );
          }

          final panelWidth = context.responsive.value<double>(kiosk: 420, tablet: 340, phone: 260);
          return Row(
            children: [
              _CartivoBrandPanel(width: panelWidth, isLandscape: true),
              Expanded(
                child: Container(color: Colors.white, child: const CartivoRegisterView()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartivoBrandPanel extends StatelessWidget {
  const _CartivoBrandPanel({this.height, this.width, required this.isLandscape});

  final double? height;
  final double? width;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    Widget content;
    if (isLandscape) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.images.cartivoLogo.image(height: 48, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Merchant Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.value<double>(kiosk: 24, tablet: 19, phone: 16),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(POSRadius.xs),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Merchant Order Portal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: r.value<double>(kiosk: 14, tablet: 12, phone: 11),
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    } else {
      content = SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            'Create Merchant Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: r.value<double>(kiosk: 22, tablet: 18, phone: 16),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(gradient: POSGradient.primaryFaded),
      padding: EdgeInsets.all(isLandscape ? 32.0 : 24.0),
      child: content,
    );
  }
}
