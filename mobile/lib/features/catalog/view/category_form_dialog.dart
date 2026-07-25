import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../state/catalog_notifier.dart';

/// Create/edit dialog for a product category (a.k.a. "group").
///
/// [existing] is `null` for create-mode; passing a [ProductGroupsTableData]
/// switches to edit-mode. We need the raw table row here (rather than the
/// lighter [CatalogGroup] entity) because [CatalogGroup] doesn't expose
/// `isActive` — that's a DAO/table-level concept the edit form needs to show
/// and let the user toggle.
class CategoryFormDialog extends ConsumerStatefulWidget {
  final ProductGroupsTableData? existing;

  const CategoryFormDialog({super.key, this.existing});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isActive;
  String? _nameError;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _nameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(catalogNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateCategory(
          id: widget.existing!.id,
          name: name,
          isActive: _isActive,
        );
      } else {
        await notifier.createCategory(name: name);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on StateError catch (e) {
      setState(() => _nameError = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'Add Category'),
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
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: _nameError,
                ),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              if (_isEditing) ...[
                const Gap(AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
