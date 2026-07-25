import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/state/auth_providers.dart';

class RefundAuthDialog extends ConsumerStatefulWidget {
  const RefundAuthDialog({super.key});

  @override
  ConsumerState<RefundAuthDialog> createState() => _RefundAuthDialogState();
}

class _RefundAuthDialogState extends ConsumerState<RefundAuthDialog> {
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .verifySupervisorPin(_pinCtrl.text.trim());
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Invalid PIN or insufficient permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supervisor Authorization Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Supervisor / Admin PIN',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Authorize'),
        ),
      ],
    );
  }
}
