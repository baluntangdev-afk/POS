import 'package:flutter/material.dart';
import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../styles/type_set.dart';

class TopAppBar extends StatelessWidget {
  const TopAppBar({super.key, required this.onBackPressed, required this.title, this.trailing});

  final void Function() onBackPressed;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: responsive.scale(24)),
        child: Stack(
          alignment: Alignment.center,
          // fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: IconButton(
                  onPressed: onBackPressed,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: ColorSet.light,
                    size: responsive.scale(35),
                  ),
                ),
              ),
            ),
            Text(
              title,
              style: TypeSet.h5.copyWith(color: ColorSet.light, fontSize: responsive.scale(28)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
