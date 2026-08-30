# Encrypted CSV Export for Cashier Reports — Design Spec

**Date:** 2026-08-30
**Feature branch:** feature/socket (mobile only)
**Scope:** Mobile app — X-Reading, Z-Reading, Daily Report

---

## Overview

When a cashier or admin generates any of the three report types (X-Reading, Z-Reading, Daily Report), they can export the full transaction list for that period as an AES-256-CBC encrypted CSV file saved to the device's Downloads folder. The file can only be decrypted with a 32-byte key that is stored in Flutter Secure Storage and viewable (once, masked by default) in app Settings.

---

## CSV Structure

Every exported file is a plain UTF-8 CSV with three logical sections separated by a blank row. All monetary values are formatted to 2 decimal places. Dates use `YYYY-MM-DD`, times use `HH:mm` (24-hour, local timezone).

### Section 1 — Report Header

Key/value rows (2 columns: `Field`, `Value`).

| Field | Example Value |
|---|---|
| Report Type | X-Reading |
| Store Name | Jufie's Cafe |
| Cashier | John Doe |
| Period Start | 2026-08-29 08:00 |
| Period End | 2026-08-29 17:30 |
| Generated At | 2026-08-29 17:35 |
| Total Sales | 12500.00 |
| Total Transactions | 45 |
| Completed | 40 |
| Voided | 3 |
| Refunded | 2 |
| Total Discounts | 500.00 |
| Vatable Sales | 11160.71 |
| VAT Amount | 1339.29 |
| VAT Exempt Sales | 0.00 |
| Cash Collected | 8000.00 |

> **Z-Reading only** — appends a sub-table at the end of Section 1 for per-cashier breakdown:
> `Cashier Breakdown` header row, then one row per cashier: `Cashier Name`, `Sales Total`, `Transaction Count`.

### Section 2 — Payment Breakdown

Column headers: `Payment Method`, `Amount`, `Count`.
One row per payment method that appeared in the period.

```
Payment Method,Amount,Count
Cash,8000.00,30
Card,3500.00,12
E-Wallet,1000.00,3
```

### Section 3 — Transaction Detail

One row per transaction, ordered by date/time ascending.

Columns:
`Invoice No`, `Date`, `Time`, `Cashier`, `Type`, `Status`, `Payment Method`, `Gross Total`, `Discount`, `Refunded`, `Net Total`, `Void Reason`

- **Invoice No** — `soNumber` if set, otherwise `#000001` (sale ID zero-padded to 6 digits)
- **Type** — human-readable: `Dine In`, `Take Out`, `Delivery`
- **Status** — `Completed`, `Voided`, `Refunded`
- **Payment Method** — comma-joined list of methods when a sale has multiple payments (e.g., `Cash, Card`)
- **Void Reason** — empty string if not voided
- **Net Total** — `max(0, gross - discount - refunded)`

---

## Encryption

### Algorithm

AES-256-CBC with PKCS7 padding. Chosen over GCM for maximum compatibility with external decryption tools (CyberChef, Python `Crypto.Cipher.AES`, OpenSSL).

### Key Management

- A 32-byte (256-bit) key is generated once on first use via `dart:math`'s `Random.secure()`.
- Stored persistently in `FlutterSecureStorage` under the key `csv_export_aes_key` (same storage used by webhook auth).
- The key is **never** hard-coded or derived from app secrets — it is unique per device/installation.

### File Format

```
[16 bytes: random IV] ++ [N bytes: AES-256-CBC encrypted UTF-8 CSV]
```

- IV is freshly generated per export using `Random.secure()`.
- Total file overhead: 16 bytes.
- The encrypted blob is written as raw bytes (not base64).

### File Naming

```
{report_type}_{YYYYMMDD}_{HHmm}_{cashier_slug}.enc
```

Examples:
- `xreading_20260829_0800_johndoe.enc`
- `zreading_20260829_1730_store.enc`
- `dailyreport_20260829_0800_janedoe.enc`

Cashier slug: lowercase, spaces → underscores, non-alphanumeric stripped.
Z-Reading uses `store` as the cashier slug since it is store-wide.

### Save Location

Saved to the device Downloads directory via `path_provider`'s `getDownloadsDirectory()` (Android). A success snackbar shows the file path after saving.

---

## New Package

```yaml
encrypt: ^5.0.3
```

Uses PointyCastle under the hood — pure Dart, no native code, no additional Android/iOS permissions needed.

---

## Key Management UI (Settings)

