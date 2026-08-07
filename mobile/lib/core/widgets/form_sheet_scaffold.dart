import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Bottom-sheet chrome shared by the inventory module's create/edit forms
/// (product, category). Centralizing the handle/header/footer means a
/// phone-width form never has to reinvent — or accidentally diverge from —
/// this shell; only [body] differs between forms.
class FormSheetScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String confirmLabel;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const FormSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.isSaving,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(AppSpacing.sm),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: AppTextStyles.headingMd)),
                      IconButton(
                        onPressed: isSaving ? null : onCancel,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    child: body,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isSaving ? null : onConfirm,
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
