import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/payment_methods_card.dart';
import '../../../widgets/section_card.dart';
import '../../settings/state/store_info_notifier.dart';

Future<void> showStoreDetailsDialog(
  BuildContext context, {
  required VoidCallback onSignOut,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StoreDetailsDialog(onSignOut: onSignOut),
  );
}

class StoreDetailsDialog extends HookConsumerWidget {
  const StoreDetailsDialog({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.read(storeInfoProvider).value;

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl = useTextEditingController(text: info?.storeName ?? '');
    final addressCtrl = useTextEditingController(text: info?.address ?? '');
    final tinCtrl = useTextEditingController(text: info?.tin ?? '');
    final terminalNameCtrl = useTextEditingController(text: info?.terminalName ?? '');
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> onSave() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      isSubmitting.value = true;
      errorMessage.value = null;
      try {
        await ref.read(storeInfoProvider.notifier).save(
              storeName: nameCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              tin: tinCtrl.text.trim(),
              terminalName: terminalNameCtrl.text.trim(),
              taxRate: info?.taxRate ?? 0.0,
              currency: info?.currency ?? 'PHP',
              receiptFooter: info?.receiptFooter ?? '',
            );
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        errorMessage.value = '$e';
        isSubmitting.value = false;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Set Up Store', style: AppTextStyles.headingLg),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Set up your store details before operating the system.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    title: 'Basic Info',
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Store name is required' : null,
                      ),
                      const Gap(AppSpacing.md),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Address is required' : null,
                      ),
                      const Gap(AppSpacing.md),
                      TextFormField(
                        controller: tinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'TIN',
                          hintText: '000-000-000-000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'TIN is required' : null,
                      ),
                      const Gap(AppSpacing.md),
                      TextFormField(
                        controller: terminalNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Terminal Name',
                          hintText: 'e.g. Front Counter, Terminal 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const PaymentMethodsCard(),
                  if (errorMessage.value != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        errorMessage.value!,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting.value
                              ? null
                              : () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  onSignOut();
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isSubmitting.value ? null : onSave,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          child: isSubmitting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
