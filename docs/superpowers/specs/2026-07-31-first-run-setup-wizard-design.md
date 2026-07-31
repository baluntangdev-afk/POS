# First-Run Setup Wizard — Design Spec

**Date:** 2026-07-31
**Branch:** feature/mobile-integration
**Author:** Jufiel Lariosa

---

## Problem

After a fresh install, an admin has to already know to go find Settings → Store Info, Users → Add Employee, and Inventory → Import Products on their own. Nothing chains these into a guided sequence.

**Kiosk** already has a partial version of this: `MenuScreen` (`kiosk/lib/features/menu/view/menu_screen.dart`) has forced, non-dismissible post-login dialogs for POS-terminal registration, empty employee list, and empty product catalog — wired via `ref.listen` + `useRef` "shown" flags. One gap:
- The empty-catalog dialog only offers "Import Products" or "Sign Out" — there's no way to continue into the app without importing products first.

Store details are **not** a separate check on kiosk. `RegisterPosTerminalDialog` already requires Legal Name / Address / TIN as part of POS-terminal registration (`POST /pos-terminals/register`), and that record is the single source of truth for store details — `StoreRepository` (receipt header data) now reads it directly via `PosTerminalsApi.getMyTerminal()`. A prior iteration of this spec added a redundant local-only "franchisee info" store that duplicated the same fields without ever syncing to the registered terminal; that feature has been removed. Do not reintroduce a separate store-details data source — mobile's equivalent should be designed the same way (see Detection below).

**Mobile** has none of this. `DashboardScreen` (`mobile/lib/features/dashboard/view/dashboard_screen.dart`) shows the tile grid immediately after login with no setup checks.

---

## Goal

Chain checks into a first-run sequence in both apps, firing right after login for the admin role. On kiosk that's **Employees → Products** (store details is already covered by the existing POS-terminal registration check). On mobile — which has no POS-terminal concept — that's **Store Details → Employees → Products**. Required checks can't be skipped except by signing out. Products is optional — a "Skip for now" button lets the admin continue into the app and add products later from Inventory.

---

## Scope

- **Kiosk**: extend the existing check-chain pattern in `menu_screen.dart`. Add a "Skip for now" button to the existing empty-catalog dialog. No changes to the POS-terminal or employee checks (already correct) — no separate store-details check, since POS-terminal registration already requires and stores that data.
- **Mobile**: build a three-check chain from scratch in `dashboard_screen.dart` (Store Details → Employees → Products), using the same mechanism (per-check `useRef` "shown" flag + `ref.listen`), backed by local Drift providers instead of API calls. Mobile needs its own Store Details check because, unlike kiosk, it has no POS-terminal registration step to piggyback on.
- No backend changes. No new database columns. Both apps already have the data needed to detect "not configured" state (see Detection below).

---

## Detection ("is this step done?")

| Step | Kiosk source | Mobile source | "Not done" condition |
|---|---|---|---|
| Store Details | *(none — covered by POS-terminal registration; `posTerminalProvider` erroring is the "not done" signal, same as the existing POS-terminal check)* | `storeInfoProvider` (Drift; `ensureStoreInfoExists()` auto-creates a default row with empty-string defaults) | `storeName.trim().isEmpty` (mobile only) |
| Employees | `userRepositoryProvider.getUsers(limit: 2, page: 1)` → `total` | `usersProvider` → `List.length` | `total <= 1` — only the seeded admin exists |
| Products | `inventoryRepositoryProvider.fetchProducts()` | inventory provider's product list | list is empty |

Neither app needs a new "setup complete" flag — each check re-derives its own state live from the same data the rest of the app already reads, exactly like the existing kiosk checks do today.

---

## Flow

```
Login → Dashboard/Menu screen builds
    ↓
(kiosk only) POS Terminal check — unchanged, existing behavior
    ↓                                              (mobile only) Store Details check
    ↓                                              ├─ storeName empty?
    ↓                                              │     YES → forced dialog (barrierDismissible: false)
    ↓                                              │           inline form (Store Name / Address / TIN), same
    ↓                                              │           shape as kiosk's RegisterPosTerminalDialog —
    ↓                                              │           NOT a navigation to the Store Info settings screen
    ↓                                              │           primary: "Save" → writes via storeInfoProvider, closes dialog
    ↓                                              │           secondary: "Sign Out"
    ↓                                              │     NO  → continue
    ↓ ←────────────────────────────────────────────┘
Employees check
    ├─ total <= 1?
    │     YES → forced dialog
    │           "Add at least one employee before operating the system."
    │           primary: "Add Employee" → navigate to Users screen
    │           secondary: "Sign Out"
    │     NO  → continue
    ↓
Products check
    ├─ product list empty?
    │     YES → forced dialog
    │           "Import your product catalog to get started."
    │           primary: "Import Products" → navigate to CSV import / inventory
    │           secondary: "Skip for now" → dismiss, mark shown, continue into app
    │           tertiary: "Sign Out"
    │     NO  → continue
    ↓
Screen usable as normal
```

Only fires for `Role.admin` (kiosk's existing employee/catalog checks already gate on admin-only; mobile mirrors that — the POS-terminal check on kiosk is the only one that also allows `supervisor`, and that's pre-existing, unchanged).

