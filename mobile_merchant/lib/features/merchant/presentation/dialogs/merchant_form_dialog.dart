import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

String generateMerchantId() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  return List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Shared dialog for merchant registration (no existing merchant) and editing
/// (settings). Controlled entirely via callbacks — no Riverpod dependency.
///
/// [initialMerchantId] / [initialMerchantName] — pre-fill values for edit mode.
/// [isRegistration] — when true the dialog is non-dismissible and the action
///   button reads "Register"; when false it reads "Save" and can be dismissed.
class MerchantFormDialog extends StatefulWidget {
  const MerchantFormDialog({
    required this.onSubmit,
    this.initialMerchantId,
    this.initialMerchantName,
    this.isRegistration = true,
    super.key,
  });

  final Future<void> Function(String merchantId, String merchantName) onSubmit;
  final String? initialMerchantId;
  final String? initialMerchantName;
  final bool isRegistration;

  @override
  State<MerchantFormDialog> createState() => _MerchantFormDialogState();
}

class _MerchantFormDialogState extends State<MerchantFormDialog> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(
      text: widget.initialMerchantId ?? generateMerchantId(),
    );
    _nameCtrl = TextEditingController(
      text: widget.initialMerchantName ?? '',
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(
        _idCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRegistration ? 'Register Merchant' : 'Merchant Settings';
    final actionLabel = widget.isRegistration ? 'Register' : 'Save';

    return PopScope(
      canPop: !widget.isRegistration,
      child: AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isRegistration) ...[
                  const Text(
                    'Set up your merchant profile to get started. '
                    'The Merchant ID has been pre-filled — accept it or type your own.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                ],
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: Colors.red.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 16),
                        const Gap(AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.md),
                ],
                _FieldLabel('Merchant ID'),
                const Gap(AppSpacing.xs),
                TextFormField(
                  controller: _idCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. ABCD1234EF',
                    prefixIcon: Icon(Icons.tag_rounded, size: 18),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Merchant ID is required' : null,
                ),
                const Gap(AppSpacing.md),
                _FieldLabel('Merchant Name'),
                const Gap(AppSpacing.xs),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Juan\'s Store',
                    prefixIcon: Icon(Icons.business_rounded, size: 18),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Merchant name is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (!widget.isRegistration)
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
