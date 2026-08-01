# Add-User Setup Check — Design Spec

**Date:** 2026-06-03  
**Branch:** demo  
**Author:** Jufiel Lariosa

---

## Problem

After a fresh install, the only user in the system is the default system admin. Nothing currently prompts the admin to add employee accounts before operating the POS. This spec covers adding a forced "Add Employee" prompt that appears at the right point in the post-login setup sequence.

---

## Scope

Flutter kiosk (`kiosk/`) only. No backend changes. No new providers.

---

## User-Facing Flow

```
Login → MenuScreen
    ↓
posTerminalProvider resolves
    ├─ ERROR (no POS registered)
    │   └─ show existing "Register POS" dialog
    │         └─ on success → ref.invalidate(posTerminalProvider)
    │                └─ resolves OK → checkAndShowUsersDialog()
    │
    └─ OK (POS already registered)
          └─ checkAndShowUsersDialog()
                ↓
          GET /api/v1/users?page=1&limit=2  (lightweight count check)
                ↓
          total ≤ 1?
            YES → show forced "Add Employee" dialog (non-dismissible)
                    ├─ "Add Employee"  → UserManagementRoute().go(context)
                    └─ "Sign Out"      → OnboardingRoute().go(context)
            NO  → nothing, menu is usable as normal
```

The check only fires when the logged-in user is `Role.admin`. Non-admin roles skip it entirely.

---

## Implementation

### File changed: `kiosk/lib/features/menu/view/menu_screen.dart`

#### 1. New ref

```dart
final hasShownUsersDialog = useRef(false);
```

Sits alongside the existing `hasShownPosDialog` ref. Prevents the dialog from re-appearing during the same session (e.g., after navigating back from `UserManagementScreen`).

#### 2. New function: `checkAndShowUsersDialog()`

```dart
Future<void> checkAndShowUsersDialog() async {
  if (hasShownUsersDialog.value) return;

  final posState  = ref.read(posTerminalProvider);
  final accessState = ref.read(accessProvider);

  // Only run when POS is confirmed OK and access is resolved
  if (posState.isLoading || posState.hasError) return;
  if (accessState.isLoading || accessState.hasError) return;

  final access = accessState.value!;
  if (access.role != Role.admin) return;

  hasShownUsersDialog.value = true;

  try {
    final repo = ref.read(userRepositoryProvider);
    final (_, total) = await repo.getUsers(limit: 2, page: 1);
    if (!context.mounted) return;
    if (total <= 1) _showAddEmployeeDialog(context);
  } catch (_) {
    // Silent fail — don't block the menu if the user count check fails
  }
}
```

#### 3. Dialog helper

```dart
void _showAddEmployeeDialog(BuildContext context) {
  showMessageDialog(
    context,
    title: 'No Employees Added',
    message:
        'No employee accounts have been set up yet. '
        'Add at least one employee before operating the system.',
    type: DialogType.warning,
    primaryButtonText: 'Add Employee',
    secondaryButtonText: 'Sign Out',
    barrierDismissible: false,
    onPrimaryPressed: () {
      Navigator.of(context, rootNavigator: true).pop();
      const UserManagementRoute().go(context);
    },
    onSecondaryPressed: () {
      Navigator.of(context, rootNavigator: true).pop();
      const OnboardingRoute().go(context);
    },
  );
}
```

#### 4. Wire into existing listeners

Both existing listeners already call `checkAndShowPosDialog()`. Add `checkAndShowUsersDialog()` to both:

```dart
ref.listen(posTerminalProvider, (prev, next) {
  checkAndShowPosDialog();
  checkAndShowUsersDialog();          // ← added
});
ref.listen(accessProvider, (prev, next) {
  checkAndShowPosDialog();
  checkAndShowUsersDialog();          // ← added
});
```

#### Why this covers both paths

- **POS already registered:** `posTerminalProvider` resolves OK on first load → listener fires → `checkAndShowUsersDialog()` runs.
- **Fresh install (POS not registered):** `posTerminalProvider` errors → `checkAndShowPosDialog()` shows Register POS dialog → on success, `ref.invalidate(posTerminalProvider)` → listener fires again → POS now resolves OK → `checkAndShowUsersDialog()` runs. `hasShownPosDialog` is already `true` at this point but `hasShownUsersDialog` is still `false`, so the users check proceeds.

---

## What is NOT changing

| Item | Reason |
|---|---|
| Backend / API | `GET /api/v1/users` already returns `total`; no new endpoint needed |
| `Auth` entity | `accessProvider` already exposes `role`; no field addition needed |
| `getUsersProvider` | That provider is scoped to `UserManagementScreen`; we call the repository directly to avoid coupling |
| `showRegisterPosTerminalDialog` | Its `onSuccess` already calls `ref.invalidate(posTerminalProvider)`, which triggers the listener |
| Non-admin roles | Guard condition `access.role != Role.admin` skips the check |

---

## Edge Cases

| Case | Behaviour |
|---|---|
| Admin adds employee, returns to menu | `hasShownUsersDialog == true` — dialog does not re-appear |
| User count API call fails | Silent catch — menu remains usable; no crash |
| Admin clicks "Sign Out" on setup dialog | Navigates to `OnboardingRoute` (same as all other Sign Out paths) |
| Supervisor logs in (no POS, no users) | POS dialog shows for supervisor too (existing behaviour), but user-check dialog does **not** show (role guard) |
| `context.mounted` false after async gap | Guarded with `if (!context.mounted) return` before showing dialog |
