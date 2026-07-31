import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/payment_methods_card.dart';
import '../../../widgets/section_card.dart';
import '../state/store_info_notifier.dart';

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
            const PaymentMethodsCard(),
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
