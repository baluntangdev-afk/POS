# Mobile Cashier UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the kiosk-derived elevation/gradient design language (approved in the `mobile-redesign.html` artifact) to the mobile cashier app's existing screens, without changing any routes, providers, validation, or business logic.

**Architecture:** Introduce two new shared token files (`app_shadows.dart`, `app_gradients.dart`) mirroring the kiosk's `POSShadow`/`POSGradient` tokens, then swap the ad-hoc `boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.0X), ...)]` blocks that are duplicated across ~13 files for the shared `AppShadows.card` token, plus apply the brand gradient to the two highest-visibility flat-color surfaces (cart bar, login avatars). Every change is a `decoration:`/`style:` swap inside an existing `build()` method — no widget is restructured, no callback signature changes, no new state.

**Explicitly excluded (per user instruction — do not touch):**
- `mobile/lib/features/ordering/view/receipt_screen.dart` — receipt preview format stays exactly as-is
- `mobile/lib/features/reports/view/reports_screen.dart`, `sales_bar_chart.dart`, `sales_donut_chart.dart`, `sales_health_tab.dart` — reports preview format stays exactly as-is

**Tech Stack:** Flutter 3, Riverpod/Hooks (unaffected — this is a pure `Widget build()` styling pass), `dart analyze` for verification (this codebase has no widget-test coverage for these screens, so verification is analyze + visual run rather than unit tests — see Verification Note below).

**Verification Note (adapted from standard TDD flow):** These are `BoxDecoration`/`style` value swaps in existing widgets with no new branching logic, and the project has no widget tests for these screens. Each task's steps are: make the edit → `dart analyze` (must be clean) → run the app and visually confirm the screen still renders/functions identically aside from the visual polish → commit. Do not write new widget tests for this pass; that would test decoration pixel values, which is not valuable.

---

## File Structure

| File | Responsibility |
|---|---|
| `mobile/lib/core/theme/app_shadows.dart` | **New.** `AppShadows.card` / `AppShadows.elevated` — shared elevation tokens |
| `mobile/lib/core/theme/app_gradients.dart` | **New.** `AppGradients.primary` — brand diagonal gradient for CTAs/avatars |
| `mobile/lib/widgets/section_card.dart` | Modify — shadow token (auto-covers Store Info + Printer Setup screens, which both use `SectionCard`) |
| `mobile/lib/features/settings/view/settings_screen.dart` | Modify — `_SettingsTile` shadow token |
| `mobile/lib/features/settings/view/csv_import_screen.dart` | Modify — `_ImportCard` shadow token |
| `mobile/lib/features/transactions/view/transactions_screen.dart` | Modify — `_TransactionTile` shadow token + status pill |
| `mobile/lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart` | Modify — `_HubCard` shadow token |
| `mobile/lib/features/inventory/view/inventory_screen.dart` | Modify — chip row + `_ProductCard` shadow token |
| `mobile/lib/features/users/view/users_screen.dart` | Modify — `_UserCard` shadow token |
| `mobile/lib/features/transactions/view/refund_screen.dart` | Modify — `_RefundItemRow` shadow token |
| `mobile/lib/features/ordering/view/ordering_screen.dart` | Modify — `_ProductCard` shadow, `_CartBar` gradient |
| `mobile/lib/features/auth/view/login_screen.dart` | Modify — `_UserGrid` card shadow, avatar gradient |
| `mobile/lib/features/ordering/view/cash_payment_sheet.dart` | Modify — total-due summary card shadow |
| `mobile/lib/features/ordering/view/discount_screen.dart` | Modify — selected-items summary container shadow |
| `mobile/lib/features/transactions/view/void_transaction_dialog.dart` | Modify — dialog icon chip shadow |
| `mobile/lib/features/ordering/view/modifier_dialog.dart` | Modify — quantity/confirm footer shadow |

---

### Task 1: Shared elevation tokens

**Files:**
- Create: `mobile/lib/core/theme/app_shadows.dart`

- [ ] **Step 1: Create the token file**

```dart
import 'package:flutter/material.dart';

/// Shared elevation tokens, mirrored from the kiosk app's `POSShadow`
/// (kiosk/lib/theme/pos_design.dart) so both apps read as one product.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd mobile && dart analyze lib/core/theme/app_shadows.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/core/theme/app_shadows.dart
git commit -m "feat(mobile): add shared AppShadows elevation tokens"
```

---

### Task 2: Shared gradient tokens

**Files:**
- Create: `mobile/lib/core/theme/app_gradients.dart`

