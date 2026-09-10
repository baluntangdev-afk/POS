# POS Mobile manuals

Two end-user manuals for the Flutter POS app in `mobile/`, generated as styled
HTML and rendered to PDF.

| File | Audience | Covers |
|---|---|---|
| `POSMobile-User-Manual.pdf` | Store owners, managers, supervisors, cashiers | Roles, first-time setup, sign-in/PINs, dashboard, taking an order, discounts, payment, receipts & voids, transactions, live online orders, cashier accounting (X/Z/Daily readings + export), inventory, users, settings, backups, printer setup, daily routine, troubleshooting/FAQ. |
| `POSMobile-Technical-Manual.pdf` | Developers, integrators, IT | Tech stack, repo layout, `.env` reference, dev setup & codegen, local Drift database + table reference, auth/roles & router guard, full route table, state management, live-orders architecture (WebSocket + device registration), printing, backups, CSV import/export, Android config (incl. the release-manifest INTERNET caveat), release build, Windows notes, troubleshooting, constraints. |

## Regenerating

Requires Python 3 and Google Chrome or Microsoft Edge (run headless to print the PDF).

```bash
cd docs/manuals/mobile
python build_manuals.py
```

- `build_manuals.py` — layout, CSS, cover/TOC template, and the render-to-PDF step.
- `content_user.py` / `content_tech.py` — the manual text.
- `manual_helpers.py` — shared markup helpers.

Edit the content modules and re-run. Both `.html` and `.pdf` are written next to the script.
