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

typedef _PendingMethod = ({PaymentMethod method, String? methodName, String? number});

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
    final pendingMethods = useState<List<_PendingMethod>>([]);
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> onAddPaymentMethod() async {
      await showDialog<void>(
        context: context,
        builder: (_) => _PaymentMethodFormDialog(
          onConfirm: (method, methodName, number) async {
            pendingMethods.value = [
              ...pendingMethods.value,
              (method: method, methodName: methodName, number: number),
            ];
          },
        ),
      );
    }

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
        );
        for (final pm in pendingMethods.value) {
          await api.addPaymentMethod(
            paymentMethod: pm.method,
            paymentMethodName: pm.methodName,
            paymentNumber: pm.number,
          );
        }
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
                      const SizedBox(height: 24),
                      _PendingPaymentMethodsSection(
                        methods: pendingMethods.value,
                        onAdd: onAddPaymentMethod,
                        onRemove: (index) {
                          final updated = [...pendingMethods.value];
                          updated.removeAt(index);
                          pendingMethods.value = updated;
                        },
                      ),
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

// ── Pending Payment Methods Section ──────────────────────────────────────────

class _PendingPaymentMethodsSection extends StatelessWidget {
  const _PendingPaymentMethodsSection({
    required this.methods,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PendingMethod> methods;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  static const _labels = {
    PaymentMethod.cash: 'Cash',
    PaymentMethod.creditCard: 'Credit Card',
    PaymentMethod.gCash: 'GCash',
    PaymentMethod.other: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        if (methods.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              color: POSColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(POSRadius.md),
              border: const Border.fromBorderSide(BorderSide(color: POSColors.borderDefault)),
            ),
            child: const Text(
              'No payment methods added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
            ),
          )
        else
          ...methods.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    border: const Border.fromBorderSide(
                        BorderSide(color: POSColors.borderDefault)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorSet.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(POSRadius.sm),
                        ),
                        child: Text(
                          e.value.method == PaymentMethod.other && e.value.methodName != null
                              ? e.value.methodName!
                              : (_labels[e.value.method] ?? e.value.method.name),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorSet.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (e.value.number != null)
                        Expanded(
                          child: Text(
                            e.value.number!,
                            style: const TextStyle(
                                fontSize: 13, color: POSColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: ColorSet.danger),
                        onPressed: () => onRemove(e.key),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorSet.primary,
            side: const BorderSide(color: ColorSet.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payment Method Form Dialog ────────────────────────────────────────────────

class _PaymentMethodFormDialog extends HookWidget {
  const _PaymentMethodFormDialog({required this.onConfirm});

  final Future<void> Function(PaymentMethod method, String? methodName, String? number) onConfirm;

  static const _labels = {
    PaymentMethod.cash: 'Cash',
    PaymentMethod.creditCard: 'Credit Card',
    PaymentMethod.gCash: 'GCash',
    PaymentMethod.other: 'Other',
  };

  static InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: POSColors.textTertiary),
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
      );

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>());
    final selectedMethod = useState(PaymentMethod.cash);
    final methodNameController = useTextEditingController();
    final numberController = useTextEditingController();
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> onSubmit() async {
      if (!formKey.value.currentState!.validate()) return;
      isSubmitting.value = true;
      errorMessage.value = null;
      try {
        final methodName = selectedMethod.value == PaymentMethod.other &&
                methodNameController.text.trim().isNotEmpty
            ? methodNameController.text.trim()
            : null;
        final number =
            numberController.text.trim().isNotEmpty ? numberController.text.trim() : null;
        await onConfirm(selectedMethod.value, methodName, number);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        errorMessage.value = e.message;
        isSubmitting.value = false;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.elevated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),
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
                  value: selectedMethod.value,
                  onChanged: (m) {
                    if (m != null) {
                      selectedMethod.value = m;
                      methodNameController.clear();
                      numberController.clear();
                    }
                  },
                  decoration: _fieldDecoration(),
                  items: PaymentMethod.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_labels[m] ?? m.name),
                        ),
                      )
                      .toList(),
                ),
                if (selectedMethod.value == PaymentMethod.other) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: POSColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: methodNameController,
                    decoration: _fieldDecoration(hint: 'e.g. PayMaya, Bitcoin'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Payment method name is required' : null,
                  ),
                ],
                if (selectedMethod.value != PaymentMethod.cash) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: POSColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: numberController,
                    decoration: _fieldDecoration(hint: 'e.g. 09171234567'),
                  ),
                ],
                if (errorMessage.value != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: errorMessage.value!),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting.value ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: POSColors.textSecondary,
                          side: const BorderSide(color: POSColors.borderDefault),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting.value ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorSet.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                        child: isSubmitting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                  strokeCap: StrokeCap.round,
                                ),
                              )
                            : const Text(
                                'Add',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