- [ ] **Step 1: Create the token file**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared gradient tokens, mirrored from the kiosk app's `POSGradient`
/// (kiosk/lib/theme/pos_design.dart) so both apps read as one product.
abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd mobile && dart analyze lib/core/theme/app_gradients.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/core/theme/app_gradients.dart
git commit -m "feat(mobile): add shared AppGradients token"
```

---

### Task 3: SectionCard shadow token (covers Store Info + Printer Setup)

**Files:**
- Modify: `mobile/lib/widgets/section_card.dart:1-27`

- [ ] **Step 1: Import the new token and swap the shadow**

In `mobile/lib/widgets/section_card.dart`, add the import after line 6:

```dart
import '../core/theme/app_shadows.dart';
```

Then replace lines 17-27:

```dart
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
```

with:

```dart
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.card,
      ),
```

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/widgets/section_card.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

Run: `flutter run -d windows`, sign in as admin, open Settings → Store Information and Settings → Printer Setup. Both screens use `SectionCard` — confirm the section cards now show a softer, deeper shadow and every field/toggle still works (save, scan, connect).

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/widgets/section_card.dart
git commit -m "style(mobile): use shared AppShadows token on SectionCard"
```

---

### Task 4: Settings screen tile shadow

**Files:**
- Modify: `mobile/lib/features/settings/view/settings_screen.dart:1-111`

- [ ] **Step 1: Import and swap**

Add import after line 6:

```dart
import '../../../core/theme/app_shadows.dart';
```

Replace lines 101-111:

```dart
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
```

with:

```dart
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
```

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/features/settings/view/settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

`flutter run -d windows`, go to Settings. Tapping "Import CSV", "Store Information", "Printer Setup" must still navigate to the same three routes.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/settings/view/settings_screen.dart
git commit -m "style(mobile): use shared AppShadows token on settings tiles"
```

---

### Task 5: CSV import card shadow

**Files:**
- Modify: `mobile/lib/features/settings/view/csv_import_screen.dart`

- [ ] **Step 1: Import and swap**

Add import after the existing theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

Find the `_ImportCard` decoration (around line 147) that reads:

```dart
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
```

Replace with:

```dart
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
```

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/features/settings/view/csv_import_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

`flutter run -d windows`, Settings → Import CSV. Confirm the four importer cards render with the new shadow and the file-picker/import buttons still work.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/settings/view/csv_import_screen.dart
git commit -m "style(mobile): use shared AppShadows token on CSV import cards"
```

---

### Task 6: Transactions tile — shadow + status pill

**Files:**
- Modify: `mobile/lib/features/transactions/view/transactions_screen.dart:1-203`

The mockup replaces the plain-text status ("Completed" / "Refunded" / "Voided") with a colored pill, matching the pattern already used elsewhere in the app (e.g. `users_screen.dart`'s role badge). This is a pure presentation change — `statusColor`/`statusLabel` computation and `onTap`/`onVoid` wiring are untouched.

- [ ] **Step 1: Import the shadow token**

Add import after line 9:

```dart
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Swap the card shadow**

Replace lines 156-166:

```dart
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
```

with:

```dart
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
```

- [ ] **Step 3: Replace the plain status text with a pill**

Replace lines 186-195:

```dart
                  Text(
                    '₱${tx.netTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.headingSm,
                  ),
                  Text(
                    statusLabel,
                    style: AppTextStyles.bodySm.copyWith(color: statusColor),
                  ),
                ],
              ),
```

with:

```dart
                  Text(
                    '₱${tx.netTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.headingSm,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.bodySm.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
```

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/transactions/view/transactions_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Visually confirm**

`flutter run -d windows`, open Transactions. Confirm: search, date filter, infinite scroll (load more), tapping a row (navigates to `/transactions/:id`), and the void action from the trailing menu all behave exactly as before — only the status now renders as a colored pill instead of plain colored text.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/transactions/view/transactions_screen.dart
git commit -m "style(mobile): elevate transaction tiles and pill-style status"
```

---

### Task 7: Cashier Accounting hub card shadow

**Files:**
- Modify: `mobile/lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart:1-153`

- [ ] **Step 1: Import and swap**

Add import after line 8:

```dart
import '../../../core/theme/app_shadows.dart';
```

Replace lines 115-117:

```dart
          boxShadow: [
            BoxShadow(color: AppColors.shadow.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 2)),
          ],
```

with:

```dart
          boxShadow: AppShadows.card,
```

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

`flutter run -d windows`, open Cashier Accounting. Confirm X-Reading / Daily Report / Z-Reading cards still navigate to their `route` and `historyRoute` correctly via the card tap and the "History" text button.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart
git commit -m "style(mobile): use shared AppShadows token on accounting hub cards"
```

---

### Task 8: Inventory — chip row + product card shadow

**Files:**
- Modify: `mobile/lib/features/inventory/view/inventory_screen.dart`

- [ ] **Step 1: Import the token**

Add near the other theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Swap the category chip row shadow**

Find (around line 149-157):

```dart
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
```

Replace the `boxShadow` block (keep `color`/`borderRadius`) with:

```dart
              boxShadow: AppShadows.card,
```

(delete the now-redundant closing `],` for the old list)

- [ ] **Step 3: Swap the product card shadow**

Find the matching block inside `_ProductCard` (around line 323-330) — identical shape — and apply the same replacement: `boxShadow: [ BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2)) ]` → `boxShadow: AppShadows.card`.

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/inventory/view/inventory_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Visually confirm**

`flutter run -d windows`, sign in as admin, open Inventory. Confirm Products/Categories tabs, the availability toggle button, and the FAB → product form dialog all still work.

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/inventory/view/inventory_screen.dart
git commit -m "style(mobile): use shared AppShadows token on inventory cards"
```

