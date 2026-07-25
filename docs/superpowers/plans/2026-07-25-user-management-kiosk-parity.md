# User Management — Kiosk Parity Implementation Plan

> **For agentic workers:** Execute task-by-task inline in the current session (per user preference — no subagent dispatch). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring mobile's user management in line with kiosk's actual flow: (1) every new user gets a system default PIN and is forced through a persisted, per-user "set your PIN" gate on first login — not just the one seeded admin; (2) add a `supervisor` role; (3) admin and supervisor both get full user-management rights (create/edit/reset-pin/delete); (4) bring over the genuinely new capabilities kiosk has that mobile lacks — employee ID, phone, avatar, hard delete — while deliberately NOT splitting `name` into first/middle/last (see Design Decision #1) and NOT building `locked`/verification flags (kiosk's own UI never exposes them either, per source-code confirmation).

**Architecture:** Local-only (no backend), so kiosk's server-driven PIN generation becomes a local default-PIN-hash-and-flag mechanism. Schema migration v4→v5 adds `employeeId`, `phone`, `avatarUrl`, `isPinChanged` to `users_table`. `UserEntity` gains `isPinChanged`, `isSupervisor`, `isAdminOrSupervisor`. `AuthNotifier`'s forced-PIN-change check moves from a transient string comparison (`pin == '000000'`) to reading the persisted `isPinChanged` flag — matching kiosk's model exactly. The existing `_ChangePinDialog` (admin types the exact new PIN) is replaced by a `Reset PIN` action (resets to the default PIN hash, sets `isPinChanged = false`, forcing the user through the same setup screen again) — matching kiosk's `resetPin(userId)`, which never lets the admin choose the new value either.

**Tech Stack:** Flutter, Riverpod, Drift (schema v4→v5), `bcrypt` (existing), `ImageStorageService` (existing, from Phase 3, reused for avatar picking).

---

## Design Decisions

1. **No first/middle/last name split.** Kiosk splits name into three columns for its own display formatting. Mobile's single `name` column is already joined against by dozens of already-shipped, already-reviewed queries across `SalesDao`, `CashierAccountingDao`, receipts, and reports (cashier name on every sale, X/Z-Reading breakdowns, transaction lists). Splitting it would mean touching every one of those approved call sites for a cosmetic difference with no behavioral gain. Mobile keeps one `name` field.
2. **No `locked` field, no email/phone verification flags.** Confirmed by reading kiosk's own source: `locked` is carried through from the DTO but never set anywhere in the kiosk UI (no lock/unlock button exists in the client at all — it's a backend/passthrough-only concept), and `emailVerified`/`phoneVerified` require an email/SMS delivery mechanism mobile doesn't have. Building UI for fields kiosk itself never exposes would be scope invented from nothing.
3. **`status` (Active/Cancelled) maps 1:1 to mobile's existing `isActive` boolean** — kiosk's in-form switch just toggles a string; no new concept needed, but the toggle moves *into* the edit dialog (matching kiosk's actual UI: the switch lives inside `UserFormDialog`, not as a separate top-level action) rather than staying a separate standalone "Deactivate" button.
4. **Hard delete is added** as a distinct, separate destructive action (matching kiosk's standalone `deleteUser`), alongside the in-form Active/Inactive toggle — this is exactly kiosk's shape: edit-with-status-switch, plus a fully separate delete button.
5. **Avatar picking reuses `ImageStorageService`** (built in Phase 3 for product images) as-is, including its `product_images/` storage subfolder. Introducing a parallel `user_avatars/`-flavored service for one extra picker call would be needless duplication; the folder name is a harmless cosmetic detail, not a functional one.
6. **Supervisor gets identical permissions to admin for user management** (create, edit, reset-pin, delete) and for the existing refund/void/Z-Reading-close authorization gates that were already conceptually "admin or supervisor" (the dialogs were already labeled "Supervisor Authorization" back in Phase 1, but the underlying check only ever looked for `role == 'admin'` since no supervisor role existed yet — this plan closes that gap, which is the whole point of introducing the role). Kiosk itself doesn't model a separate supervisor-vs-admin permission tier for user management, so granting supervisor full parity with admin here is the simplest, most consistent choice.

---

## Task 1: Schema migration v4 → v5

**Files:**
- Modify: `mobile/lib/core/database/tables/users_table.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Test: `mobile/test/core/database/daos/users_dao_test.dart` (new)

Add to `UsersTable`: `employeeId` (text, nullable), `phone` (text, nullable), `avatarUrl` (text, nullable), `isPinChanged` (bool, **default `true`** — existing rows already have admin-chosen real PINs and must NOT be forced through setup on migration; new rows created going forward explicitly pass `isPinChanged: false` at the call site when assigning the default PIN).

Bump `schemaVersion` to 5, extend `onUpgrade`:
```dart
if (from < 5) {
  await m.addColumn(usersTable, usersTable.employeeId);
  await m.addColumn(usersTable, usersTable.phone);
  await m.addColumn(usersTable, usersTable.avatarUrl);
  await m.addColumn(usersTable, usersTable.isPinChanged);
}
```

- [ ] Write failing tests: schema version >= 5; new columns round-trip; a freshly-inserted user with no explicit `isPinChanged` defaults to `true` (proving existing-row migration safety).
- [ ] Confirm fail, implement, regenerate codegen, confirm pass.

---

## Task 2: `UsersDao` — delete, reset-pin, partial-update fix

**Files:**
- Modify: `mobile/lib/core/database/daos/users_dao.dart`
- Test: `mobile/test/core/database/daos/users_dao_test.dart` (extend)

- Fix `updateUser`: currently `update(usersTable).replace(companion)` — same full-row-replace risk fixed for payment methods in Phase 5. Change to `(update(usersTable)..where((t) => t.id.equals(companion.id.value))).write(companion)` for a genuine partial update.
- Add `Future<int> deleteUser(int id) => (delete(usersTable)..where((t) => t.id.equals(id))).go();`
- Add `Future<int> resetPin(int userId, String defaultPinHash) => (update(usersTable)..where((t) => t.id.equals(userId))).write(UsersTableCompanion(pinHash: Value(defaultPinHash), isPinChanged: const Value(false)));`
- Add `Future<int> completePinSetup(int userId, String newPinHash) => (update(usersTable)..where((t) => t.id.equals(userId))).write(UsersTableCompanion(pinHash: Value(newPinHash), isPinChanged: const Value(true)));`

- [ ] Write failing tests for `deleteUser`, `resetPin` (sets both pinHash and isPinChanged:false), `completePinSetup` (sets both pinHash and isPinChanged:true), and a partial-update regression test for `updateUser` (edit one field, confirm an unspecified field like `employeeId` isn't clobbered — mirrors the Phase 5 `sortOrder` regression test).
- [ ] Confirm fail, implement, confirm pass.

---

## Task 3: `UserEntity` / `AuthRepository` / `AuthNotifier` — persisted per-user PIN gate + supervisor

**Files:**
- Modify: `mobile/lib/features/auth/entities/user_entity.dart`
- Modify: `mobile/lib/features/auth/repositories/auth_repository.dart`, `auth_repository_impl.dart`
- Modify: `mobile/lib/features/auth/state/auth_notifier.dart`
- Modify: `mobile/lib/core/seeder/admin_seeder.dart`
- Test: extend `mobile/test/features/auth/state/auth_notifier_test.dart`

`UserEntity` gains `isPinChanged` (required), `employeeId`/`phone`/`avatarUrl` (nullable, for display), and:
```dart
bool get isSupervisor => role == 'supervisor';
bool get isAdminOrSupervisor => role == 'admin' || role == 'supervisor';
```

`AuthRepositoryImpl.login`/`getActiveUsers` map the new fields through from `UsersTableData`.

`AuthNotifier.login`: replace `mustChangePin: pin == defaultSeededPin` with `mustChangePin: !user.isPinChanged` (the DB-persisted flag is now the source of truth, matching kiosk's `auth.isPinChanged` check — no more transient string comparison).

`AuthNotifier.verifySupervisorPin`/`AuthRepositoryImpl.verifyAdminPin`: widen the role filter from `role == 'admin'` to `role == 'admin' || role == 'supervisor'` (this is the method the Refund/Z-Reading authorization dialogs already call — closing the gap flagged back in Phase 1/2 where "mobile has no supervisor role").

`AdminSeeder`: explicitly pass `isPinChanged: const Value(false)` when seeding (now backed by the real persisted column instead of relying on the transient check).

- [ ] Write failing tests: login with a user whose `isPinChanged` is `false` sets `mustChangePin: true` regardless of what PIN string was typed; login with `isPinChanged: true` never sets `mustChangePin` even if the typed PIN happens to be `'000000'` (proving the check is now persisted-flag-based, not string-based); `verifySupervisorPin` succeeds for a `role: 'supervisor'` user's correct PIN.
- [ ] Confirm fail, implement, confirm pass.

---

## Task 4: `SetupPinScreen` — persist `isPinChanged` on completion

**Files:**
- Modify: `mobile/lib/features/auth/view/setup_pin_screen.dart`
- Modify: `mobile/lib/features/users/state/users_notifier.dart` (add `completeOwnPinSetup`)

Replace the current `usersProvider.notifier.changePin(...)` call (which will be removed/replaced by Reset-Pin in Task 5) with a new `UsersNotifier.completeOwnPinSetup({required int userId, required String newPin})` that hashes the PIN and calls `UsersDao.completePinSetup` (sets both `pinHash` and `isPinChanged: true` atomically) — then still calls `authNotifier.completePinSetup()` to flip the in-memory `AuthState` so the router redirect stops sending the user back to `/setup-pin`.

- [ ] Manual/analyzer verification (this screen has no existing dedicated widget test; DB-level behavior is already covered by Task 2/3's tests).

---

## Task 5: `UsersNotifier` — default-PIN creation, reset-pin, hard delete, richer edit

**Files:**
- Modify: `mobile/lib/features/users/state/users_notifier.dart`
- Test: `mobile/test/features/users/state/users_notifier_test.dart` (new)

- `addUser({required String name, required String role, String? employeeId, String? phone, String? avatarUrl})` — **no `pin` parameter anymore**. Hashes `defaultSeededPin` (imported from `core/seeder/admin_seeder.dart`, already public) and inserts with `isPinChanged: false` — matching kiosk's `devicePin: '000000', isPinChanged: false` on every create.
- `editUser({required int id, required String name, required String role, required bool isActive, String? employeeId, String? phone, String? avatarUrl})` — now also carries `isActive` (folded in from the old standalone deactivate action) and the three new optional fields. Uses the fixed partial-update DAO method.
- Remove `changePin` (replaced by `resetPin`).
- Add `Future<void> resetPin(int userId)` — hashes `defaultSeededPin`, calls `UsersDao.resetPin`.
- Add `Future<void> completeOwnPinSetup({required int userId, required String newPin})` (used only by `SetupPinScreen`, Task 4).
- Add `Future<void> deleteUser(int userId)` — calls `UsersDao.deleteUser` (hard delete).
- Remove `deactivateUser` (folded into `editUser`'s `isActive` param, matching kiosk's in-form toggle).
- `build()` should list **all** users, not just active ones (an admin managing users needs to see and be able to re-activate/delete an inactive account too — mirrors kiosk's management console, which lists both Active and Cancelled users). Add `UsersDao.getAllUsers()` (no `isActive` filter) and switch `build()` to call it instead of `getAllActiveUsers()`. `getAllActiveUsers()` stays (still used by the login roster, which correctly should only show active users).

- [ ] Write failing tests for all of the above (create assigns default PIN + isPinChanged:false; edit updates fields including isActive without clobbering others; resetPin sets default PIN + isPinChanged:false; deleteUser actually removes the row; build() lists inactive users too).
- [ ] Confirm fail, implement, confirm pass.

---

## Task 6: Users screen UI — 3-role picker, new fields, reset-pin, hard delete, avatar

**Files:**
- Modify: `mobile/lib/features/users/view/users_screen.dart`

- `_RoleToggle` → three options: Cashier / Supervisor / Admin (values `'cashier'`, `'supervisor'`, `'admin'`).
- `_RoleBadge` → three-way label/color (Admin / Supervisor / Cashier).
- `_AddUserDialog`: remove PIN/confirm-PIN fields entirely; add Employee ID, Phone (both optional `TextFormField`s), and an avatar picker (reuse `ImageStorageService.pickAndStore()`/`isNetworkUrl`, same thumbnail-plus-choose/remove pattern established in `ProductFormDialog`). Add a small info line: "New users start with a default PIN and will set their own on first login" so the admin isn't confused by the missing PIN field.
- `_EditUserDialog`: add Employee ID, Phone, avatar picker, and an Active/Inactive `SwitchListTile` (folded in from the old standalone deactivate action).
- Replace `_ChangePinDialog` with a `_confirmResetPin` confirm dialog ("Reset PIN for {name}? They'll be asked to set a new PIN on next login.") calling `usersProvider.notifier.resetPin(userId)`.
- Add a hard-delete confirm dialog ("Delete {name}? This permanently removes their account and cannot be undone.") calling `usersProvider.notifier.deleteUser(userId)`.
- Permission gating: change every `isAdmin` check in this file to `isAdmin || isSupervisor` (FAB visibility, popup-menu visibility) — both roles get full CRUD per the user's explicit instruction.
- `_UserCard`: show employee ID / phone in the subtitle (if set), show avatar image (network vs. local file, same branching as `ProductFormDialog`'s thumbnail) with initials fallback, show an "Inactive" visual indicator for deactivated accounts (since the list now includes them, per Task 5's `build()` change).

- [ ] `dart analyze` clean on this file. No new widget test required (UI-only, matches the established precedent of testing the notifier layer and reviewing the UI directly).

---

## Task 7: Propagate `isAdminOrSupervisor` to existing admin-only gates

**Files:**
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart` (Users tile visibility; role label in header now shows Admin/Supervisor/Cashier)
- Modify: `mobile/lib/features/transactions/view/transaction_detail_screen.dart` (Refund/Void button visibility)

Change `isAdmin` checks (`user?.isAdmin ?? false` / `authState.user.isAdmin`) to `user?.isAdminOrSupervisor ?? false` / `authState.user.isAdminOrSupervisor` in both files. Update the role-label ternary in `dashboard_screen.dart` (`role == 'admin' ? 'Admin' : 'Cashier'`) to a three-way check.

- [ ] `dart analyze` clean.

---

## Task 8: Manual verification pass

- [ ] Run full test suite — all pass except the known pre-existing unrelated `widget_test.dart` failure.
- [ ] Manually: log in as the seeded admin (still forced through Setup PIN on first-ever run, now via the persisted flag). Create a new Supervisor user — confirm no PIN field appears, confirm they can log in with the default PIN and are immediately forced through Setup PIN. Log in as the new supervisor, confirm they can see/use Users management (create/edit/reset-pin/delete) and can authorize a refund/Z-Reading close. Edit a user's Employee ID/Phone/avatar and confirm it persists. Reset a user's PIN and confirm they're forced through setup again on next login. Hard-delete a user and confirm the row is gone (not just deactivated).

If any step fails, use `superpowers:systematic-debugging` before patching.
