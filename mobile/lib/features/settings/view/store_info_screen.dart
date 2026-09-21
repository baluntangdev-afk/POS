import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/live_orders/use_cases/webhook_auth_error.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/transaction_sync/transaction_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/backend_api/errors/api_exception.dart';
import '../../../widgets/payment_methods_card.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/setup_prompt_dialog.dart';
import '../../live_orders/state/merchant_device_notifier.dart';
import '../../live_orders/view/device_registration_prompt.dart';
import '../../live_orders/view/device_registration_status_card.dart';
import '../state/merchant_verification_provider.dart';
import '../state/store_info_notifier.dart';

const _storeIdAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String storeSaveErrorMessage(Object error) => switch (error) {
  ApiException(:final message) => message,
  WebhookAuthException(:final message) => message,
  VerifiedMerchantLockedException(:final message) => message,
  _ => 'Could not save store info. Try again.',
};

void _showStoreSaveError(BuildContext context, Object error) {
  final message = storeSaveErrorMessage(error);

  if (error is WebhookAuthException &&
      error.reason == WebhookAuthError.invalidRequest) {
    unawaited(
      showSetupPromptDialog(
        context,
        type: SetupPromptType.error,
        title: 'Store Not Recognized',
        message: message,
        primaryButtonText: 'OK',
        barrierDismissible: false,
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
}

Future<bool> shouldOfferDataTransfer(
  WidgetRef ref, {
  required String previousStoreId,
  required String newStoreId,
}) async {
  if (previousStoreId.trim() == newStoreId.trim()) return false;
  final previouslyVerified =
      ref.read(merchantVerificationProvider).value ?? false;
  if (previouslyVerified) return false;
  return ref.read(databaseProvider).salesDao.hasAnyTransactions();
}

/// Shown when the user tries to change the Store ID away from a merchant
/// the backend already recognizes as verified. Proceeding still verifies and
/// registers the device against the new store ID as usual, but any local
/// sale/refund still pending sync under the old merchant is excluded from
/// the next sync batch first, so it isn't pushed under the new store.
Future<bool> confirmReassignVerifiedStoreId(BuildContext context) async {
  var proceed = false;
  await showSetupPromptDialog(
    context,
    type: SetupPromptType.warning,
    title: 'Verified Merchant',
    message:
        '${const VerifiedMerchantLockedException().message} '
        'Proceeding will reassign this device to the new store; any local '
        'sales data still pending sync will not be sent to it.',
    primaryButtonText: 'Proceed',
    secondaryButtonText: 'Cancel',
    barrierDismissible: false,
    onPrimaryPressed: () {
      proceed = true;
      Navigator.of(context).pop();
    },
    onSecondaryPressed: () => Navigator.of(context).pop(),
  );
  return proceed;
}

Future<void> maybeOfferDataTransfer(BuildContext context, WidgetRef ref) {
  return showSetupPromptDialog(
    context,
    type: SetupPromptType.info,
    title: 'Existing Data Found',
    message:
        'This device has local sales data. It will be transferred to the '
        'now-active merchant on the next sync.',
    primaryButtonText: 'Transfer',
    secondaryButtonText: 'Not Now',
    onPrimaryPressed: () async {
      final storeId = ref.read(storeInfoProvider).value?.storeId ?? '';
      await TransactionSyncService.unsyncAll(
        ref.read(databaseProvider),
        storeId,
      );
      if (context.mounted) Navigator.of(context).pop();
    },
    onSecondaryPressed: () => Navigator.of(context).pop(),
  );
}

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

    ref.listen(merchantDeviceNotifierProvider, (prev, next) {
      handleMerchantDeviceOutcome(context, prev?.value, next.value);
    });

    final info = infoAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Store Information'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(context, ref, infoAsync.hasValue, info),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    bool hasValue,
    StoreInfoTableData? info,
  ) {
    // No data yet (first load, or a reload that hasn't landed) → just a spinner.
    if (!hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (info == null || info.storeId.isEmpty) {
      return _StoreIdSetupGate(
        onConfirm: (storeId) async {
          bool verifiedOnline;
          try {
            verifiedOnline = await ref
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
                  // First-run only: a device with no network yet shouldn't
                  // be stuck on this gate. A genuinely rejected store ID
                  // still blocks — see `StoreInfoNotifier.save` doc.
                  allowOfflineSetup: true,
                );
          } catch (error) {
            if (context.mounted) _showStoreSaveError(context, error);
            rethrow;
          }
          if (!verifiedOnline && context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    "Saved. Couldn't reach the server to verify this store "
                    "ID — you can finish setup later once you're back "
                    "online.",
                  ),
                  duration: Duration(seconds: 6),
                ),
              );
          }
        },
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
        var bypassVerifiedLock = false;
        if (storeId.trim() != info.storeId.trim() &&
            (ref.read(merchantVerificationProvider).value ?? false)) {
          if (!context.mounted) return;
          final proceed = await confirmReassignVerifiedStoreId(context);
          if (!proceed) return;
          bypassVerifiedLock = true;
        }

        final offerDataTransfer = await shouldOfferDataTransfer(
          ref,
          previousStoreId: info.storeId,
          newStoreId: storeId,
        );
        bool verifiedOnline;
        try {
          verifiedOnline = await ref
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
                bypassVerifiedLock: bypassVerifiedLock,
              );
        } catch (error) {
          // A rejected store ID (e.g. an unknown merchant) leaves the
          // previous store info untouched — show why it wasn't saved
          // instead of claiming success.
          if (context.mounted) _showStoreSaveError(context, error);
          return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Store info saved')));
        }
        if (verifiedOnline && offerDataTransfer && context.mounted) {
          await maybeOfferDataTransfer(context, ref);
        }
      },
    );
  }
}

/// Shown when the local store has no ID saved yet. Sits behind a required,
/// non-dismissible dialog until one is confirmed.
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

    return const Center(child: CircularProgressIndicator());
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
      try {
        await onConfirm(controller.text.trim());
        if (context.mounted) Navigator.of(context).pop();
      } catch (_) {
        // Error already surfaced by onConfirm; keep the dialog open so the
        // user can fix the ID and retry.
        if (context.mounted) saving.value = false;
      }
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
                decoration: InputDecoration(
                  labelText: 'Store ID',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Generate a new ID',
                    onPressed: () => controller.text = generateStoreId(),
                  ),
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
    final merchantVerified =
        ref.watch(merchantVerificationProvider).value ?? false;

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

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (merchantVerified) ...[
            const DeviceRegistrationStatusCard(),
            const Gap(AppSpacing.lg),
          ],
          SectionCard(
            title: 'Basic Info',
            children: [
              TextFormField(
                controller: storeIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Store ID',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Generate a new ID',
                    onPressed: () => storeIdCtrl.text = generateStoreId(),
                  ),
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
    );
  }
}
