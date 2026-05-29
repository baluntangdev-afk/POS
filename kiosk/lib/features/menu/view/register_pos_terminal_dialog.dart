import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/enums/payment_method.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../state/pos_terminal_notifier.dart';

Future<void> showRegisterPosTerminalDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RegisterPosTerminalDialog(
      onSuccess: () {
        Navigator.of(context, rootNavigator: true).pop();
        ref.invalidate(posTerminalProvider);
      },
      onCancel: () {
        Navigator.of(context, rootNavigator: true).pop();
        const OnboardingRoute().go(context);
      },
    ),
  );
}

class RegisterPosTerminalDialog extends HookConsumerWidget {
  const RegisterPosTerminalDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useRef(GlobalKey<FormState>());
    final legalNameController = useTextEditingController();
    final addressController = useTextEditingController();
    final tinController = useTextEditingController();
    final paymentMethod = useState(PaymentMethod.cash);
    final paymentNumberController = useTextEditingController();
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> onRegister() async {
      if (!formKey.value.currentState!.validate()) return;
      isSubmitting.value = true;
      errorMessage.value = null;
      try {
        final api = ref.read(posTerminalsApiProvider);
        await api.registerMyTerminal(
          legalName: legalNameController.text.trim(),
          address: addressController.text.trim(),
          tinNumber: tinController.text.trim(),
          paymentMethod: paymentMethod.value,
          paymentNumber: paymentNumberController.text.trim().isNotEmpty
              ? paymentNumberController.text.trim()
              : null,
        );
        onSuccess();
      } catch (e) {
        errorMessage.value = e.message;
        isSubmitting.value = false;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.elevated,
        ),
        child: Form(
          key: formKey.value,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PosFormField(
                        label: 'Legal Name',
                        controller: legalNameController,
                        hint: 'e.g. ABC Corporation',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Legal Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _PosFormField(
                        label: 'Address',
                        controller: addressController,
                        hint: 'e.g. 123 Main St., City',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _PosFormField(
                        label: 'TIN Number',
                        controller: tinController,
                        hint: 'e.g. 123-456-789-000',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'TIN Number is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _PaymentMethodField(
                        value: paymentMethod.value,
                        onChanged: (m) {
                          paymentMethod.value = m!;
                          paymentNumberController.clear();
                        },
                      ),
                      if (paymentMethod.value != PaymentMethod.cash) ...[
                        const SizedBox(height: 16),
                        _PosFormField(
                          label: 'Payment Number',
                          controller: paymentNumberController,
                          hint: 'e.g. 09171234567',
                        ),
                      ],
                      if (errorMessage.value != null) ...[
                        const SizedBox(height: 16),
                        _RegisterErrorBanner(message: errorMessage.value!),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting.value ? null : onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ColorSet.danger,
                                side: BorderSide(
                                  color: ColorSet.danger.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(POSRadius.md),
                                ),
                              ),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: isSubmitting.value ? null : onRegister,
                              style: FilledButton.styleFrom(
                                backgroundColor: ColorSet.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(POSRadius.md),
                                ),
                              ),
                              child: isSubmitting.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    )
                                  : const Text(
                                      'Register Terminal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorSet.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(POSRadius.xl),
          topRight: Radius.circular(POSRadius.xl),
        ),
        border: const Border(bottom: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorSet.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: ColorSet.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register POS Terminal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fill in the details to register this terminal.',
                  style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosFormField extends StatelessWidget {
  const _PosFormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: POSColors.textTertiary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: POSColors.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: ColorSet.danger),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodField extends StatelessWidget {
  const _PaymentMethodField({required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod?> onChanged;

  static const _labels = {
    PaymentMethod.cash: 'Cash',
    PaymentMethod.creditCard: 'Credit Card',
    PaymentMethod.gCash: 'GCash',
    PaymentMethod.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaymentMethod>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: POSColors.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: PaymentMethod.values
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(_labels[m] ?? m.name),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RegisterErrorBanner extends StatelessWidget {
  const _RegisterErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorSet.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: ColorSet.danger.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: ColorSet.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ColorSet.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
