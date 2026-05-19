import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';

class TopAppBar extends StatelessWidget {
  const TopAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBack = true,
  });

  final String title;
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorSet.secondary.withValues(alpha: 0.85),
            ColorSet.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: hPad),
          if (showBack)
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: onBackPressed ?? () { if (context.canPop()) context.pop(); },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: ColorSet.light, size: backSize),
              ),
            )
          else
            SizedBox(width: backSize),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: r.fontTitle,
                fontWeight: FontWeight.w600,
                color: ColorSet.light,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            SizedBox(width: hPad),
          ] else
            SizedBox(width: backSize + hPad),
        ],
      ),
    );
  }
}
