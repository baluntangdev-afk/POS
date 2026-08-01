import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

class TopAppBar extends StatelessWidget {
  const TopAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBack = true,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBack;

  static double preferredHeight(BuildContext context) => context.responsive.appBarHeight;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final backSize = r.iconBack;
    final hPad = r.hPagePadding;

    return Container(
      height: r.appBarHeight,
      decoration: const BoxDecoration(
        gradient: POSGradient.header,
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: hPad),
          if (showBack)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(POSRadius.xl),
              child: InkWell(
                borderRadius: BorderRadius.circular(POSRadius.xl),
                onTap: onBackPressed ?? () { if (context.canPop()) context.pop(); },
                splashColor: Colors.white.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: ColorSet.light, size: backSize),
                ),
              ),
            )
          else
            SizedBox(width: backSize + 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: r.fontTitle,
                    fontWeight: FontWeight.w700,
                    color: ColorSet.light,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: r.fontTitle * 0.6,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            SizedBox(width: hPad),
          ] else
            SizedBox(width: backSize + 16 + hPad),
        ],
      ),
    );
  }
}

class POSFlatHeader extends StatelessWidget {
  const POSFlatHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.height,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final h = height ?? r.value(kiosk: 68.0, tablet: 60.0, phone: 52.0);

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: r.value(kiosk: 24.0, tablet: 16.0, phone: 12.0)),
      child: Row(
        children: [
          _BackButton(onBack: onBack, size: r.value(kiosk: 52.0, tablet: 44.0, phone: 38.0)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: r.value(kiosk: 22.0, tablet: 18.0, phone: 16.0),
                fontWeight: FontWeight.w700,
                color: POSColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: r.value(kiosk: 110.0, tablet: 90.0, phone: 76.0),
            child: trailing != null
                ? Align(alignment: Alignment.centerRight, child: trailing)
                : null,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({this.onBack, required this.size});

  final VoidCallback? onBack;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 20,
      height: size,
      child: OutlinedButton.icon(
        onPressed: onBack ?? () { if (context.canPop()) context.pop(); },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        label: const Text('Back'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorSet.primary,
          side: const BorderSide(color: ColorSet.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
