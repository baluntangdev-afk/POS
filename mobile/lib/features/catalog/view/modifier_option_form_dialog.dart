import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_spacing.dart';
import '../state/modifier_groups_notifier.dart';

/// Create/edit dialog for a single option belonging to a modifier group.
///
/// [existing] is `null` for create-mode; passing a [ModifierOptionsTableData]
/// switches to edit-mode.
class ModifierOptionFormDialog extends ConsumerStatefulWidget {
  final int productId;
  final int groupId;
  final ModifierOptionsTableData? existing;

  const ModifierOptionFormDialog({
    super.key,
    required this.productId,
    required this.groupId,
    this.existing,
  });

  @override
  ConsumerState<ModifierOptionFormDialog> createState() => _ModifierOptionFormDialogState();
}

class _ModifierOptionFormDialogState extends ConsumerState<ModifierOptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  String? _errorText;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController =
        TextEditingController(text: existing != null ? _formatPrice(existing.additionalPrice) : '0');
  }

  String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final additionalPrice = double.parse(_priceController.text.trim());

    setState(() => _isSaving = true);
    try {
      final actions = ref.read(modifierGroupsActionsProvider(widget.productId));
      if (_isEditing) {
        await actions.updateOption(
          optionId: widget.existing!.id,
          name: name,
          additionalPrice: additionalPrice,
        );
      } else {
        await actions.createOption(
          groupId: widget.groupId,
          name: name,
          additionalPrice: additionalPrice,
        );
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
      title: Text(_isEditing ? 'Edit Option' : 'Add Option'),
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
                  errorText: _errorText,
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Additional Price', prefixText: 'PHP '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Additional price is required';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) return 'Enter a valid price (0 or more)';
                  return null;
                },
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
