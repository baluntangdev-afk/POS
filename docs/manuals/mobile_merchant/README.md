# Cartivo Merchant manuals

Two end-user manuals for the `mobile_merchant/` Flutter app (the third-party
merchant live-orders companion), generated as styled HTML and rendered to PDF.

| File | Audience | Covers |
|---|---|---|
| `CartivoMerchant-User-Manual.pdf` | Merchant staff, store owners, front-of-house | What the app is (and isn't), what you need, registering your merchant, getting the device approved (pending / approved / deactivated), the dashboard toolbar and connection pill, the Orders list and filter tabs, working an order through the status flow, cancelling, the order detail sheet, alerts & notifications, Merchant Settings (rename vs. switch Merchant ID), behaviour when the connection drops, daily routine, troubleshooting & FAQ. |
| `CartivoMerchant-Technical-Manual.pdf` | Developers, integrators, IT | Tech stack, repo layout & feature-module rules, `.env` reference + WebSocket-URL derivation, local dev & codegen, the three-call device-auth chain (`/auth/token` → `/devices/register` → `/devices/token`) and 15s approval polling, the live-orders WebSocket feed (state machine, backoff, de-dupe ring, hydration mute, wire frame), REST endpoints (`GET`/`PATCH /merchant/orders`), Drift DB + secure-storage keys, Riverpod providers & list-merge rules, notifications, **Android config incl. the release-manifest `INTERNET` caveat**, release build & pre-flight checklist, troubleshooting, known constraints. |

## Regenerating

Requires Python 3 and Google Chrome or Microsoft Edge (run headless to print the PDF).

```bash
cd docs/manuals/mobile_merchant
python build_manuals.py
```

- `build_manuals.py` — layout, CSS, cover/TOC template, and the render-to-PDF step.
- `content_user.py` / `content_tech.py` — the manual text.
- `manual_helpers.py` — shared markup helpers.

Edit the content modules and re-run. Both `.html` and `.pdf` are written next to the script.
