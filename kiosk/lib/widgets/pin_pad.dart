import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import 'pin_button.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.selectedButton,
    this.onConfirm,
  });

  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final ValueNotifier<int?> selectedButton;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final spacing = context.responsive.value<double>(phone: 8, tablet: 10, kiosk: 12);

    Expanded numberButton(String digit) => Expanded(
          child: PinButton(
            label: digit,
            onPressed: () => onNumberPressed(digit),
            selectedButton: selectedButton,
            buttonIndex: int.parse(digit),
          ),
        );

    return Column(
      children: [
        Row(children: [numberButton('1'), Gap(spacing), numberButton('2'), Gap(spacing), numberButton('3')]),
        Gap(spacing),
        Row(children: [numberButton('4'), Gap(spacing), numberButton('5'), Gap(spacing), numberButton('6')]),
        Gap(spacing),
        Row(children: [numberButton('7'), Gap(spacing), numberButton('8'), Gap(spacing), numberButton('9')]),
        Gap(spacing),
        Row(
          children: [
            Expanded(
              child: PinButton(
                onPressed: onBackspace,
                selectedButton: selectedButton,
                buttonIndex: 10,
                child: Icon(
                  Icons.backspace_outlined,
                  size: context.responsive.value<double>(phone: 20, tablet: 22, kiosk: 26),
                  color: ColorSet.dark,
                ),
              ),
            ),
            Gap(spacing),
            numberButton('0'),
            Gap(spacing),
            Expanded(
              child: PinButton(
                onPressed: onConfirm ?? () {},
                selectedButton: selectedButton,
                buttonIndex: 11,
                child: Icon(
                  Icons.check_rounded,
                  size: context.responsive.value<double>(phone: 20, tablet: 22, kiosk: 26),
                  color: ColorSet.dark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
