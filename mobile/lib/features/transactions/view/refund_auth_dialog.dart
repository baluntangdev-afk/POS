import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/entities/user_entity.dart';
import '../../auth/state/auth_providers.dart';

class RefundAuthDialog extends ConsumerStatefulWidget {
  const RefundAuthDialog({super.key});

  @override
  ConsumerState<RefundAuthDialog> createState() => _RefundAuthDialogState();
}

class _RefundAuthDialogState extends ConsumerState<RefundAuthDialog> {
  final _pinCtrl = TextEditingController();
  UserEntity? _selectedAuthorizer;
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authorizer = _selectedAuthorizer;
    if (authorizer == null) {
      setState(() => _error = 'Select an authorizer');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .verifyPinForUser(authorizer.id, _pinCtrl.text.trim());
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
    final authorizersAsync = ref.watch(authorizersProvider);

    return AlertDialog(
      title: const Text('Supervisor Authorization Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          authorizersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Text('Failed to load authorizers: $e'),
            data: (authorizers) => DropdownButtonFormField<UserEntity>(
              initialValue: _selectedAuthorizer,
              decoration: const InputDecoration(labelText: 'Authorizer'),
              items: authorizers
                  .map((u) => DropdownMenuItem(value: u, child: Text('${u.name} (${u.role})')))
                  .toList(),
              onChanged: (u) => setState(() {
                _selectedAuthorizer = u;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
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
