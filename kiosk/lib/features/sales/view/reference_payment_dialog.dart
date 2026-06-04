import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../data/backend_api/schemas/payment_method_entry_dto.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_bottom_sheet.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_box_form_field.dart';
import '../entities/payment.dart';

Future<Payment?> showReferencePaymentDialog(
  BuildContext context, {
  required PaymentMethodEntryDto entry,
  required Decimal collectibleAmount,
}) {
  if (Platform.isAndroid) {
    return showAndroidBottomSheet<Payment>(
      context: context,
      maxHeightRatio: 0.95,
      builder: (ctx) => _ReferencePaymentContent(
        entry: entry,
        collectibleAmount: collectibleAmount,
      ),
    );
  }
  return showDialog<Payment>(
    context: context,
    builder: (context) => Dialog(
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
      child: _ReferencePaymentContent(
        entry: entry,
        collectibleAmount: collectibleAmount,
      ),
    ),
  );
}

class _ReferencePaymentContent extends HookWidget {
  const _ReferencePaymentContent({
    required this.entry,
    required this.collectibleAmount,
  });

  final PaymentMethodEntryDto entry;
  final Decimal collectibleAmount;

  bool get _isCard => entry.paymentMethod == 'Credit Card';

  String get _title => switch (entry.paymentMethod) {
    'Credit Card' => 'Card Payment',
    'GCash' => 'GCash Payment',
    _ => '${entry.paymentMethodName ?? entry.paymentMethod} Payment',
  };

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final referenceController = useTextEditingController();
    final cardDigitsController = useTextEditingController();
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
            spacing: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
            children: [
              Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              Text(
                _title,
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
                controller: referenceController,
                label: 'Reference Number',
                hint: 'Enter reference number',
                maxLines: 1,
                textInputAction: _isCard ? TextInputAction.next : TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reference number is required';
                  }
                  return null;
                },
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                ),
              ),
              if (_isCard)
                TextBoxFormField(
                  controller: cardDigitsController,
                  label: 'Last 4 Digits of Card',
                  hint: '0000',
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 4) {
                      return 'Enter exactly 4 digits';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  ),
                ),
              Row(
                children: [
                  Button.outlined(
                    foregroundColor: ColorSet.text,
                    onPressed: () => Navigator.of(context).pop(),
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
                      final Payment payment;
                      if (_isCard) {
                        payment = CardPayment(
                          paidAmount: collectibleAmount,
                          referenceNumber: referenceController.text.trim(),
                          cardType: 'Credit/Debit',
                          cardNumber: cardDigitsController.text,
                        );
                      } else {
                        payment = QRPayment(
                          paidAmount: collectibleAmount,
                          referenceNumber: referenceController.text.trim(),
                          walletProvider: entry.paymentMethodName ?? entry.paymentMethod,
                        );
                      }
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
