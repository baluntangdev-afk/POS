import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';

class OrderSourceScreen extends StatelessWidget {
  const OrderSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return AndroidScaffold(
        backgroundColor: POSColors.surfaceSubtle,
        body: const SafeArea(child: OrderSourceContent()),
      );
    }

    return WindowsScaffold(
      backgroundColor: POSColors.surfaceSubtle,
      body: const OrderSourceContent(),
    );
  }
}

class OrderSourceContent extends StatelessWidget {
  const OrderSourceContent({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isPortrait = MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: r.value<double>(kiosk: 64, tablet: 40, phone: 24),
          vertical: r.value<double>(kiosk: 48, tablet: 36, phone: 24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.images.cartivoLogo.image(
                    height: r.value<double>(kiosk: 40, tablet: 34, phone: 28),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'POS Kiosk',
                    style: TextStyle(
                      color: POSColors.textPrimary,
                      fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.value<double>(kiosk: 56, tablet: 44, phone: 32)),
              Text(
                'How would you like to order?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: POSColors.textPrimary,
                  fontSize: r.value<double>(kiosk: 34, tablet: 30, phone: 26),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an option to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: POSColors.textTertiary,
                  fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: r.value<double>(kiosk: 48, tablet: 40, phone: 32)),
              if (isPortrait)
                Column(
                  children: [
                    _OrderSourceCard(
                      icon: Icons.storefront_outlined,
                      title: 'In Store',
                      subtitle: 'Staff login for counter orders',
                      accentGradient: null,
                      onTap: () => const LoginRoute().go(context),
                    ),
                    const SizedBox(height: 16),
                    _OrderSourceCard(
                      logo: Assets.images.cartivoLogo,
                      title: 'Cartivo Merchant',
                      subtitle: 'Sign in with your merchant account',
                      accentGradient: POSGradient.primaryFaded,
                      onTap: () => const CartivoLoginRoute().go(context),
                    ),
                  ],
                )
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _OrderSourceCard(
                          icon: Icons.storefront_outlined,
                          title: 'In Store',
                          subtitle: 'Staff login for counter orders',
                          accentGradient: null,
                          onTap: () => const LoginRoute().go(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _OrderSourceCard(
                          logo: Assets.images.cartivoLogo,
                          title: 'Cartivo Merchant',
                          subtitle: 'Sign in with your merchant account',
                          accentGradient: POSGradient.primaryFaded,
                          onTap: () => const CartivoLoginRoute().go(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSourceCard extends StatefulWidget {
  const _OrderSourceCard({
    this.icon,
    this.logo,
    required this.title,
    required this.subtitle,
    required this.accentGradient,
    required this.onTap,
  });

  final IconData? icon;
  final AssetGenImage? logo;
  final String title;
  final String subtitle;
  final Gradient? accentGradient;
  final VoidCallback onTap;

  @override
  State<_OrderSourceCard> createState() => _OrderSourceCardState();
}

class _OrderSourceCardState extends State<_OrderSourceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final badgeSize = r.value<double>(kiosk: 72, tablet: 64, phone: 56);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: POSAnimation.fast,
        curve: POSAnimation.ease,
        child: Container(
          constraints: BoxConstraints(
            minHeight: r.value<double>(kiosk: 220, tablet: 200, phone: 96),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: r.value<double>(kiosk: 32, tablet: 28, phone: 20),
            vertical: r.value<double>(kiosk: 32, tablet: 28, phone: 20),
          ),
          decoration: BoxDecoration(
            color: POSColors.surfaceElevated,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            boxShadow: _pressed ? POSShadow.card : POSShadow.panel,
            border: Border.all(color: POSColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color:
                      widget.accentGradient == null
                          ? ColorSet.primary.withValues(alpha: 0.1)
                          : null,
                  gradient: _fadeGradient(widget.accentGradient, 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      widget.logo != null
                          ? widget.logo!.image(height: badgeSize * 0.55, fit: BoxFit.contain)
                          : Icon(widget.icon, color: ColorSet.primary, size: badgeSize * 0.48),
                ),
              ),
              SizedBox(width: r.value<double>(kiosk: 20, tablet: 18, phone: 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: POSColors.textPrimary,
                        fontSize: r.value<double>(kiosk: 22, tablet: 20, phone: 17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: POSColors.textTertiary,
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: POSColors.textTertiary,
                size: r.value<double>(kiosk: 28, tablet: 24, phone: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Gradient? _fadeGradient(Gradient? gradient, double opacity) {
  if (gradient is! LinearGradient) return gradient;
  return LinearGradient(
    colors: gradient.colors.map((c) => c.withValues(alpha: opacity)).toList(),
    begin: gradient.begin,
    end: gradient.end,
  );
}
