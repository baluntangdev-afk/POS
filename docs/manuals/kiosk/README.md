# POS Kiosk manuals

Four end-user manuals, generated as styled HTML and rendered to PDF.

| File | Audience | Covers |
|---|---|---|
| `POSKiosk-Kiosk-User-Manual.pdf` | Cashiers, supervisors, store admins | Signing in, and every kiosk screen/module step by step (New Order, Discounts, Payment, Orders, Transactions, X/Z/Daily readings, Inventory, Modifier Groups, Users, Settings, Backup & Transfer, customer display, troubleshooting). |
| `POSKiosk-Kiosk-Technical-Manual.pdf` | Developers, integrators, IT | Flutter architecture, `.env`, codegen, routes, feature→endpoint map, Windows specifics, release build, packaging, troubleshooting. |
| `POSKiosk-Backend-Operations-Manual.pdf` | Store owners/managers (non-technical) | What the backend service does, health checks, Swagger tour, a plain-language description of every module, backups, restarting the service. |
| `POSKiosk-Backend-Technical-Manual.pdf` | Backend developers, DevOps | NestJS architecture, env reference, command reference, auth flow, full API reference for every module, health, ERP sync, device-transfer internals, migrations, SEA build + Windows installer. |

## Regenerating

Requires Python 3 and Google Chrome or Microsoft Edge (used headless to print the PDF).

```bash
cd docs/manuals
python build_manuals.py
```

Content lives in the `content_*.py` modules; shared markup helpers in `manual_helpers.py`;
layout/CSS and the cover/TOC template in `build_manuals.py`. Edit those and re-run.

> `gen-admin-manual.js` is the older standalone Word (`.docx`) admin manual generator; it is
> independent of this Python pipeline.
