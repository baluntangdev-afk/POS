import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

/// A general-purpose numeric keypad for PIN and cash entry.
///
/// Key layout (3 × 4):
///   1  2  3
///   4  5  6
///   7  8  9
///   _  0  ⌫
///
/// On Android, keys use Material [InkWell] for ripple feedback.
/// On Windows, keys use a shadow-based pressed look consistent with the
/// existing [PinButton] style.
///
/// [keyHeight] defaults to [ResponsiveValue.keypadKeySize]
/// (88 px kiosk · 72 px tablet · 56 px phone).
///
/// To prevent the Android system keyboard from appearing when this is used
/// for PIN input, set `readOnly: true` on any backing [TextField] and drive
/// all input through this widget.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.keyHeight,
    this.keySpacing,
  });

  final void Function(String digit) onKeyPressed;
  final VoidCallback onBackspace;

  /// Height (and width) of each square key.
  final double? keyHeight;

  /// Gap between adjacent keys; defaults to [ResponsiveValue.spacingMd].
  final double? keySpacing;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final size = keyHeight ?? r.keypadKeySize;
    final gap = keySpacing ?? r.spacingMd;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3'], size, gap),
        Gap(gap),
        _row(['4', '5', '6'], size, gap),
        Gap(gap),
        _row(['7', '8', '9'], size, gap),
        Gap(gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: size), // intentional empty slot
            Gap(gap),
            _KeyCell(
              size: size,
              label: '0',
              onTap: () => onKeyPressed('0'),
            ),
            Gap(gap),
            _KeyCell(
              size: size,
              onTap: onBackspace,
              child: Text(
                '⌫',
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: POSColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits, double size, double gap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gap / 2),
          child: _KeyCell(
            size: size,
            label: d,
            onTap: () => onKeyPressed(d),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({
    required this.size,
    required this.onTap,
    this.label,
    this.child,
  });

  final double size;
  final VoidCallback onTap;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Text(
          label ?? '',
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600,
            color: POSColors.textPrimary,
          ),
        );

    if (Platform.isAndroid) {
      return Material(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: ColorSet.primary.withValues(alpha: 0.18),
          highlightColor: ColorSet.primary.withValues(alpha: 0.08),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: content),
          ),
        ),
      );
    }

    // Windows: subtle shadow, no ripple.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: POSColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: POSShadow.card,
        ),
        child: Center(child: content),
      ),
    );
  }
}
