# Tile Grid + PIN Login — Design

## Context

The kiosk currently logs in staff via a typed username field followed by a 6-digit PIN pad (`kiosk/lib/features/auth/view/login_view.dart`, `username_input.dart`). This is slow for a touch kiosk where cashiers switch in and out frequently during a shift, and typing on a virtual keyboard is not the native interaction for a fullscreen touch terminal.

This design replaces the typed username step with a tile grid of active staff — tap a name, then enter your PIN — matching the pattern used by Toast, Square, and Clover POS kiosks.

## Goals

- Replace typed-username entry with a tap-to-select tile grid of active staff.
- Keep the existing PIN entry step (`PinIndicator` + `PinPad`) unchanged in behavior.
- Add the minimum backend surface needed to list staff before authentication, without leaking sensitive user data (email, phone, role) to an unauthenticated screen.

## Non-goals

- PIN attempt lockout / rate limiting — explicitly out of scope for this change; the backend's current PIN validation behavior is unchanged.
- Search/filter UI for the tile grid — out of scope; roster is expected to stay small for a single-location kiosk. Can be revisited if that assumption breaks.
- Any device/terminal-level authentication for the new endpoint — the backend already exposes another `@Public()` endpoint (`catalog`) under the same local-network, single-installer threat model, so this follows existing precedent rather than introducing new device auth.

## Backend: `GET /users/roster`

A new, public, read-only endpoint that lists staff eligible to appear on the login screen.

**DTO** — `be/src/users/dto/login-roster-item.dto.ts`:

```ts
export class LoginRosterItemDto {
  id: number;
  userId: string;
  firstName: string;
  middleName: string | null;
  lastName: string;
  suffix: UserSuffix | null;
  image: string | null;
}
```

No `email`, `phone`, `role`, `status`, or `locked` fields are returned — the tile grid only needs enough to render a name and an avatar.

**Service** — `UsersService.findLoginRoster()`:

- Query: `status = BaseStatus.ACTIVE AND locked = false`.
- Select only the `LoginRosterItemDto` fields.
- Order by `firstName ASC` (same convention as `findAuthorizers()`).
- No pagination.

**Controller** — new method on `UsersController`:

```ts
@Get('roster')
@Public()
@ApiOkResponse({ type: [LoginRosterItemDto] })
findLoginRoster() {
  return this.usersService.findLoginRoster();
}
```

Placed above the existing `@Get(':id')` handler so the literal `roster` path isn't shadowed by the `:id` param route (same reason `authorizers` is already ordered above `:id` today).

## Kiosk: data layer

- New schema `LoginRosterItemDto` (`dart_mappable`) in `kiosk/lib/data/backend_api/schemas/`, mirroring the backend DTO.
- New method `UserApi.getLoginRoster()` calling `GET /api/v1/users/roster`. This must use the **unauthenticated** Dio client, not `secureApiClientProvider` — there is no access token yet at the login screen. The exact client to use will be confirmed against `api_clients.dart` during implementation (likely the same client `AuthApi.login()` already uses).
- New provider `loginRosterProvider` (`FutureProvider.autoDispose`) in `kiosk/lib/features/auth/state/`, fetching the roster for the login screen to consume.

## Kiosk: UI flow

`LoginView` becomes a two-step flow, both steps still rendered inside the existing `LoginScreen` shell (brand panel unchanged):

**Step 1 — Select staff member**

- Responsive `GridView` of tiles, one per roster entry, following the kiosk's existing spacing/radius/shadow tokens (`POSRadius`, `POSColors`, `POSShadow`, `context.responsive`).
- Each tile shows: avatar image if `image` is set, otherwise a colored initials circle (first + last initial); first name + last initial below.
- Loading state: skeleton/spinner consistent with existing dialogs (e.g. `_LoginLoadingDialog` styling).
- Error state (roster fetch failed): retry affordance with the existing `_ErrorBanner` styling — without the roster, no one can log in, so this can't be a silent failure.
- Empty state (no active users returned): message directing the user to contact an admin. This is an unexpected operational state, not a normal empty state, but the UI must not dead-end silently.

**Step 2 — Enter PIN**

- Reuses the existing `_PinSection` (`PinIndicator`) and `PinPad` exactly as they work today.
- Shows the selected user's name and a back control that returns to Step 1 and clears the in-progress PIN.
- On PIN completion, calls `LoginStateNotifier.login(selectedUser.userId, pin)` — same call as today, just sourced from the tile selection instead of a text field.
- Wrong-PIN error handling is unchanged (`_ErrorBanner` + PIN reset), scoped to this step.

**Removed:** `kiosk/lib/features/auth/view/username_input.dart` and its usage — no longer needed once typed username entry is fully replaced.

## Data flow summary

```
LoginScreen
  └─ LoginView (step state: grid | pin)
       ├─ Step "grid": loginRosterProvider → UserApi.getLoginRoster() → GET /api/v1/users/roster (public)
       │      tap tile → step = "pin", selectedUser set
       └─ Step "pin": PinPad → LoginStateNotifier.login(selectedUser.userId, pin)
              → AuthRepository.login() → POST /api/v1/auth/login (unchanged)
```

## Error handling summary

| Condition | Behavior |
|---|---|
| Roster fetch fails (network/server) | Error state on grid step, with retry |
| Roster fetch succeeds but empty | Empty-state message, contact-admin guidance |
| Wrong PIN | Existing error banner + PIN reset, stays on PIN step for same user |
| PIN step abandoned | Back control returns to grid, clears PIN, does not refetch roster |

## Testing

- Backend: unit test for `UsersService.findLoginRoster()` (filters out locked/inactive users, correct field selection) and a controller test confirming the route is reachable without a JWT.
- Kiosk: widget test for the grid step (loading/error/empty/populated) and for the two-step transition (tile tap → PIN step → back navigation).
