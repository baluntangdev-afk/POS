import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 1-9 grid + 0/delete row, shared by every screen that collects a PIN
/// (login, change-PIN) so staff always tap the same layout.
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool disabled;

  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          rows.map((row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // Every cell — including the blank corner — goes through the
              // same SizedBox+padding wrapper so row 4 lines up under the
              // grid above it instead of drifting from a smaller placeholder.
              children:
                  row.map((key) {
                    return _KeypadCell(
                      keyLabel: key,
                      disabled: disabled,
                      onDigit: onDigit,
                      onDelete: onDelete,
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }
}

class _KeypadCell extends StatelessWidget {
  const _KeypadCell({
    required this.keyLabel,
    required this.disabled,
    required this.onDigit,
    required this.onDelete,
  });

  final String keyLabel;
  final bool disabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDelete = keyLabel == 'del';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SizedBox(
        width: AppSpacing.touchPreferred,
        height: AppSpacing.touchPreferred,
        child:
            keyLabel.isEmpty
                ? null
                : FilledButton(
                  onPressed:
                      disabled
                          ? null
                          : isDelete
                          ? onDelete
                          : () => onDigit(keyLabel),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.05,
                    ),
                    disabledForegroundColor: AppColors.primaryDark
                        .withValues(alpha: 0.4),
                    overlayColor: AppColors.primary.withValues(alpha: 0.12),
                    elevation: 0,
                  ),
                  child:
                      isDelete
                          ? const Icon(Icons.backspace_outlined)
                          : Text(keyLabel, style: AppTextStyles.headingMd),
                ),
      ),
    );
  }
}
