# Store Details Inline Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mobile first-run "Store Details" check's navigation-to-screen behavior with an inline-form dialog, mirroring kiosk's `RegisterPosTerminalDialog`, per the design decision in `docs/superpowers/specs/2026-07-31-first-run-setup-wizard-design.md`.

**Architecture:** Add one new dialog widget (`StoreDetailsDialog` + `showStoreDetailsDialog()`) under `mobile/lib/features/dashboard/view/`, styled with the mobile app's existing `AppColors`/`AppSpacing`/`AppTextStyles` tokens and `storeInfoProvider` for persistence. Wire it into `dashboard_screen.dart`'s existing `checkAndShowStoreDetailsDialog()` in place of the current `showSetupPromptDialog` + `context.push('/settings/store-info')` call. Everything else in the first-run chain (kiosk side, mobile Employees/Products checks, `setup_prompt_dialog.dart`, `StoreInfoScreen`) is already implemented and unchanged.

**Tech Stack:** Flutter, Hooks Riverpod (`hooks_riverpod`, `flutter_hooks`), Drift (`storeInfoProvider` → `StoreInfoNotifier.save()`).

---

## Context worth knowing before starting

- `mobile/lib/features/dashboard/view/dashboard_screen.dart` already contains the full three-check chain (Store Details / Employees / Products) with `useRef` "shown" flags and `ref.listen`, matching kiosk's pattern. Only the **Store Details** check's action needs to change.
- `mobile/lib/widgets/setup_prompt_dialog.dart` (message-only dialog, no form fields) already exists and is correctly used for the Employees and Products checks — do not touch it.
- `mobile/lib/features/settings/state/store_info_notifier.dart` exposes `storeInfoProvider` (`AsyncNotifierProvider<StoreInfoNotifier, StoreInfoTableData?>`) with a `save({required storeName, required address, required taxRate, required currency, required receiptFooter, required tin, required terminalName})` method — **all seven params are required**, so the dialog must pass through the existing values for fields it doesn't show (taxRate, currency, receiptFooter, terminalName) rather than blanking them.
- `mobile/lib/features/settings/view/store_info_screen.dart` is the full settings-screen form (all fields + payment methods) and stays as-is for post-setup editing — not part of this plan.
- Reference implementation to mirror the shape of (not copy verbatim — different design tokens): `kiosk/lib/features/menu/view/register_pos_terminal_dialog.dart`.
- Mobile has no widget-test setup (`mobile/test/` doesn't exist) and no established testing convention for dialogs — verification for this plan is `dart analyze` plus a manual run-through, not automated tests.

---

## File Structure

- Create: `mobile/lib/features/dashboard/view/store_details_dialog.dart` — `showStoreDetailsDialog()` entry point + `StoreDetailsDialog` `HookConsumerWidget` (Store Name / Address / TIN form, Save / Sign Out buttons).
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart:80-107` — `checkAndShowStoreDetailsDialog()` calls the new dialog instead of `showSetupPromptDialog(...)`.

---

### Task 1: Create the inline Store Details dialog

**Files:**
- Create: `mobile/lib/features/dashboard/view/store_details_dialog.dart`

- [ ] **Step 1: Write the dialog widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl = useTextEditingController();
    final addressCtrl = useTextEditingController();
    final tinCtrl = useTextEditingController();
    final isSubmitting = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> onSave() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      isSubmitting.value = true;
      errorMessage.value = null;
      try {
        final existing = ref.read(storeInfoProvider).value;
        await ref.read(storeInfoProvider.notifier).save(
              storeName: nameCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              tin: tinCtrl.text.trim(),
              taxRate: existing?.taxRate ?? 0.0,
              currency: existing?.currency ?? 'PHP',
              receiptFooter: existing?.receiptFooter ?? '',
              terminalName: existing?.terminalName ?? '',
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
        width: 400,
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
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
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
```

- [ ] **Step 2: Run static analysis on the new file**

Run: `cd mobile && dart analyze lib/features/dashboard/view/store_details_dialog.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/features/dashboard/view/store_details_dialog.dart
git commit -m "feat: add inline store details dialog for mobile first-run setup"
```

---

### Task 2: Wire the dialog into the dashboard's Store Details check

**Files:**
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart:9` (imports), `:80-107` (`checkAndShowStoreDetailsDialog`)

- [ ] **Step 1: Swap the import**

In `mobile/lib/features/dashboard/view/dashboard_screen.dart`, replace:

```dart
import '../../../widgets/setup_prompt_dialog.dart';
```

with:

```dart
import '../../../widgets/setup_prompt_dialog.dart';
import 'store_details_dialog.dart';
```

(keep `setup_prompt_dialog.dart` — the Employees and Products checks still use it)

- [ ] **Step 2: Replace the Store Details check body**

Replace:

```dart
    void checkAndShowStoreDetailsDialog() {
      if (hasShownStoreDetailsDialog.value) return;
      if (user?.isAdmin != true) return;

      final storeState = ref.read(storeInfoProvider);
      if (storeState.isLoading || storeState.hasError) return;
      final info = storeState.value;
      if (info == null || info.storeName.trim().isNotEmpty) return;

      hasShownStoreDetailsDialog.value = true;
      unawaited(showSetupPromptDialog(
        context,
        title: 'Store Details Not Set Up',
        message: 'Set up your store details before operating the system.',
        type: SetupPromptType.warning,
        primaryButtonText: 'Set Up Store',
        secondaryButtonText: 'Sign Out',
        barrierDismissible: false,
        onPrimaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push('/settings/store-info');
        },
        onSecondaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          ref.read(authNotifierProvider.notifier).logout();
        },
      ));
    }
```

with:

```dart
    void checkAndShowStoreDetailsDialog() {
      if (hasShownStoreDetailsDialog.value) return;
      if (user?.isAdmin != true) return;

      final storeState = ref.read(storeInfoProvider);
      if (storeState.isLoading || storeState.hasError) return;
      final info = storeState.value;
      if (info == null || info.storeName.trim().isNotEmpty) return;

      hasShownStoreDetailsDialog.value = true;
      unawaited(showStoreDetailsDialog(
        context,
        onSignOut: () => ref.read(authNotifierProvider.notifier).logout(),
      ));
    }
```

- [ ] **Step 3: Run static analysis on the whole file**

Run: `cd mobile && dart analyze lib/features/dashboard/view/dashboard_screen.dart`
Expected: `No issues found!` (confirms `context.push` import for go_router is still used elsewhere in the file for Employees/Products checks — if analyze flags an unused import, check whether `package:go_router/go_router.dart` is still needed; it is, since Employees/Products checks still call `context.push`)

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/dashboard/view/dashboard_screen.dart
git commit -m "feat: show inline store details dialog instead of navigating to settings"
```

---

## What is NOT changing

| Item | Reason |
|---|---|
| Kiosk (`menu_screen.dart`, `message_dialog.dart`, `register_pos_terminal_dialog.dart`) | Already implemented and correct — untouched by this plan |
| `mobile/lib/widgets/setup_prompt_dialog.dart` | Still used by Employees and Products checks |
| `mobile/lib/features/settings/view/store_info_screen.dart` | Stays as the full post-setup editing screen, unchanged |
| `mobile/lib/features/settings/state/store_info_notifier.dart` | Existing `save()` signature is reused as-is, no changes needed |
