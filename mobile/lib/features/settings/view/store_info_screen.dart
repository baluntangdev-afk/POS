import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/payment_methods_card.dart';
import '../../../widgets/section_card.dart';
import '../../live_orders/state/merchant_device_notifier.dart';
import '../../live_orders/view/device_registration_prompt.dart';
import '../state/store_info_notifier.dart';

const _storeIdAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateStoreId() {
  final random = Random.secure();
  return List.generate(
    8,
    (_) => _storeIdAlphabet[random.nextInt(_storeIdAlphabet.length)],
  ).join();
}

class StoreInfoScreen extends HookConsumerWidget {
  const StoreInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(storeInfoProvider);

    // Surfaces the device-registration outcome kicked off by saving store
    // info here. De-duplicated with the dashboard listener — only one dialog.
    ref.listen(merchantDeviceNotifierProvider, (prev, next) {
      handleMerchantDeviceOutcome(context, prev?.value, next.value);
    });

    return infoAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Store Information')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    '$e',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(AppSpacing.lg),
                  FilledButton(
                    onPressed: () => ref.invalidate(storeInfoProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: (info) {
        if (info == null || info.storeId.isEmpty) {
          return _StoreIdSetupGate(
            onConfirm:
                (storeId) => ref
                    .read(storeInfoProvider.notifier)
                    .save(
                      storeId: storeId,
                      storeName: info?.storeName ?? '',
                      address: info?.address ?? '',
                      taxRate: info?.taxRate ?? 0.0,
                      currency: info?.currency ?? 'PHP',
                      receiptFooter: info?.receiptFooter ?? '',
                      tin: info?.tin ?? '',
                      terminalName: info?.terminalName ?? '',
                    ),
          );
        }
        return _StoreInfoForm(
          initialStoreId: info.storeId,
          initialName: info.storeName,
          initialAddress: info.address,
          initialTaxRate: info.taxRate,
          initialCurrency: info.currency,
          initialFooter: info.receiptFooter,
          initialTin: info.tin,
          initialTerminalName: info.terminalName,
          onSave: (
            storeId,
            name,
            address,
            taxRate,
            currency,
            footer,
            tin,
            terminalName,
          ) async {
            await ref
                .read(storeInfoProvider.notifier)
                .save(
                  storeId: storeId,
                  storeName: name,
                  address: address,
                  taxRate: taxRate,
                  currency: currency,
                  receiptFooter: footer,
                  tin: tin,
                  terminalName: terminalName,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Store info saved')));
            }
          },
        );
      },
    );
  }
}

/// Shown when the local store has no ID saved yet. Blocks the screen
/// behind a required, non-dismissible dialog until one is confirmed.
class _StoreIdSetupGate extends HookWidget {
  const _StoreIdSetupGate({required this.onConfirm});

  final Future<void> Function(String storeId) onConfirm;

  @override
  Widget build(BuildContext context) {
    final dialogShown = useRef(false);

    useEffect(() {
      if (!dialogShown.value) {
        dialogShown.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => _StoreIdInputDialog(onConfirm: onConfirm),
            );
          }
        });
      }
      return null;
    }, const []);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _StoreIdInputDialog extends HookWidget {
  const _StoreIdInputDialog({required this.onConfirm});

  final Future<void> Function(String storeId) onConfirm;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: generateStoreId());
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final saving = useState(false);

    Future<void> confirm() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      saving.value = true;
      await onConfirm(controller.text.trim());
      if (context.mounted) Navigator.of(context).pop();
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Set Store ID'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This store needs a unique ID. A suggested ID has been filled in — '
                'accept it or type your own.',
              ),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Store ID',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator:
                    (v) =>
                        (v?.trim().isEmpty ?? true)
                            ? 'Store ID is required'
                            : null,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: saving.value ? null : confirm,
            child:
                saving.value
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StoreInfoForm extends HookConsumerWidget {
  final String initialStoreId;
  final String initialName;
  final String initialAddress;
  final double initialTaxRate;
  final String initialCurrency;
  final String initialFooter;
  final String initialTin;
  final String initialTerminalName;
  final Future<void> Function(
    String,
    String,
    String,
    double,
    String,
    String,
    String,
    String,
  )
  onSave;

  const _StoreInfoForm({
    required this.initialStoreId,
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
    final storeIdCtrl = useTextEditingController(text: initialStoreId);
    final nameCtrl = useTextEditingController(text: initialName);
    final addressCtrl = useTextEditingController(text: initialAddress);
    final taxRateCtrl = useTextEditingController(
      text: initialTaxRate > 0 ? initialTaxRate.toString() : '',
    );
    final currencyCtrl = useTextEditingController(text: initialCurrency);
    final footerCtrl = useTextEditingController(text: initialFooter);
    final tinCtrl = useTextEditingController(text: initialTin);
    final terminalNameCtrl = useTextEditingController(
      text: initialTerminalName,
    );
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
          storeIdCtrl.text.trim(),
          nameCtrl.text.trim(),
          addressCtrl.text.trim(),
          taxRate,
          currency,
          footerCtrl.text.trim(),
          tinCtrl.text.trim(),
          terminalNameCtrl.text.trim(),
        );
      } finally {
        if (context.mounted) saving.value = false;
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
                  controller: storeIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store ID',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Store ID is required'
                              : null,
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Store name is required'
                              : null,
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
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.touchPreferred,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child:
                  saving.value
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
