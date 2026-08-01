# Built-in printer support for mobile (Nyx POS terminals)

## Problem

The mobile app currently prints receipts only via an externally-paired Bluetooth thermal
printer (`lib/core/services/print_service.dart` + `PrinterSetupScreen`). The device this
work is developed against — a MIRAY/NB55 Android POS terminal — has a **built-in** thermal
printer exposed through the `net.nyx.printerservice` system app, which is common across
white-label "Nyx" Android POS terminals. Confirmed on-device via `adb`:

- `net.nyx.printerservice` is installed (versionName `1.3.3`).
- It exposes an AIDL service (`net.nyx.printerservice.IPrinterService`) for direct printing,
  and separately registers as a standard Android `PrintService` and a Bluetooth print service
  — this design uses the AIDL route for a silent, dialog-free print.
- The printer is **tear-bar**, not auto-cut — no cut command is needed, just a trailing feed.

Additionally, the current Bluetooth `printReceipt()` output does not match everything shown
in the on-screen receipt preview (`_ReceiptPreview` in `receipt_screen.dart`): it omits the
REFUNDS section and the VOID REASON block that the preview renders when applicable. This
work brings both print paths to full content parity with the preview.

## Scope

- Detect the built-in Nyx printer at print time and use it when present, preferring it over
  the paired Bluetooth printer. Fall back to the existing Bluetooth path when the built-in
  printer is unavailable.
- Bring printed receipt content to parity with `_ReceiptPreview`: store info + "Sales
  Invoice" label, items with discount-beneficiary sub-lines, VAT/summary rows, a REFUNDS
  section when `receipt.hasRefunds`, a VOID REASON block when `receipt.isVoided`, and the
  payment section — for **both** the built-in and Bluetooth print paths.
- Out of scope: X-Reading / Daily Report / Z-Reading printing (`printXReading`,
  `printDailyReport`, `printZReading`) — these stay on the existing Bluetooth-only path
  unchanged. Auto-cut logic, barcode/QR printing, cash-drawer/LCD features exposed by the
  Nyx AIDL are not used.

## Design

### Shared receipt formatting: `ReceiptPrintDocument`

New pure-Dart file `lib/core/services/receipt_print_document.dart`. Builds an ordered list of
abstract print instructions from a `Receipt` (plus store info/currency), so both printers
render from the same source instead of each hand-building output from `Receipt` fields:

```dart
sealed class PrintInstruction {}
class PrintText extends PrintInstruction {
  final String text;
  final PrintAlign align;
  final bool bold;
  final int sizeMultiplier; // 1 = normal, 2 = double (used for headers)
}
class PrintRow extends PrintInstruction {
  final List<String> columns; // e.g. [label, amount]
  final List<int> weights;    // column width weights, e.g. [8, 4]
  final PrintAlign lastColumnAlign;
  final bool bold;
}
class PrintDivider extends PrintInstruction {
  final String char; // '*' or '-', matches _ReceiptDivider
}
class PrintFeed extends PrintInstruction {
  final int lines;
}

abstract final class ReceiptPrintDocument {
  static List<PrintInstruction> build(
    Receipt receipt, {
    required String currency,
    String? storeName,
    String? storeAddress,
    String? storeTin,
    String? terminalName,
    String storeFooter = 'Thank you!',
  });
}
```

`build()` mirrors `_ReceiptPreview` section-for-section:

1. Store name / address / TIN (centered), then "Sales Invoice" label
2. `*` divider
3. Date, `SI# <docNumber>`, cashier, terminal (if provided)
4. `*` divider
5. Items — qty + description + amount; a `LESS: <discountType> — <beneficiaryName>
   (<beneficiaryId>)` sub-line when `item.discountBeneficiaryName` is set (matches
   `_ItemsView`)
6. `-` divider
7. VATable Sales / VAT-Exempt Sales (if > 0) / VAT / Discount (if > 0) / Total rows (matches
   `_SummaryView`)
8. **If `receipt.hasRefunds`:** `-` divider, `REFUNDS` header row, then per refund: reason
   line + refunded line items (qty + description + `-amount`), `Total Refund` row, `-`
   divider, `Net Total` row (matches `_RefundsView`)
