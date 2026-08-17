# Order Source Landing + Cartivo Merchant Login — Design

## Context

Today the kiosk boots into `StartupScreen` (backend health check), which on success navigates straight to `LoginRoute` — the existing user-roster + PIN login (`kiosk/lib/features/auth/view/login_screen.dart`). There is also an `OnboardingScreen`/`OnboardingRoute` ("Touch to Start" pulsing button) at `kiosk/lib/features/onboarding/`, but it is dead code: nothing in the app currently navigates to it.

The business now wants two ways to place an order: staff working the counter ("In Store", the existing roster/PIN flow) or a merchant signing in through **Cartivo**, a separate merchant-facing account system. This design adds a landing screen shown right after startup that lets the user pick one of the two, and a new visual-only Cartivo Merchant login screen matching a supplied reference design.

## Goals

- Show a new choice screen immediately after the startup health check, replacing the direct jump to `LoginRoute`.
- "In Store" choice leads to the existing user-roster + PIN login, unchanged in behavior.
- "Cartivo Merchant" choice leads to a new login screen matching the reference screenshot (email/password form, Cartivo branding, gradient Sign In button).
- Add back navigation from both login screens to the new choice screen.
- Remove the dead "Touch to Start" onboarding screen/route.

## Non-goals

- Any real authentication for Cartivo Merchant — no API calls, no validation, no navigation on Sign In. This is a visual mockup of the form only, per explicit instruction. Wiring it to a real merchant backend is future work.
- "Forgot Password?" / "Register" functionality on the Cartivo screen — rendered as visual elements matching the reference, not functional links.
- Changes to `LoginStateNotifier`, `AuthRepository`, or any roster/PIN business logic.
- Dark mode — out of scope, consistent with the rest of the kiosk today.

## Routing changes

```
StartupScreen (health check)
    → OrderSourceRoute        (NEW, path "/order-source")
        → LoginRoute              (existing, path "/login" — adds a back arrow)
        → CartivoLoginRoute       (NEW, path "/cartivo-login")
```

- `StartupScreen`: `const LoginRoute().go(context)` → `const OrderSourceRoute().go(context)`.
- New file `kiosk/lib/navigation/order_source_route.dart` (`part of 'router.dart'`), registered in `router.dart`'s `part` list and import list, following the exact pattern of `login_route.dart`.
- New file `kiosk/lib/navigation/cartivo_login_route.dart`, same pattern.
- Delete `kiosk/lib/features/onboarding/` (both `onboarding_screen.dart` and `onboarding_contents.dart`) and `kiosk/lib/navigation/onboarding_route.dart`, and remove its `part`/import from `router.dart`. Confirmed unreferenced anywhere else in the codebase.
- `dart run build_runner build --delete-conflicting-outputs` must be run after these route changes to regenerate `router.g.dart`.

## New feature: `order_source`

New folder `kiosk/lib/features/order_source/view/order_source_screen.dart`. View-only screen, no state/repository layer needed — it only makes two navigation decisions.

**Layout** (`OrderSourceScreen`, following the existing `AndroidScaffold`/`WindowsScaffold` + `LayoutBuilder` responsive split used by `LoginScreen`):

- Background: `POSColors.surfaceSubtle` (not the teal gradient — keeps focus on the two cards).
- Top: small centered lockup — `POS Kiosk` wordmark, consistent with the brand panel style used elsewhere but without a colored panel behind it.
- Headline: "How would you like to order?" — large, bold, `POSColors.textPrimary`, using the same responsive font-size pattern as `_SelectUserStep`'s "Who's working?" (`context.responsive.value<double>(phone: 26, tablet: 30, kiosk: 34)`).
- Two large touch cards, equal width, laid out in a `Row` on landscape/kiosk/tablet and a `Column` on portrait/phone (same `isPortrait` check pattern as `LoginScreen`):
  - **In Store** — `Icons.storefront_outlined`, title "In Store", subtitle "Staff login for counter orders". Card: `POSColors.surfaceElevated` background, `POSShadow.card`, `POSRadius.xl` corners, `ColorSet.primary` accent on the icon badge.
  - **Cartivo Merchant** — `Assets.images.cartivoLogo`, title "Cartivo Merchant", subtitle "Sign in with your merchant account". Card: same base styling, icon/logo badge accented with `POSGradient.primaryFaded` (teal→olive), matching the reference screenshot's button gradient.
