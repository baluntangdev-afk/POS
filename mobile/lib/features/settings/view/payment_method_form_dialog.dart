import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../entities/payment_method_type.dart';
import '../state/store_info_notifier.dart';

class PaymentMethodFormDialog extends HookConsumerWidget {
  final PaymentMethodsTableData? existing;

  const PaymentMethodFormDialog({super.key, this.existing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardTypes =
        PaymentMethodType.values.where((t) => t != PaymentMethodType.other);
    final otherEntries = (ref.read(paymentMethodsProvider).value ?? const <PaymentMethodsTableData>[])
        .where((m) => m.id != existing?.id);

    final existingTypes = standardTypes
        .where((t) => otherEntries.any((m) => m.label == t.label))
        .toSet();
    final existingOtherNames = otherEntries
        .where((m) => !standardTypes.any((t) => t.label == m.label))
        .map((m) => m.label.trim().toLowerCase())
        .toSet();

    final availableMethods = PaymentMethodType.values
        .where((t) => t == PaymentMethodType.other || !existingTypes.contains(t))
        .toList();

    final initialType = existing == null
        ? availableMethods.first
        : PaymentMethodType.values.firstWhere(
            (t) => t.label == existing!.label,
            orElse: () => PaymentMethodType.other,
          );

    final selectedType = useState(initialType);
    // `availableMethods` is recomputed from live provider data on every rebuild
    // (e.g. each keystroke), so a type the user already picked can stop being
    // valid mid-edit if the payment-methods list finishes loading afterwards.
    // Fall back to a type that's still in the list so the dropdown below never
    // gets handed a value that isn't one of its items.
    final currentType = availableMethods.contains(selectedType.value)
        ? selectedType.value
        : availableMethods.first;
    final methodNameCtrl = useTextEditingController(
      text: initialType == PaymentMethodType.other ? (existing?.label ?? '') : '',
    );
    final numberCtrl = useTextEditingController(text: existing?.accountNumber ?? '');
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isSaving = useState(false);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      isSaving.value = true;
      try {
        final label = currentType == PaymentMethodType.other
            ? methodNameCtrl.text.trim()
            : currentType.label;
        final accountNumber = numberCtrl.text.trim();
        if (existing == null) {
          await ref.read(paymentMethodsProvider.notifier).create(
                label: label,
                accountNumber: accountNumber.isEmpty ? null : accountNumber,
              );
        } else {
          await ref.read(paymentMethodsProvider.notifier).edit(
                id: existing!.id,
                label: label,
                accountNumber: accountNumber.isEmpty ? null : accountNumber,
              );
        }
        if (!context.mounted) return;
        Navigator.of(context).pop();
      } finally {
        if (context.mounted) isSaving.value = false;
      }
    }

    return AlertDialog(
      title: Text(existing == null ? 'Add Payment Method' : 'Edit Payment Method'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<PaymentMethodType>(
              initialValue: currentType,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: availableMethods
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) {
                if (t == null) return;
                selectedType.value = t;
                methodNameCtrl.clear();
                numberCtrl.clear();
              },
            ),
            if (currentType == PaymentMethodType.other) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: methodNameCtrl,
                decoration: const InputDecoration(labelText: 'Payment Method Name'),
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
            if (currentType != PaymentMethodType.cash) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(labelText: 'Payment Number (optional)'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving.value ? null : submit,
          child: isSaving.value
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(existing == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
