import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/enums/payment_method.dart';
import '../../../data/backend_api/schemas/payment_method_entry_dto.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../../exceptions/exception_extension.dart';
import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../../menu/state/pos_terminal_notifier.dart';

Future<void> showPosTerminalDetailsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PosTerminalDetailsDialog(),
  );
}

class PosTerminalDetailsDialog extends HookConsumerWidget {
  const PosTerminalDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useRef(GlobalKey<FormState>());
    final legalNameController = useTextEditingController();
    final addressController = useTextEditingController();
    final tinController = useTextEditingController();
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);
    final isInitialized = useState(false);

    final posTerminalAsync = ref.watch(posTerminalProvider);

    useEffect(() {
      if (posTerminalAsync case AsyncData(value: final terminal)) {
        if (!isInitialized.value) {
          legalNameController.text = terminal.legalName ?? '';
          addressController.text = terminal.address;
          tinController.text = terminal.tinNumber;
          isInitialized.value = true;
        }
      }
      return null;
    }, [posTerminalAsync]);

    Future<void> onSave() async {
      if (!formKey.value.currentState!.validate()) return;
      isSubmitting.value = true;
      errorMessage.value = null;
      try {
        final api = ref.read(posTerminalsApiProvider);
        await api.updateMyTerminal(
          legalName: legalNameController.text.trim(),
          address: addressController.text.trim(),
          tinNumber: tinController.text.trim(),
        );
        ref.invalidate(posTerminalProvider);
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        errorMessage.value = e.message;
        isSubmitting.value = false;
      }
    }

    List<PaymentMethodEntryDto> resolveExistingEntries({int? excludeId}) {
      final terminal = switch (ref.read(posTerminalProvider)) {
        AsyncData(:final value) => value,
        _ => null,
      };
      final methods = terminal?.paymentMethods ?? <PaymentMethodEntryDto>[];
      return methods.where((e) => excludeId == null || e.id != excludeId).toList();
    }

    Future<void> onAddPaymentMethod() async {
      final api = ref.read(posTerminalsApiProvider);
      final existingEntries = resolveExistingEntries();
      await showDialog<void>(
        context: context,
        builder: (_) => _PaymentMethodFormDialog(
          existingEntries: existingEntries,
          onConfirm: (method, methodName, number) async {
            await api.addPaymentMethod(
              paymentMethod: method,
              paymentMethodName: methodName,
              paymentNumber: number,
            );
            ref.invalidate(posTerminalProvider);
          },
        ),
      );
    }

    Future<void> onEditPaymentMethod(PaymentMethodEntryDto entry) async {
      final api = ref.read(posTerminalsApiProvider);
      final existingEntries = resolveExistingEntries(excludeId: entry.id);
      await showDialog<void>(
        context: context,
        builder: (_) => _PaymentMethodFormDialog(
          initial: entry,
          existingEntries: existingEntries,
          onConfirm: (method, methodName, number) async {
            await api.updatePaymentMethod(
              entry.id,
              paymentMethod: method,
              paymentMethodName: methodName,
              paymentNumber: number,
            );
            ref.invalidate(posTerminalProvider);
          },
        ),
      );
    }

    Future<void> onDeletePaymentMethod(int id) async {
      final api = ref.read(posTerminalsApiProvider);
      await api.removePaymentMethod(id);
      ref.invalidate(posTerminalProvider);
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
        child: posTerminalAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: ColorSet.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: ColorSet.danger, size: 40),
                const SizedBox(height: 12),
                Text(
                  e.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: POSColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          data: (terminal) => Form(
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
                        _KioskIdBadge(kioskId: terminal.kioskId),
                        const SizedBox(height: 16),
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
                        _PaymentMethodsSection(
                          paymentMethods: terminal.paymentMethods,
                          onAdd: onAddPaymentMethod,
                          onEdit: onEditPaymentMethod,
                          onDelete: onDeletePaymentMethod,
                        ),
                        if (errorMessage.value != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: errorMessage.value!),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting.value
                                    ? null
                                    : () => Navigator.of(context, rootNavigator: true).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: POSColors.textSecondary,
                                  side: const BorderSide(color: POSColors.borderDefault),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(POSRadius.md),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: isSubmitting.value ? null : onSave,
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
                                        'Save Changes',
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
      ),
    );
  }
}

// ── Payment Methods Section ───────────────────────────────────────────────────

