import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../state/modifier_groups_notifier.dart';

/// Create/edit dialog for a global modifier group.
///
/// [existing] is `null` for create-mode; passing a [ModifierGroupsTableData]
/// switches to edit-mode.
class ModifierGroupFormDialog extends ConsumerStatefulWidget {
  final ModifierGroupsTableData? existing;

  const ModifierGroupFormDialog({super.key, this.existing});

  @override
  ConsumerState<ModifierGroupFormDialog> createState() => _ModifierGroupFormDialogState();
}

class _ModifierGroupFormDialogState extends ConsumerState<ModifierGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _maxSelectionsController;
  late bool _isRequired;
  String? _errorText;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _maxSelectionsController =
        TextEditingController(text: existing != null ? existing.maxSelections.toString() : '1');
    _isRequired = existing?.isRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxSelectionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final maxSelections = int.parse(_maxSelectionsController.text.trim());

    setState(() => _isSaving = true);
    try {
      final actions = ref.read(modifierGroupsManagementActionsProvider);
      if (_isEditing) {
        await actions.updateGroup(
          groupId: widget.existing!.id,
          name: name,
          isRequired: _isRequired,
          maxSelections: maxSelections,
        );
      } else {
        await actions.createGroup(name: name, isRequired: _isRequired, maxSelections: maxSelections);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? 'Edit Modifier Group' : 'Add Modifier Group'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', errorText: _errorText),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: _maxSelectionsController,
                decoration: const InputDecoration(labelText: 'Max Selections'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Max selections is required';
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const Gap(AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Required'),
                value: _isRequired,
                onChanged: (v) => setState(() => _isRequired = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
