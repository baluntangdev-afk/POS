import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

/// Red outlined pill that takes the discount off a cart line (see
/// `OrderingNotifier.removeDiscount`). The visual stays compact to fit
/// dense item rows, but the hit area is padded to the 48×48 touch minimum.
class RemoveDiscountButton extends StatelessWidget {
  const RemoveDiscountButton({super.key, required this.onPressed, this.label = 'Remove Discount'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final fontSize = r.value<double>(kiosk: 12, tablet: 11, phone: 11);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.close_rounded, size: fontSize + 2),
      label: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorSet.danger,
        backgroundColor: ColorSet.danger.withValues(alpha: 0.06),
        side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: r.value<double>(kiosk: 12, tablet: 10, phone: 10)),
        minimumSize: Size(0, r.value<double>(kiosk: 36, tablet: 32, phone: 32)),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Shown on a discounted line: the discount taken off, as `−₱22.40`.
class DiscountAmountText extends StatelessWidget {
  const DiscountAmountText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
        fontWeight: FontWeight.w700,
        color: ColorSet.danger,
      ),
    );
  }
}