9. **If `receipt.isVoided` and `receipt.voidReason != null`:** `-` divider, `VOID REASON:`
   text, then the reason text (matches the preview's void block)
10. Payment section: cash → Tendered + Change rows; else → method + amount, and a `Ref:
    <reference>` line if present (matches `_PaymentView`)
11. `storeFooter` (or `'Thank you!'` if empty), feed 1 line, then feed 3 more lines for
    tear-bar clearance (no cut — confirmed tear-bar hardware)

### `PrintService.printReceipt()` — routing

`lib/core/services/print_service.dart`'s existing `printReceipt()` becomes the single entry
point used by `ReceiptNotifier`/`receipt_screen.dart`. It changes to:

```dart
static Future<bool> printReceipt(Receipt receipt, {...}) async {
  final document = ReceiptPrintDocument.build(receipt, currency: currency, ...);

  if (await BuiltInPrinter.isAvailable()) {
    return BuiltInPrinter.print(document);
  }

  return _printViaBluetooth(document); // existing bytes-building logic, now consuming
                                        // `document` instead of `receipt` fields directly
}
```

The existing bytes-building code in `printReceipt()` is refactored into a private
`_printViaBluetooth(List<PrintInstruction> document)` that walks the same instruction list
and emits ESC/POS bytes via `Generator` (mapping `PrintRow` → `generator.row(...)`,
`PrintDivider` → `generator.hr()`, etc.) — this is what closes the current parity gap on the
Bluetooth path.

`printXReading`, `printDailyReport`, `printZReading` are untouched (out of scope).

### `BuiltInPrinter` — new Dart service

New `lib/core/services/built_in_printer.dart`:

```dart
abstract final class BuiltInPrinter {
  static bool? _availableCache;

  static Future<bool> isAvailable() async {
    _availableCache ??= await _channel.invokeMethod<bool>('isAvailable') ?? false;
    return _availableCache!;
  }

  static Future<bool> print(List<PrintInstruction> document) async {
    final payload = document.map(_encodeInstruction).toList();
    return await _channel.invokeMethod<bool>('printDocument', payload) ?? false;
  }
}
```

`_encodeInstruction` serializes each `PrintInstruction` to a `Map` (e.g.
`{'type': 'text', 'text': ..., 'align': ..., 'bold': ..., 'sizeMultiplier': ...}`,
`{'type': 'row', 'columns': [...], 'weights': [...], ...}`, etc.) for the method channel.

`isAvailable()`'s result is cached for the process lifetime — package presence on a given
device doesn't change at runtime.

### Native plugin (Android / Kotlin)

**AIDL files**, copied verbatim (package path must match exactly, per the SDK's own
requirement) into the mobile Android project:

- `android/app/src/main/aidl/net/nyx/printerservice/print/IPrinterService.aidl`
- `android/app/src/main/aidl/net/nyx/printerservice/print/PrintTextFormat.aidl`
- `android/app/src/main/java/net/nyx/printerservice/print/PrintTextFormat.java`

Relevant AIDL surface (confirmed from the upstream Nyx `PrinterClient` SDK):

```
int printText(String text, in PrintTextFormat textFormat);
int printTableText(in String[] texts, in int[] weights, in PrintTextFormat[] formats);
int paperOut(int px);
int getPrinterStatus();
```

`PrintTextFormat` fields used: `textSize`, `ali` (0/1/2 = left/center/right), `style` (bold
etc.), used to express `PrintText.align`/`.bold`/`.sizeMultiplier`.

**`NyxPrinterPlugin.kt`** (new, `android/app/src/main/kotlin/com/dpo/mobile/`):

- Registered manually in `MainActivity.kt` (`flutterEngine.plugins.add(NyxPrinterPlugin())`)
  since this is not a pub package.
- `MethodChannel("com.dpo.mobile/nyx_printer")`:
  - `isAvailable` — `PackageManager` check for `net.nyx.printerservice` being installed. No
    service binding needed for this check.
  - `printDocument(List<Map>)` — binds the service
    (`Intent("net.nyx.printerservice.IPrinterService").setPackage("net.nyx.printerservice")`
    + `bindService`), awaits `onServiceConnected` with a ~3s timeout, then walks the
    instruction list sequentially against `IPrinterService.Stub.asInterface(binder)`:
    - `text` → `printText(text, PrintTextFormat)`
    - `row` → `printTableText(columns, weights, formats)`
    - `divider` → synthesized `printText("-".repeat(n), ...)` (no native rule primitive)
    - `feed` → `paperOut(lines * lineHeightPx)`
  - Unbinds the service after completion or timeout. Any exception during binding or an AIDL
    call is caught and the method channel returns `false` (never throws to Dart).

**`AndroidManifest.xml`** — add a `<queries>` entry for `net.nyx.printerservice` (Android
11+ package visibility), alongside the existing `PROCESS_TEXT` queries block.

## Error handling

- `BuiltInPrinter.isAvailable() == false` is not an error — it's the normal "no built-in
  printer on this device" case, falling through to the Bluetooth path exactly as today.
- Bind timeout or any AIDL call throwing is caught natively; the method channel returns
  `false` rather than throwing. `PrintService.printReceipt()` then returns `false` up to the
  UI, which already shows the "No printer configured — go to Settings → Printer Setup"
  snackbar in `receipt_screen.dart` — message wording may need a small tweak since the
  failure could now be a built-in-printer error rather than "no printer configured", but the
  UX flow (snackbar, no dialog, cashier can retry) is unchanged.
- No retry logic — matches the existing Bluetooth path's single-attempt behavior.

## Testing

- Unit tests for `ReceiptPrintDocument.build()` against representative `Receipt` fixtures
  (plain, with item discount, with refund, voided) asserting the produced instruction list —
  this is testable without hardware and is what guarantees preview/print parity.
- The Kotlin plugin and actual AIDL calls can only be verified on physical Nyx-based hardware
  (`flutter run -d <device-id>` on the MIRAY unit) — no emulator has `net.nyx.printerservice`
  installed. Manual verification: print a plain sale, a sale with a senior/PWD discount, a
  refunded sale, and a voided sale, and confirm each matches its on-screen preview.
- Manual verification that Bluetooth printing still works unchanged when the built-in
  printer path reports unavailable (e.g. temporarily uninstall/disable
  `net.nyx.printerservice` via `adb`, or test on a non-Nyx device).