---

### Task 9: Users screen card shadow

**Files:**
- Modify: `mobile/lib/features/users/view/users_screen.dart`

- [ ] **Step 1: Import and swap**

Add import near the other theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

Find (around line 305-312):

```dart
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
```

Replace with:

```dart
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppShadows.card,
        ),
```

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/features/users/view/users_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

`flutter run -d windows`, sign in as admin, open Users. Confirm edit/reset-PIN/delete actions on a user card still open their respective dialogs.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/users/view/users_screen.dart
git commit -m "style(mobile): use shared AppShadows token on user cards"
```

---

### Task 10: Refund screen item row shadow

**Files:**
- Modify: `mobile/lib/features/transactions/view/refund_screen.dart`

- [ ] **Step 1: Import and add shadow**

Add import near the other theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

Find the `_RefundItemRow` container decoration (around line 139-145):

```dart
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isRefunded ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
```

Add a `boxShadow` line right after `borderRadius`:

```dart
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isRefunded ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: isRefunded ? null : AppShadows.card,
```

(kept conditional so already-refunded rows, shown at reduced opacity, don't get a shadow that reads oddly against the dimmed fill)

- [ ] **Step 2: Verify**

Run: `cd mobile && dart analyze lib/features/transactions/view/refund_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Visually confirm**

`flutter run -d windows`, open a transaction → Refund. Confirm item selection checkboxes, quantity change, reason field, refund method selector, and the "Refund" button (with its confirmation flow) are unchanged.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/transactions/view/refund_screen.dart
git commit -m "style(mobile): add card elevation to refund item rows"
```

---

### Task 11: Ordering screen — product card shadow + cart bar gradient

**Files:**
- Modify: `mobile/lib/features/ordering/view/ordering_screen.dart`

- [ ] **Step 1: Import the new tokens**

Add near the other theme imports (after the `app_spacing.dart` import around line 9):

```dart
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Give `_ProductCard` a shadow**

Replace (around lines 334-338):

```dart
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
```

with:

```dart
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
```

Because this adds one level of nesting (`Container` wrapping `Material`), the matching closing parens at the end of `build()` (currently `);` `}` `}` after the `Column` closes, around lines 421-424) need one more closing paren+brace. Replace:

```dart
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
```

with:

```dart
          ],
        ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
```

- [ ] **Step 3: Give `_CartBar` the brand gradient**

Replace (around lines 483-493):

```dart
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
```

with:

```dart
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
```

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/ordering/view/ordering_screen.dart`
Expected: `No issues found!` — pay particular attention to paren/brace balance from Step 2.

- [ ] **Step 5: Visually confirm**

`flutter run -d windows` at a phone width (or resize the window) and at a tablet width. Confirm: tapping a product still opens the modifier dialog and adds to cart, the floating cart bar still opens the bottom sheet, and the tablet side-panel layout is unaffected (this task doesn't touch `_CartPanel`).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/ordering/view/ordering_screen.dart
git commit -m "style(mobile): elevate product cards and gradient the cart bar"
```

---

### Task 12: Login screen — user grid card shadow + gradient avatars

**Files:**
- Modify: `mobile/lib/features/auth/view/login_screen.dart`

- [ ] **Step 1: Import the new tokens**

Add near the other theme imports (after line 8):

```dart
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Add shadow + drop the border on the user tile**

Replace (around lines 201-206):

```dart
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
```

with:

```dart
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.card,
            ),
