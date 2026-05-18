import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../styles/responsive/responsive_value.dart';
import 'pin_button.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.selectedButton,
  });

  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final ValueNotifier<int?> selectedButton;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final buttonSize = responsive.scale(100);
    final spacing = responsive.value<double>(phone: 16, tablet: 24, kiosk: 32);

    return Column(
      children: [
        _buildRow(['1', '2', '3'], buttonSize, spacing),
        Gap(spacing),
        _buildRow(['4', '5', '6'], buttonSize, spacing),
        Gap(spacing),
        _buildRow(['7', '8', '9'], buttonSize, spacing),
        Gap(spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: buttonSize),
            Gap(spacing),
            PinButton(
              size: buttonSize,
              label: '0',
              onPressed: () => onNumberPressed('0'),
              selectedButton: selectedButton,
              buttonIndex: 0,
            ),
            Gap(spacing),
            PinButton(
              size: buttonSize,
              onPressed: onBackspace,
              selectedButton: selectedButton,
              buttonIndex: 11,
              child: Text(
                '⌫',
                style: TextStyle(
                  fontSize: context.responsive.scale(40),
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> numbers, double buttonSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          numbers.map((number) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: PinButton(
                size: buttonSize,
                label: number,
                onPressed: () => onNumberPressed(number),
                selectedButton: selectedButton,
                buttonIndex: int.parse(number),
              ),
            );
          }).toList(),
    );
  }
}
