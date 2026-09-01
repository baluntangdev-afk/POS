import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/services/report_email_recipients.dart';

/// Shows the add-chip recipient dialog. Returns the chosen recipient list, or
/// `null` if the user cancelled. The list is guaranteed non-empty on a non-null
/// return. Persisting the list is the caller's job (do it only on a real send).
Future<List<String>?> showReportEmailRecipientsDialog(BuildContext context) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => const _ReportEmailRecipientsDialog(),
  );
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _ReportEmailRecipientsDialog extends HookWidget {
  const _ReportEmailRecipientsDialog();

  @override
  Widget build(BuildContext context) {
    final recipients = useState<List<String>>(const []);
    final controller = useTextEditingController();
    final error = useState<String?>(null);

    useEffect(() {
      ReportEmailRecipients.load().then((saved) {
        if (recipients.value.isEmpty) recipients.value = saved;
      });
      return null;
    }, const []);

    useListenable(controller);

    void addFromField() {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      if (!_emailRegex.hasMatch(value)) {
        error.value = 'Enter a valid email address';
        return;
      }
      if (recipients.value.contains(value)) {
        error.value = 'Already added';
        return;
      }
      recipients.value = [...recipients.value, value];
      controller.clear();
      error.value = null;
    }

    void remove(String email) {
      recipients.value =
          recipients.value.where((e) => e != email).toList(growable: false);
    }

    return AlertDialog(
      scrollable: true,
      title: const Text('Email transactions CSV'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipients.value.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final email in recipients.value)
                    InputChip(
                      label: Text(email),
                      onDeleted: () => remove(email),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => addFromField(),
              onChanged: (_) {
                if (error.value != null) error.value = null;
              },
              decoration: InputDecoration(
                labelText: 'Add recipient',
                hintText: 'name@example.com',
                errorText: error.value,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addFromField,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (recipients.value.isNotEmpty ||
                  controller.text.trim().isNotEmpty)
              ? () {
                  addFromField();
                  if (recipients.value.isNotEmpty) {
                    Navigator.of(context).pop(recipients.value);
                  }
                }
              : null,
          child: const Text('Send'),
        ),
      ],
    );
  }
}
