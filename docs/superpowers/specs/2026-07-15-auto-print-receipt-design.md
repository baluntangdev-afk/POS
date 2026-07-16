# Auto-print receipt after successful transaction

## Problem

After a cashier confirms payment and lands on `ReceiptScreen`, the receipt must be printed manually by tapping the "Print Receipt" button. The kiosk should print automatically as soon as a fresh transaction completes, without requiring that tap.

## Scope

- Auto-print fires only when arriving at the receipt screen immediately after a payment is confirmed (`PaymentScreen` → `confirmSale()` → navigate to `ReceiptRoute`).
- Auto-print must NOT fire when a cashier reopens a past receipt from `TransactionsScreen` (transaction history).
- Auto-print must NOT fire for voided receipts.
- Non-Windows platforms are unaffected — printing already no-ops there.

## Design

### Route param: `autoPrint`

`ReceiptRoute` (`kiosk/lib/navigation/sales_route.dart`) gains a second, optional constructor parameter:

```dart
class ReceiptRoute extends GoRouteData with $ReceiptRoute {
  const ReceiptRoute(this.receiptId, {this.autoPrint = false});

  final String receiptId;
  final bool autoPrint;
  ...
}
```

Because `autoPrint` isn't part of the URL path, it travels as in-memory route-data state (go_router_builder supports optional non-path fields as query-less extra data passed via the constructor at navigation time) — it does not need to persist across a browser-style deep link, since this is a Windows kiosk app driven entirely by in-app navigation.

- `PaymentScreen`'s `_ConfirmButton` navigation (`kiosk/lib/features/sales/view/payment_screen.dart:623`) changes to `ReceiptRoute(receipt.id, autoPrint: true).go(context)`.
- `TransactionsScreen`'s two "view receipt" call sites (`transactions_screen.dart:955`, `:1255`) are left unchanged — they call `ReceiptRoute(receipt.id).push<void>(context)`, defaulting `autoPrint` to `false`.

### Triggering the print

`ReceiptScreen` (`kiosk/lib/features/sales/view/receipt_screen.dart`) is currently a `ConsumerWidget`. It becomes a `HookConsumerWidget` so it can use `useEffect` to fire the print exactly once per screen instance.

The print is triggered from a `ref.listenManual` on `receiptProvider(receiptId)` inside a `useEffect`, firing as soon as the receipt data resolves for the first time (avoiding any race with the in-flight initial fetch):

```dart
final autoPrinted = useRef(false);

useEffect(() {
  if (!autoPrint) return null;
  final sub = ref.listenManual(receiptProvider(receiptId), (prev, next) {
    if (autoPrinted.value) return;
    if (next case AsyncData(:final value) when !value.isVoided) {
      autoPrinted.value = true;
      ReceiptNotifier.printAction.run(ref, (txn) {
        return txn.get(receiptProvider(receiptId).notifier).print();
      }).ignore();
    }
  });
  return sub.close;
}, const []);
```

`ref.listenManual` is used (rather than the widget-level `ref.listen` used elsewhere in this file for error dialogs) because it must live inside a `useEffect`/hook lifecycle callback, not directly in `build`. `autoPrinted` (a `useRef<bool>`) guards against the listener firing more than once (e.g. if the receipt later refreshes for an unrelated reason).

`.ignore()` on the returned mutation future means the auto-triggered print does not surface its own error dialog — it just updates the shared `printAction` mutation state, which the existing `_PrintButton` widget already renders (spinner while pending, "Print Receipt" if it ended in error, "Reprint" if it succeeded). This satisfies "silent failure, cashier reprints manually."

### No changes needed to:
- `ReceiptNotifier.print()` — reused as-is, including its existing Windows-only guard.
- `_PrintButton` — reused as-is; it already reflects `printAction` mutation state regardless of what triggered it.
- `encode_esc_pos_receipt.dart`, `win32_printer.dart` — untouched.

## Testing

- Manual verification (per project convention — this app has no widget/golden test coverage for this screen): complete a cash sale on the Windows kiosk build and confirm the receipt prints without tapping "Print Receipt", and that the button reads "Reprint" afterward.
- Open a past transaction from Transaction History and confirm nothing prints automatically.
- Simulate a printer failure (e.g. printer off) during a fresh-transaction auto-print and confirm no error dialog appears, and that the "Print Receipt" button is still tappable to retry.