```

- [ ] **Step 3: Replace the flat `CircleAvatar` with a gradient-filled circle**

Replace (around lines 210-219):

```dart
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: AppTextStyles.headingLg.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
```

with:

```dart
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: AppTextStyles.headingLg.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
```

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/auth/view/login_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Visually confirm**

`flutter run -d windows`. Confirm the user selection grid renders with the new gradient avatars and card shadow, selecting a user still transitions to the PIN pad, and a correct/incorrect PIN still authenticates/shows the error exactly as before (this task does not touch `_PinPad` or `appendDigit`/`authNotifier.login`).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/auth/view/login_screen.dart
git commit -m "style(mobile): elevate user cards and gradient avatars on login"
```

---

### Task 13: Cash payment sheet + discount screen summary shadows

**Files:**
- Modify: `mobile/lib/features/ordering/view/cash_payment_sheet.dart`
- Modify: `mobile/lib/features/ordering/view/discount_screen.dart`

- [ ] **Step 1: Import the token in both files**

Add to each file, near the other theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Add shadow to the total-due card in `cash_payment_sheet.dart`**

Find (around lines 90-96):

```dart
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
```

Replace with:

```dart
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: AppShadows.card,
                  ),
```

- [ ] **Step 3: Add shadow to the selected-items summary in `discount_screen.dart`**

Find (around lines 447-451):

```dart
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
```

Replace with:

```dart
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: AppShadows.card,
                ),
```

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/ordering/view/cash_payment_sheet.dart lib/features/ordering/view/discount_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Visually confirm**

`flutter run -d windows`, start an order, add items, open Checkout → Cash Payment (confirm denomination buttons and change calculation are untouched), and separately open Apply Discount (confirm item selection and Senior/PWD vs Promo fields are untouched).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/ordering/view/cash_payment_sheet.dart mobile/lib/features/ordering/view/discount_screen.dart
git commit -m "style(mobile): add card elevation to payment and discount summaries"
```

---

### Task 14: Void dialog + modifier sheet footer shadows

**Files:**
- Modify: `mobile/lib/features/transactions/view/void_transaction_dialog.dart`
- Modify: `mobile/lib/features/ordering/view/modifier_dialog.dart`

- [ ] **Step 1: Import the token in both files**

Add to each file, near the other theme imports:

```dart
import '../../../core/theme/app_shadows.dart';
```

- [ ] **Step 2: Add shadow to the void dialog's warning icon chip**

In `void_transaction_dialog.dart`, find (around lines 117-121):

```dart
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
```

Replace with:

```dart
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      boxShadow: AppShadows.card,
                    ),
```

- [ ] **Step 3: Add shadow to the modifier sheet's quantity/confirm footer**

In `modifier_dialog.dart`, find (around lines 261-267):

```dart
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.divider),
              ),
```

Replace with:

```dart
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppShadows.elevated,
              border: const Border(
                top: BorderSide(color: AppColors.divider),
              ),
```

- [ ] **Step 4: Verify**

Run: `cd mobile && dart analyze lib/features/transactions/view/void_transaction_dialog.dart lib/features/ordering/view/modifier_dialog.dart`
Expected: `No issues found!`

- [ ] **Step 5: Visually confirm**

`flutter run -d windows`. From Transactions, void a transaction (confirm the supervisor PIN flow still works end-to-end). From an order, tap a product with modifiers (confirm variant selection, options, quantity stepper, and "Add to order" still work and return the correct `LineItem`).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/features/transactions/view/void_transaction_dialog.dart mobile/lib/features/ordering/view/modifier_dialog.dart
git commit -m "style(mobile): add elevation to void dialog and modifier sheet footer"
```

---

## Self-Review

1. **Spec coverage:** All 15 screens from the approved mockup are addressed except the two the user explicitly excluded (Receipt, Reports). Dashboard and the Cashier Accounting hub card were already close to the target look in the existing codebase (they already use press-state shadows/borders); Task 7 still unifies the hub card's shadow with the shared token for consistency, and Dashboard is intentionally left untouched since it already matches the approved direction.
2. **Placeholder scan:** No TBD/TODO — every step has literal before/after code.
3. **Type consistency:** `AppShadows.card` / `AppShadows.elevated` and `AppGradients.primary` are the only new symbols introduced; every task that references them matches the names defined in Tasks 1-2.
4. **Business-flow safety:** Every change is confined to a `decoration:`/`style:` value or a wrapping `Container` purely for shadow purposes. No `onPressed`, `onTap`, provider call, or route changes anywhere in this plan.

---

**Note on commits:** This repo's `CLAUDE.md` states commits should only happen when the user explicitly asks. The steps above include `git commit` for completeness, but during execution, skip the actual `git commit` invocation and stop after the verify/visual-confirm step — leave changes staged/unstaged for the user to review and commit themselves, unless they say otherwise.