Each check is independent and re-evaluated on every relevant provider change (`ref.listen`), same as kiosk today — this means:
- If the admin backs out without completing a required step, it reappears next time the gating providers resolve.
- "Skip for now" on Products only suppresses the dialog for the current screen-build session (via the `useRef` flag) — if products are still empty on the next login, the dialog reappears. This matches the existing behavior of the other kiosk checks and is intentional: skipping doesn't mean "never ask again," it means "not right now."

Errors from any check's data fetch are caught and swallowed silently (existing kiosk pattern) — a failed check never blocks the screen from being usable.

---

## Implementation

### Kiosk — `kiosk/lib/features/menu/view/menu_screen.dart`

No store-details check — `RegisterPosTerminalDialog` already requires Legal Name / Address / TIN before `posTerminalProvider` resolves without error, so the existing POS-terminal check (`checkAndShowPosDialog`) already covers this. `StoreRepository` (`kiosk/lib/features/sales/repositories/store_repository.dart`) now builds receipt header data directly from `PosTerminalsApi.getMyTerminal()` instead of a separate local store — there is exactly one place store details are recorded.

1. `showMessageDialog`/`MessageDialog` (`kiosk/lib/widgets/message_dialog.dart`) currently only supports two buttons (primary + optional secondary, rendered as a row) — confirmed by reading `_ActionButtons`. Add optional `tertiaryButtonText` / `onTertiaryPressed` params: when present, render the existing primary/secondary row unchanged, plus a plain `TextButton` below it (lesser visual weight, matches "skip" being the least-favored action). This is a small, generically useful addition to the shared widget, not a one-off hack in `menu_screen.dart`.
2. Modify `checkAndShowEmptyCatalogDialog()` to pass `tertiaryButtonText: 'Skip for now'` with a handler that just pops the dialog — no navigation, no state change beyond the existing `hasShownEmptyCatalogDialog.value = true` already set before the dialog opens.

No new routes needed — reuses `UserManagementRoute`, `ProductsRoute`, already used by the existing checks.

### Mobile — `mobile/lib/features/dashboard/view/dashboard_screen.dart`

Mirrors the kiosk mechanism exactly, adapted to mobile's local-DB providers:

1. Three `useRef(false)` flags: store details, employees, products shown.
2. Three check functions reading `storeInfoProvider`, `usersProvider`, and the inventory provider respectively, gated on `authState.user.isAdmin`.
3. `ref.listen` on `authNotifierProvider` (or the three source providers directly, whichever fires reliably on first dashboard build — match whatever pattern `authProviders` already supports) triggers all three checks in order.
4. Store Details is a **dialog with an inline form**, not a navigation — mirrors kiosk's `RegisterPosTerminalDialog` (`kiosk/lib/features/menu/view/register_pos_terminal_dialog.dart`): a non-dismissible `Dialog` containing `Store Name` / `Address` / `TIN` fields (the subset `store_info_table` already has that the detection check cares about), a "Save" button that calls `storeInfoProvider.notifier.save(...)` and closes on success, and a "Sign Out" secondary button. Add it as `mobile/lib/features/dashboard/view/store_details_dialog.dart`. This is a first-run-only shortcut — the full form (tax rate, currency, receipt footer, terminal name, payment methods) stays on `StoreInfoScreen` (`mobile/lib/features/settings/view/store_info_screen.dart`, unchanged) for editing after setup.
5. Employees and Products dialogs: mobile has no existing reusable message-dialog widget (checked — none found). Add a small new one, `mobile/lib/widgets/setup_prompt_dialog.dart`, matching kiosk's `showMessageDialog` shape closely enough to keep the two apps' check functions structurally parallel (title, message, primary/secondary/optional-tertiary buttons, `barrierDismissible: false`). Used for the Employees and Products checks; Store Details uses its own dialog per point 4 since it needs form fields, not just message + buttons. Everything else reuses existing screens (`/users`, `/settings/csv-import`).

---

## What is NOT changing

| Item | Reason |
|---|---|
| Backend / API | Nothing touched — both apps already have local access to the data needed |
| Database schema (either app) | No new tables/columns — detection uses existing empty-default fields |
| Kiosk POS-terminal check | Already correct, untouched |
| Kiosk employee check | Already correct, untouched |
| Non-admin roles | Skip the entire chain, same as existing kiosk gating |
| Installer / `installer.iss` | Explicitly out of scope — this is in-app, not part of the Windows installer wizard |

---

## Edge Cases

| Case | Behavior |
|---|---|
| Admin completes store details, returns to menu/dashboard | Flag is already `true` for that check this session; check doesn't re-show unless the app is fully relaunched and the field is still empty |
| Admin skips products, later imports from Inventory manually | Next login, products check passes (list no longer empty) — no dialog |
| Store-info / users / product fetch throws | Caught, logged nowhere, dialog simply doesn't show — screen remains usable (matches existing kiosk pattern) |
| Supervisor logs in (mobile) | No checks run — only `admin` triggers the chain, matching kiosk's employee/catalog gating |
| `context.mounted` false after an async gap | Guarded with `if (!context.mounted) return` before showing any dialog, same as kiosk today |