class _PaymentMethodsSection extends StatelessWidget {
  const _PaymentMethodsSection({
    required this.paymentMethods,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PaymentMethodEntryDto> paymentMethods;
  final VoidCallback onAdd;
  final Future<void> Function(PaymentMethodEntryDto) onEdit;
  final Future<void> Function(int) onDelete;

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
        if (paymentMethods.isEmpty)
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
          ...paymentMethods.map(
            (entry) => _PaymentMethodTile(
              entry: entry,
              onEdit: () => onEdit(entry),
              onDelete: () => onDelete(entry.id),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
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

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentMethodEntryDto entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: const Border.fromBorderSide(BorderSide(color: POSColors.borderDefault)),
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
              entry.paymentMethod == 'Other' && entry.paymentMethodName != null
                  ? entry.paymentMethodName!
                  : entry.paymentMethod,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorSet.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (entry.paymentNumber != null)
            Expanded(
              child: Text(
                entry.paymentNumber!,
                style: const TextStyle(fontSize: 13, color: POSColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: POSColors.textTertiary),
            onPressed: onEdit,
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: ColorSet.danger),
            onPressed: onDelete,
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Payment Method Form Dialog ────────────────────────────────────────────────

class _PaymentMethodFormDialog extends HookWidget {
  const _PaymentMethodFormDialog({
    required this.onConfirm,
    this.initial,
    this.existingEntries = const <PaymentMethodEntryDto>[],
  });

  final PaymentMethodEntryDto? initial;
  final Future<void> Function(PaymentMethod method, String? methodName, String? number) onConfirm;
  final List<PaymentMethodEntryDto> existingEntries;

  static const _labels = {
    PaymentMethod.cash: 'Cash',
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
    final existingTypes = existingEntries
        .where((e) => e.paymentMethod != 'Other')
        .map((e) => PaymentMethod.values.firstWhere(
              (m) => m.toValue() == e.paymentMethod,
              orElse: () => PaymentMethod.other,
            ))
        .toSet();
    final existingOtherNames = existingEntries
        .where((e) => e.paymentMethod == 'Other')
        .map((e) => (e.paymentMethodName ?? '').trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final availableMethods = PaymentMethod.values
        .where((m) =>
            m != PaymentMethod.creditCard &&
            (m == PaymentMethod.other || !existingTypes.contains(m)))
        .toList();
    final selectedMethod = useState(
      initial != null
          ? PaymentMethod.values.firstWhere(
              (m) => m.toValue() == initial!.paymentMethod,
              orElse: () => availableMethods.isNotEmpty ? availableMethods.first : PaymentMethod.gCash,
            )
          : (availableMethods.isNotEmpty ? availableMethods.first : PaymentMethod.gCash),
    );
    final methodNameController = useTextEditingController(text: initial?.paymentMethodName ?? '');
    final numberController = useTextEditingController(text: initial?.paymentNumber ?? '');
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
        final number = numberController.text.trim().isNotEmpty ? numberController.text.trim() : null;
        await onConfirm(selectedMethod.value, methodName, number);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        errorMessage.value = e.message;
        isSubmitting.value = false;
      }
    }

    final isEdit = initial != null;

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
                Text(
                  isEdit ? 'Edit Payment Method' : 'Add Payment Method',
                  style: const TextStyle(
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
                  items: availableMethods
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
                    validator: (v) {
                      final trimmed = (v ?? '').trim();
                      if (trimmed.isEmpty) return 'Payment method name is required';
                      if (existingOtherNames.contains(trimmed.toLowerCase())) {
                        return 'A payment method with this name already exists';
                      }
                      return null;
                    },
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
                        onPressed: isSubmitting.value ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: POSColors.textSecondary,
                          side: const BorderSide(color: POSColors.borderDefault),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
                            : Text(
                                isEdit ? 'Update' : 'Add',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
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
                  'POS Terminal Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'View and edit your terminal information.',
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

class _KioskIdBadge extends StatelessWidget {
  const _KioskIdBadge({required this.kioskId});

  final String kioskId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: const Border.fromBorderSide(BorderSide(color: POSColors.borderDefault)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded, size: 16, color: POSColors.textTertiary),
          const SizedBox(width: 8),
          const Text(
            'Kiosk ID',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: POSColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kioskId,
              style: const TextStyle(
                fontSize: 12,
                color: POSColors.textSecondary,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
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