- Both cards: minimum 72px touch height (exceeds the 48px CLAUDE.md minimum), scale/elevate on press using `POSAnimation.fast`, consistent with other kiosk tap targets.
- No back button on this screen — it's the first interactive screen after startup.
- Tapping "In Store" → `const LoginRoute().go(context)`. Tapping "Cartivo Merchant" → `const CartivoLoginRoute().go(context)`.

## New screen: `CartivoLoginScreen`

New file `kiosk/lib/features/auth/view/cartivo_login_screen.dart` (co-located with the existing `login_screen.dart` since it's conceptually a login screen), plus `cartivo_login_view.dart` for the form content.

Reuses `LoginScreen`'s structural shell (brand panel + white form panel, `Row` on landscape / `Column` on portrait, same responsive breakpoints, `AndroidScaffold`/`WindowsScaffold` split) so it feels native rather than a bolted-on page.

**Brand panel**: same layout as `_BrandPanel` in `login_screen.dart`, but:
- Gradient swapped from `POSGradient.header` to `POSGradient.primaryFaded` (teal→olive).
- `Assets.images.cartivoLogo` in place of the generic logo mark.

**Form panel** (matches the reference screenshot):
- Back arrow (`Icons.arrow_back_rounded`) top-left → `const OrderSourceRoute().go(context)`. Same placement/style added to `LoginScreen`'s form panel (see below), for visual consistency between the two login screens.
- Centered Cartivo logo (`Assets.images.cartivoLogo`).
- Headline: "Sign in to your account." (bold).
- Subtext: "Enter your email and password to sign in." (`POSColors.textTertiary`).
- Email field: labeled "Email", filled input, placeholder `yourname@example.com`, standard `TextField`/`TextFormField` styled with the kiosk's existing filled-input look (soft border, `POSRadius.md`, focus glow — matching CLAUDE.md input guidance; no existing shared input widget was found in `lib/widgets/`, so this introduces a plain styled `TextField`, not a new reusable component, since only one screen needs it right now).
- Password field: labeled "Password", filled input, obscured by default, trailing eye icon (`Icons.visibility_outlined` / `Icons.visibility_off_outlined`) toggling `obscureText` via local `useState`.
- Row: "Forgot Password?" (left) and "Register" (right) — static `Text` widgets styled as tappable links (`ColorSet.primary` or `POSColors.textTertiary`), no `onTap` handler (non-functional per non-goals).
- Full-width "Sign In" button: `POSGradient.primaryFaded` background, `POSRadius.md`/`lg` corners, white bold label, ≥56px height. `onTap` only toggles a brief local pressed/loading visual (e.g. 400–600ms fake delay using `POSAnimation` timings) and then resets — no navigation, no API call, no form validation.
- All spacing/typography follows `context.responsive.value(...)` the same way `LoginView` does, so the screen scales correctly across kiosk/tablet/phone.

## Change to existing `LoginScreen`

Add a back arrow (`Icons.arrow_back_rounded`, same icon/placement as the new Cartivo screen) to the top-left of the form panel, calling `const OrderSourceRoute().go(context)`. This is a pure additive UI change — `LoginView`'s roster/PIN logic, state, and API calls are untouched.

## Data flow summary

```
StartupScreen
  └─ health check OK → OrderSourceRoute
       ├─ tap "In Store"         → LoginRoute → LoginView (existing roster/PIN flow, unchanged)
       │        (back arrow → OrderSourceRoute)
       └─ tap "Cartivo Merchant" → CartivoLoginRoute → CartivoLoginView (visual only, no API calls)
                (back arrow → OrderSourceRoute)
```

## Testing

- Kiosk: widget test for `OrderSourceScreen` confirming both cards navigate to the correct route.
- Kiosk: widget test for `CartivoLoginScreen` confirming the password field's visibility toggle works and the Sign In button does not navigate or throw.
- Kiosk: existing `LoginScreen`/`LoginView` tests remain valid unchanged; add a test that the new back arrow navigates to `OrderSourceRoute`.
- Manual: `flutter run -d windows` — verify the full flow (startup → order source → in store → back → cartivo merchant → back) across kiosk-sized and portrait window dimensions.
