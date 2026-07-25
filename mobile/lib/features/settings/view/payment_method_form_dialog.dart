import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../state/store_info_notifier.dart';

class PaymentMethodFormDialog extends HookConsumerWidget {
  final PaymentMethodsTableData? existing;

  const PaymentMethodFormDialog({super.key, this.existing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelCtrl = useTextEditingController(text: existing?.label ?? '');
    final accountNameCtrl = useTextEditingController(text: existing?.accountName ?? '');
    final accountNumberCtrl = useTextEditingController(text: existing?.accountNumber ?? '');
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isSaving = useState(false);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      isSaving.value = true;
      try {
        final label = labelCtrl.text.trim();
        final accountName = accountNameCtrl.text.trim();
        final accountNumber = accountNumberCtrl.text.trim();
        if (existing == null) {
          await ref.read(paymentMethodsProvider.notifier).create(
                label: label,
                accountName: accountName.isEmpty ? null : accountName,
                accountNumber: accountNumber.isEmpty ? null : accountNumber,
              );
        } else {
          await ref.read(paymentMethodsProvider.notifier).edit(
                id: existing!.id,
                label: label,
                accountName: accountName.isEmpty ? null : accountName,
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
          children: [
            TextFormField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label (e.g. GCash, Bank Transfer)'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Label is required' : null,
            ),
            TextFormField(
              controller: accountNameCtrl,
              decoration: const InputDecoration(labelText: 'Account Name (optional)'),
            ),
            TextFormField(
              controller: accountNumberCtrl,
              decoration: const InputDecoration(labelText: 'Account Number (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving.value ? null : submit,
          child: isSaving.value
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
