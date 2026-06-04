# Add-User Setup Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After login, if the admin has no POS registered, show the Register POS dialog; on success (or if POS is already registered), check whether there is only one user in the system and, if so, force the admin to the User Management screen via a non-dismissible dialog.

**Architecture:** All logic is added inside `MenuScreen.build()` as a second closure (`checkAndShowUsersDialog`) that mirrors the existing `checkAndShowPosDialog` pattern. Both existing `ref.listen` calls are expanded to invoke both closures. No new providers, no new files, no backend changes.

**Tech Stack:** Flutter · Hooks Riverpod (`hooks_riverpod`) · `flutter_hooks` · GoRouter

---

## File Map

| Action | Path |
|--------|------|
| Modify | `kiosk/lib/features/menu/view/menu_screen.dart` |

---

### Task 1: Add the `userRepositoryProvider` import

**Files:**
- Modify: `kiosk/lib/features/menu/view/menu_screen.dart:21`

`menu_screen.dart` does not currently import the user repository. Add it so `checkAndShowUsersDialog` can call `repo.getUsers`.

- [ ] **Step 1: Add the import**

In `menu_screen.dart`, after line 21 (`import '../view/register_pos_terminal_dialog.dart';`), add:

```dart
import '../../users/repositories/user_repository.dart';
```

The import block (lines 16–21) should look like this afterwards:

```dart
import '../entities/access.dart';
import '../enums/role.dart';
import '../state/access_notifier.dart';
import '../state/pos_terminal_notifier.dart';
import '../view/menu_grid.dart';
import '../view/register_pos_terminal_dialog.dart';
import '../../users/repositories/user_repository.dart';
```

- [ ] **Step 2: Verify the import resolves**

```bash
cd kiosk && fvm dart analyze lib/features/menu/view/menu_screen.dart
```

Expected: no errors (the file is syntactically identical to before — the import is unused until Task 2).

---

### Task 2: Add `hasShownUsersDialog` ref and `checkAndShowUsersDialog` closure

**Files:**
- Modify: `kiosk/lib/features/menu/view/menu_screen.dart:30–77`

- [ ] **Step 1: Add the ref on line 31 (after `hasShownPosDialog`)**

Replace:

```dart
    final hasShownPosDialog = useRef(false);
```

With:

```dart
    final hasShownPosDialog = useRef(false);
    final hasShownUsersDialog = useRef(false);
```

- [ ] **Step 2: Add `checkAndShowUsersDialog` closure after `checkAndShowPosDialog`**

The existing `checkAndShowPosDialog` ends at the closing `}` on line 77. Insert the new closure immediately after it (before line 79 where the listeners start):

```dart
    Future<void> checkAndShowUsersDialog() async {
      if (hasShownUsersDialog.value) return;

      final posState = ref.read(posTerminalProvider);
      final accessState = ref.read(accessProvider);

      // Only run when POS is confirmed OK and access is fully resolved
      if (posState.isLoading || posState.hasError) return;
      if (accessState.isLoading || accessState.hasError) return;

      final access = accessState.value!;
      if (access.role != Role.admin) return;

      hasShownUsersDialog.value = true;

      try {
        final repo = ref.read(userRepositoryProvider);
        final (_, total) = await repo.getUsers(limit: 2, page: 1);
        if (!context.mounted) return;
        if (total <= 1) {
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
      } catch (_) {
        // Silent fail — don't block the menu if the user count check fails
      }
    }
```

- [ ] **Step 3: Verify no analysis errors**

```bash
cd kiosk && fvm dart analyze lib/features/menu/view/menu_screen.dart
```

Expected: no errors, no warnings about unused variables (the function is defined but not yet wired — that's fine at this stage).

---

### Task 3: Wire `checkAndShowUsersDialog` into both listeners

**Files:**
- Modify: `kiosk/lib/features/menu/view/menu_screen.dart:79–80`

The two listeners currently use arrow syntax with a single call. Expand them to block bodies so both closures are called.

- [ ] **Step 1: Replace the two listener lines**

Replace:

```dart
    ref.listen(posTerminalProvider, (prev, next) => checkAndShowPosDialog());
    ref.listen(accessProvider, (prev, next) => checkAndShowPosDialog());
```

With:

```dart
    ref.listen(posTerminalProvider, (prev, next) {
      checkAndShowPosDialog();
      checkAndShowUsersDialog();
    });
    ref.listen(accessProvider, (prev, next) {
      checkAndShowPosDialog();
      checkAndShowUsersDialog();
    });
```

- [ ] **Step 2: Final analysis pass on the whole file**

```bash
cd kiosk && fvm dart analyze lib/features/menu/view/menu_screen.dart
```

Expected: `No issues found!`

---

### Task 4: Manual smoke test

Run the app and verify both paths:

- [ ] **Step 1: Start the app**

```bash
cd kiosk && fvm flutter run -d windows
```

- [ ] **Step 2: Smoke test — POS already registered, users already exist**

Log in as admin. If POS is registered and more than one user exists, the menu loads normally with no dialogs. Confirm this is the case.

- [ ] **Step 3: Smoke test — POS already registered, only admin user**

Log in as admin on a system where only the admin account exists. After the menu loads, the "No Employees Added" dialog should appear with two buttons: **Add Employee** and **Sign Out**.

  - Tap **Add Employee** → should navigate to the User Management screen.
  - Return to the menu (back button or nav) → dialog should NOT reappear (session guard is set).

- [ ] **Step 4: Smoke test — fresh install (no POS registered)**

Log in as admin on a system where no POS terminal is assigned.

  - "No POS Terminal Assigned" dialog appears (existing behaviour).
  - Tap **Register POS** → complete the registration form → submit.
  - After successful registration, the "No Employees Added" dialog should appear automatically.
  - Tap **Sign Out** → navigates back to the onboarding screen.

- [ ] **Step 5: Smoke test — non-admin login**

Log in as a non-admin user. Confirm the "No Employees Added" dialog does NOT appear regardless of user count.

---

### Task 5: Commit

- [ ] **Step 1: Stage and commit**

```bash
git add kiosk/lib/features/menu/view/menu_screen.dart
git commit -m "feat(menu): show forced add-employee dialog when only admin exists

After the POS terminal check passes, admins are now prompted to add
employees if no non-admin users exist. The dialog is non-dismissible
and redirects to User Management. Fires on both the fresh-install path
(post POS registration) and the already-registered path."
```

---

## Spec Coverage Check

| Spec requirement | Task |
|---|---|
| Only fires for `Role.admin` | Task 2 — `if (access.role != Role.admin) return` |
| Only fires when POS is OK | Task 2 — `if (posState.isLoading \| posState.hasError) return` |
| Total ≤ 1 triggers dialog | Task 2 — `if (total <= 1)` |
| Fresh install path (after POS register) | Task 3 — listener on `posTerminalProvider` re-fires after `ref.invalidate` |
| Already-registered path | Task 3 — listener fires on first successful resolution |
| Non-dismissible dialog | Task 2 — `barrierDismissible: false` |
| "Add Employee" → UserManagementRoute | Task 2 — `UserManagementRoute().go(context)` |
| "Sign Out" → OnboardingRoute | Task 2 — `OnboardingRoute().go(context)` |
| Dialog does not reappear in same session | Task 2 — `hasShownUsersDialog.value = true` before async call |
| Silent fail on API error | Task 2 — `catch (_) {}` |
| `context.mounted` guard | Task 2 — `if (!context.mounted) return` |