A new **"CSV Export Key"** tile is added to the existing Settings screen.

- Label: `CSV Export Key`
- Value: masked (`••••••••`) by default
- **Eye icon** — tap to reveal the full hex-encoded key (64 hex chars)
- **Copy icon** — copies hex key to clipboard, shows "Copied" confirmation
- **Regenerate** button — shows a confirmation dialog warning that existing `.enc` files cannot be decrypted with the new key; on confirm, generates and saves a new key

The key is displayed and stored as a lowercase hex string (64 characters). Users share this string with whoever needs to decrypt the exports.

---

## Export Trigger — Where the Button Lives

An **Export CSV** button (icon: `Icons.download`) is added to the app bar of:

| Screen | Provider used for data |
|---|---|
| X-Reading live screen | `xReadingProvider` |
| X-Reading history detail | `xReadingHistoryRowProvider(id)` |
| Z-Reading live screen | `zReadingProvider` |
| Z-Reading history detail | `zReadingHistoryRowProvider(id)` |
| Daily Report live screen | `dailyReportProvider` |
| Daily Report history detail | `dailyReportHistoryRowProvider(id)` |

The button is disabled (grayed) while export is in progress. A circular progress indicator replaces the icon during the async write. If the report has no transactions yet (period start is null), the button is hidden entirely.

---

## Data Fetching for Transaction Detail

The transaction detail rows require a new DAO method that fetches all transactions in a date range without pagination, joined with payment methods. The existing `getTransactions` method is paginated and cannot be used directly.

**New DAO method (SalesDao):**

```dart
Future<List<TransactionExportRow>> getTransactionsForExport({
  required DateTime from,
  required DateTime to,
  int? cashierId,
})
```

`TransactionExportRow` is a plain Dart class (not a drift `DataClass`) that holds all `TransactionSummary` fields plus `paymentMethods: List<String>`. It is assembled in Dart after two queries: one for sales (joined with users for cashier name and refunds for refunded amount, same as `getTransactions`), and one bulk-fetch of all `PaymentsTable` rows for those sale IDs (same pattern as `_refundedAmountsBySaleIds`).

---

## Code Structure

```
lib/
  core/
    csv/
      csv_exporter.dart              # abstract interface CsvExporter
      report_csv_builder.dart        # builds the CSV string from report data
      report_csv_exporter.dart       # encrypts + saves; implements CsvExporter
    crypto/
      csv_encryption_key_store.dart  # generates, stores, retrieves the AES key
      csv_encrypter.dart             # encrypt(String plaintext) → Uint8List
  features/
    settings/
      view/
        settings_screen.dart         # (modified) add CSV Export Key tile
    cashier_accounting/
      shared/
        export_csv_button.dart       # reusable AppBar action widget
```

`ReportCsvBuilder` is a pure function class — it takes typed report data and returns a `String`. It has no I/O and is straightforwardly unit-testable.

`ReportCsvExporter` calls `ReportCsvBuilder`, then `CsvEncrypter`, then writes the result to disk. It is the only class that does I/O.

`ExportCsvButton` is a `ConsumerWidget` that reads the relevant provider, calls `ReportCsvExporter`, and handles loading/error state locally.

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| No transactions in period | Export button hidden |
| Export key not yet generated | Key is auto-generated on first tap (no user prompt) |
| Downloads directory unavailable | Snackbar: "Could not access Downloads folder" |
| Disk write fails | Snackbar: "Export failed — check storage space" |
| Export succeeds | Snackbar: "Saved to Downloads/{filename}" |

---

## Testing

- **Unit test — `ReportCsvBuilder`:** Given known `XReadingData` + transactions, assert the CSV string has the correct header rows, section separators, payment breakdown rows, and transaction rows in ascending time order.
- **Unit test — `CsvEncrypter`:** Encrypt a known string, decrypt with the same key+IV, assert round-trip equality. Assert that different IVs produce different ciphertexts.
- **Unit test — `CsvEncryptionKeyStore`:** Given a mock `FlutterSecureStorage`, assert key is generated once and reused on subsequent calls.
- No widget tests for `ExportCsvButton` — behaviour is covered by the unit tests above; the button itself is a thin glue layer.

---

## Out of Scope

- In-app CSV decryption / viewer (decrypt on device to read the file)
- Automatic export on report close (export is always manually triggered)
- Email or share-sheet delivery (save to Downloads only, as requested)
- Key rotation strategy beyond the manual "Regenerate" button
