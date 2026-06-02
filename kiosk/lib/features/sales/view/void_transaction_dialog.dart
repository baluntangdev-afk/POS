import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../use_cases/void_sale.dart';

class VoidTransactionDialog extends HookConsumerWidget {
  const VoidTransactionDialog({
    super.key,
    required this.salesOrderId,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  final String salesOrderId;
  final String invoiceNumber;
  final Decimal totalAmount;

  static Future<bool> show(
    BuildContext context, {
    required String salesOrderId,
    required String invoiceNumber,
    required Decimal totalAmount,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          builder: (context) => VoidTransactionDialog(
            salesOrderId: salesOrderId,
            invoiceNumber: invoiceNumber,
            totalAmount: totalAmount,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final reasonController = useTextEditingController();
    final userIdController = useTextEditingController();
    final pin = useState('');
    final isLoading = useState(false);

    const maxPinLength = 6;

    void appendDigit(String digit) {
      if (pin.value.length < maxPinLength) {
        pin.value = pin.value + digit;
      }
    }

    void deleteDigit() {
      if (pin.value.isNotEmpty) {
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    Future<void> confirmVoid() async {
      if (isLoading.value) return;

      final reason = reasonController.text.trim();
      final userId = userIdController.text.trim();
      final pinValue = pin.value;

      final missing = <String>[];
      if (reason.isEmpty) missing.add('void reason');
      if (userId.isEmpty) missing.add('authorizer User ID');
      if (pinValue.length < 4) missing.add('PIN (min. 4 digits)');

      if (missing.isNotEmpty) {
        await showMessageDialog(
          context,
          type: DialogType.error,
          message: 'Please provide: ${missing.join(', ')}.',
        );
        return;
      }

      isLoading.value = true;
      try {
        await ref.read(voidSaleProvider)(
          salesOrderId: salesOrderId,
          reason: reason,
          authorizerUserId: userId,
          authorizerPin: pinValue,
        );
        if (context.mounted) Navigator.of(context).pop(true);
      } catch (e) {
        isLoading.value = false;
        if (context.mounted) {
          await showMessageDialog(
            context,
            type: DialogType.error,
            message: 'Failed to void transaction: $e',
          );
        }
      }
    }

    final dialogWidth = r.value<double>(kiosk: 560, tablet: 480, phone: 340);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
                vertical: r.value<double>(kiosk: 20, tablet: 16, phone: 14),
              ),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.06),
                border: const Border(bottom: BorderSide(color: POSColors.borderDefault)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorSet.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(POSRadius.sm),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      color: ColorSet.danger,
                      size: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                    ),
                  ),
                  SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Void Transaction',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                            fontWeight: FontWeight.w700,
                            color: ColorSet.danger,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$invoiceNumber  ·  ${totalAmount.pesoFormatted}',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                            color: POSColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner
                    Container(
                      padding: EdgeInsets.all(r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                      decoration: BoxDecoration(
                        color: ColorSet.danger.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        border: Border.all(color: ColorSet.danger.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: ColorSet.danger,
                            size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                          ),
                          SizedBox(width: r.value<double>(kiosk: 8, tablet: 6, phone: 6)),
                          Expanded(
                            child: Text(
                              'This action cannot be undone. The transaction will be permanently cancelled.',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: ColorSet.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 14)),

                    // Reason
                    TextBoxFormField(
                      controller: reasonController,
                      label: 'Reason for Void',
                      hint: 'Enter void reason...',
                      maxLines: 2,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      ),
                    ),

                    SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 14)),

                    // Auth section divider
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: POSColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(POSRadius.xs),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                            color: POSColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Supervisor Authorization',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                            fontWeight: FontWeight.w700,
                            color: POSColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                    // User ID
                    TextBoxFormField.singleLine(
                      controller: userIdController,
                      label: 'User ID',
                      hint: 'Enter admin/supervisor User ID',
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      ),
                    ),

                    SizedBox(height: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),

                    // PIN dots
                    _PinDisplay(pin: pin, maxLength: maxPinLength, r: r),

                    SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),

                    // PIN pad
                    _PinPad(
                      onDigit: appendDigit,
                      onDelete: deleteDigit,
                      r: r,
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
                vertical: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: POSColors.borderDefault)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: r.value<double>(kiosk: 48, tablet: 44, phone: 40),
                      child: OutlinedButton(
                        onPressed:
                            isLoading.value ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: POSColors.textSecondary,
                          side: const BorderSide(color: POSColors.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                  Expanded(
                    child: SizedBox(
                      height: r.value<double>(kiosk: 48, tablet: 44, phone: 40),
                      child: FilledButton.icon(
                        onPressed: isLoading.value ? null : confirmVoid,
                        icon: isLoading.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              )
                            : const Icon(Icons.block_rounded, size: 16),
                        label: Text(
                          isLoading.value ? 'Voiding...' : 'Void Transaction',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isLoading.value ? POSColors.borderStrong : ColorSet.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PIN dots display ──────────────────────────────────────────────────────────

class _PinDisplay extends StatelessWidget {
  const _PinDisplay({
    required this.pin,
    required this.maxLength,
    required this.r,
  });

  final ValueNotifier<String> pin;
  final int maxLength;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final dotSize = r.value<double>(kiosk: 14, tablet: 12, phone: 10);
    final spacing = r.value<double>(kiosk: 10, tablet: 8, phone: 7);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLength, (index) {
          final isFilled = index < pin.value.length;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? ColorSet.danger : Colors.transparent,
              border: Border.all(
                color: isFilled ? ColorSet.danger : POSColors.borderStrong,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── PIN pad ───────────────────────────────────────────────────────────────────

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onDelete,
    required this.r,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final btnSize = r.value<double>(kiosk: 64, tablet: 56, phone: 48);
    final spacing = r.value<double>(kiosk: 10, tablet: 8, phone: 6);

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...rows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map(
                    (digit) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: _PinButton(
                        label: digit,
                        size: btnSize,
                        onTap: () => onDigit(digit),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        // Bottom row: 0 + backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: btnSize + spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: _PinButton(
                label: '0',
                size: btnSize,
                onTap: () => onDigit('0'),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: _PinDeleteButton(size: btnSize, onTap: onDelete),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({
    required this.label,
    required this.size,
    required this.onTap,
  });

  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
                color: POSColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDeleteButton extends StatelessWidget {
  const _PinDeleteButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: ColorSet.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: ColorSet.danger,
              size: size * 0.38,
            ),
          ),
        ),
      ),
    );
  }
}
