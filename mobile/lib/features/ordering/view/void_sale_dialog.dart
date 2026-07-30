import 'package:flutter/material.dart';

class VoidSaleDialog extends StatefulWidget {
  const VoidSaleDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(context: context, builder: (_) => const VoidSaleDialog());
  }

  @override
  State<VoidSaleDialog> createState() => _VoidSaleDialogState();
}

class _VoidSaleDialogState extends State<VoidSaleDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Void this transaction?'),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _reasonController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reasonController.text.trim()),
          child: const Text('Void'),
        ),
      ],
    );
  }
}
