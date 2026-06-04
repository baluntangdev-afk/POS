import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/decimal_input_formatter.dart';
import '../../../validation/rules/min_value.dart';
import '../../../validation/validate.dart';
import '../../../widgets/android_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../../widgets/text_box_form_field.dart';
import '../entities/payment.dart';

/// Shows the cash payment UI.
///
/// On Android: slides up as a bottom sheet (spec §10 [A]).
/// On Windows: shows as a centred dialog.
Future<CashPayment?> showCashPaymentDialog(
  BuildContext context, {
  required Decimal collectibleAmount,
}) {
  if (Platform.isAndroid) {
    return showAndroidBottomSheet<CashPayment>(
      context: context,
      maxHeightRatio: 0.95,
      builder: (ctx) => _CashPaymentContent(collectibleAmount: collectibleAmount),
    );
  }
  return showDialog<CashPayment>(
    context: context,
    builder: (context) => CashPaymentDialog(collectibleAmount: collectibleAmount),
  );
}

/// Windows dialog wrapper — wraps [_CashPaymentContent] in a [Dialog].
class CashPaymentDialog extends HookWidget {
  const CashPaymentDialog({super.key, required this.collectibleAmount});

  final Decimal collectibleAmount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: _CashPaymentContent(collectibleAmount: collectibleAmount),
    );
  }
}

/// Shared form content used by both the Windows dialog and the Android bottom sheet.
class _CashPaymentContent extends HookWidget {
  const _CashPaymentContent({required this.collectibleAmount});

  final Decimal collectibleAmount;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final cashController = useTextEditingController();
    final cashInputFormatter = useMemoized(() => DecimalInputFormatter());

    useListenable(cashController);

    final cashReceived = Decimal.tryParse(cashController.text.replaceAll(',', '')) ?? Decimal.zero;
    final bottomInset = Platform.isAndroid ? MediaQuery.of(context).viewPadding.bottom : 0.0;

    return Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: context.responsive.value(kiosk: 600, tablet: 600, phone: double.infinity),
            padding: EdgeInsets.only(
              left: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
              right: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
              bottom: bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
              children: [
                Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                Text(
                  'Cash Payment',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 36, tablet: 24, phone: 18),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  padding: EdgeInsets.all(
                    context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                  ),
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(POSRadius.xl),
                    border: Border.all(color: POSColors.borderDefault),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount Due',
                        style: TextStyle(
                          color: POSColors.textTertiary,
                          fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Gap(context.responsive.value(kiosk: 12, tablet: 8, phone: 4)),
                      Text(
                        collectibleAmount.withCommas,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 56, tablet: 36, phone: 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextBoxFormField(
                  controller: cashController,
                  label: 'Cash Received',
                  hint: '0.00',
                  maxLines: 1,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [cashInputFormatter],
                  suffixIcon: cashController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            cashController.clear();
                            formKey.currentState?.reset();
                          },
                        )
                      : null,
                  validator: (value) {
                    final rules = [
                      minValue(collectibleAmount.toDouble(), message: 'Insufficient amount'),
                    ];
                    final validate = Validate<double>(rules: rules);
                    final sanitizedValue = value?.replaceAll(',', '');
                    final receivedAmount = double.tryParse(sanitizedValue ?? '') ?? 0.0;
                    return validate(receivedAmount);
                  },
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
                ResponsiveWrapContainer(
                  spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                  equalWidth: true,
                  rowItems: 3,
                  // runSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                  items:
                      [20, 50, 100, 200, 500, 1000].map((denomination) {
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          child: InkWell(
                            onTap: () {
                              final current = Decimal.tryParse(
                                    cashController.text.replaceAll(',', ''),
                                  ) ??
                                  Decimal.zero;
                              final newAmount = current + Decimal.fromInt(denomination);
                              final newText = newAmount.toString();
                              final newValue = cashInputFormatter.formatEditUpdate(
                                cashController.value,
                                TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(
                                    offset: newText.length,
                                  ),
                                ),
                              );
                              cashController.value = newValue;
                            },
                            borderRadius: BorderRadius.circular(POSRadius.md),
                            child: Container(
                              width: context.responsive.value(kiosk: 120, tablet: 96, phone: 96),
                              height: context.responsive.value(kiosk: 60, tablet: 48, phone: 48),
                              decoration: BoxDecoration(
                                border: Border.all(color: POSColors.borderDefault),
                                borderRadius: BorderRadius.circular(POSRadius.md),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$denomination',
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 24,
                                    tablet: 20,
                                    phone: 16,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: POSColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                if (cashReceived >= collectibleAmount)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                          fontWeight: FontWeight.w500,
                          color: POSColors.textTertiary,
                        ),
                      ),
                      Text(
                        (cashReceived - collectibleAmount).withCommas,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 56, tablet: 36, phone: 28),
                          fontWeight: FontWeight.w800,
                          color: ColorSet.success,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                          ),
                        ),
                      ),
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    Button(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final payment = CashPayment(
                          paidAmount: collectibleAmount,
                          cashReceived: cashReceived,
                        );
                        Navigator.of(context).pop(payment);
                      },
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.primary,
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              ],
            ),
          ),
        ),
    );
  }
}
