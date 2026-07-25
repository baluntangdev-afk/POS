import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/store_info_notifier.dart';
import 'payment_method_form_dialog.dart';

class StoreInfoScreen extends HookConsumerWidget {
  const StoreInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(storeInfoProvider);

    return infoAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Store Information')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const Gap(AppSpacing.md),
              Text('$e',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const Gap(AppSpacing.lg),
              FilledButton(
                onPressed: () => ref.invalidate(storeInfoProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (info) => _StoreInfoForm(
        initialName: info?.storeName ?? '',
        initialAddress: info?.address ?? '',
        initialTaxRate: info?.taxRate ?? 0.0,
        initialCurrency: info?.currency ?? 'PHP',
        initialFooter: info?.receiptFooter ?? '',
        initialTin: info?.tin ?? '',
        initialTerminalName: info?.terminalName ?? '',
        onSave: (name, address, taxRate, currency, footer, tin, terminalName) async {
          await ref.read(storeInfoProvider.notifier).save(
                storeName: name,
                address: address,
                taxRate: taxRate,
                currency: currency,
                receiptFooter: footer,
                tin: tin,
                terminalName: terminalName,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Store info saved')),
            );
          }
        },
      ),
    );
  }
}

class _StoreInfoForm extends HookConsumerWidget {
  final String initialName;
  final String initialAddress;
  final double initialTaxRate;
  final String initialCurrency;
  final String initialFooter;
  final String initialTin;
  final String initialTerminalName;
  final Future<void> Function(String, String, double, String, String, String, String) onSave;

  const _StoreInfoForm({
    required this.initialName,
    required this.initialAddress,
    required this.initialTaxRate,
    required this.initialCurrency,
    required this.initialFooter,
    required this.initialTin,
    required this.initialTerminalName,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController(text: initialName);
    final addressCtrl = useTextEditingController(text: initialAddress);
    final taxRateCtrl = useTextEditingController(
      text: initialTaxRate > 0 ? initialTaxRate.toString() : '',
    );
    final currencyCtrl = useTextEditingController(text: initialCurrency);
    final footerCtrl = useTextEditingController(text: initialFooter);
    final tinCtrl = useTextEditingController(text: initialTin);
    final terminalNameCtrl = useTextEditingController(text: initialTerminalName);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final saving = useState(false);

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      try {
        final taxRate = double.tryParse(taxRateCtrl.text.trim()) ?? 0.0;
        final currency =
            currencyCtrl.text.trim().isEmpty ? 'PHP' : currencyCtrl.text.trim();
        await onSave(
          nameCtrl.text.trim(),
          addressCtrl.text.trim(),
          taxRate,
          currency,
          footerCtrl.text.trim(),
          tinCtrl.text.trim(),
          terminalNameCtrl.text.trim(),
        );
      } finally {
        saving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Information'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _FormCard(
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
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: tinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'TIN',
                    hintText: '000-000-000-000',
                    border: OutlineInputBorder(),
                  ),
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
            const Gap(AppSpacing.lg),
            const _PaymentMethodsCard(),
            const Gap(AppSpacing.lg),
            _FormCard(
              title: 'Tax & Currency',
              children: [
                TextFormField(
                  controller: taxRateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate',
                    hintText: '0.0',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (double.tryParse(v) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: currencyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol',
                    hintText: 'PHP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            _FormCard(
              title: 'Receipt',
              children: [
                TextFormField(
                  controller: footerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Footer',
                    hintText: 'Thank you for your purchase!',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const Gap(AppSpacing.xl),
            FilledButton(
              onPressed: saving.value ? null : save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: saving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _PaymentMethodsCard extends ConsumerWidget {
  const _PaymentMethodsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PAYMENT METHODS',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const PaymentMethodFormDialog(),
                ),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                tooltip: 'Add Payment Method',
              ),
            ],
          ),
          methodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e', style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            data: (methods) {
              if (methods.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No payment methods added yet.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
                  ),
                );
              }
              return Column(
                children: methods.map((m) {
                  final subtitleParts = [
                    if (m.accountName != null && m.accountName!.isNotEmpty) m.accountName!,
                    if (m.accountNumber != null && m.accountNumber!.isNotEmpty) m.accountNumber!,
                  ];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.label),
                    subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => PaymentMethodFormDialog(existing: m),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => _confirmDelete(context, ref, m.id, m.label),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment method?'),
        content: Text('Remove "$label"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(paymentMethodsProvider.notifier).delete(id);
    }
  }
}
