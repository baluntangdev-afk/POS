# Bluetooth printer scan, pairing, and explicit built-in/Bluetooth print choice (mobile)

## Problem

The mobile printer setup (`lib/features/settings/view/printer_setup_screen.dart`) only lists
already-**paired** Bluetooth devices (`PrintBluetoothThermal.pairedBluetooths`) — a printer
must first be paired through Android's system Bluetooth settings before it shows up in-app.
The underlying `print_bluetooth_thermal` package (v1.2.1) has no way to:

- prompt the user to turn Bluetooth on (`bluetoothEnabled` only checks, never requests),
- actually request the Android 12+ runtime permission it needs (`ispermissionbluetoothgranted`
  checks `BLUETOOTH_CONNECT` but its own request-permission code path is dead/commented out
  in the plugin's Kotlin source), or
- discover new, unpaired nearby devices (Android `pairedBluetooths` only returns bonded
  devices) or pair them.

`AndroidManifest.xml` currently declares no Bluetooth permissions of its own (they arrive only
transitively from the plugin's manifest), and no permission-request package is installed.

Separately, `receipt_screen.dart`'s single "Print Receipt" button calls
`PrintService.printReceipt()`, which silently auto-picks the built-in printer if present,
falling back to Bluetooth — the user has no way to explicitly choose which printer a given
receipt goes to.

## Scope

- Bluetooth-enable prompt, runtime permission handling (including the pre-Android-12
  location-permission/Location-Services requirement), live discovery of unpaired nearby
  devices, and in-app pairing — added to `PrinterSetupScreen`.
- Two explicit print buttons on `receipt_screen.dart`: built-in and Bluetooth.
- Out of scope: X-Reading / Daily Report / Z-Reading print screens — these keep their existing
  single-button auto-dispatch print flow unchanged. No changes to the actual print/formatting
  logic (`ReceiptPrintDocument`, `BuiltInPrinter`, existing Bluetooth byte-encoding) — this
  work is entirely about *discovering, enabling, and choosing* a printer, not printing itself.

## Design

### New native layer: `BluetoothDiscoveryPlugin.kt`

New file `android/app/src/main/kotlin/com/dpo/mobile/BluetoothDiscoveryPlugin.kt`, registered
manually in `MainActivity.kt` (same pattern as the existing `NyxPrinterPlugin` from the
built-in-printer work) since it needs `Activity`-scoped permission-result callbacks, not just
an `ApplicationContext`.

**`MethodChannel("com.dpo.mobile/bt_discovery")`:**

- `checkPermissions()` — returns whether the permissions discovery needs are already granted:
  `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` on API 31+; `ACCESS_FINE_LOCATION` below that (legacy
  `BLUETOOTH`/`BLUETOOTH_ADMIN` are normal/install-time, nothing to request there).
- `requestPermissions()` — `ActivityCompat.requestPermissions(...)`, resolves the pending
  method-channel result from `onRequestPermissionsResult`.
- `isPermanentlyDenied()` — `shouldShowRequestPermissionRationale == false` after a prior
  denial, used to switch the UI from "retry" to "open settings".
- `isLocationServicesEnabled()` — pre-Android-12 only (`LocationManager` check); Android 12+
  discovery doesn't need Location Services at all, so the UI skips this check on that OS
  version.
- `startDiscovery()` / `stopDiscovery()` — wraps `BluetoothAdapter.startDiscovery()` /
  `cancelDiscovery()`.
- `pairDevice(mac)` — `BluetoothDevice.createBond()` on the given address; result comes via the
  `bondStateChanged` event, not this call's return value (bonding is asynchronous on Android).

**`EventChannel("com.dpo.mobile/bt_discovery_events")`**, backed by a single
`BroadcastReceiver` registered for `ACTION_FOUND`, `ACTION_DISCOVERY_FINISHED`, and
`ACTION_BOND_STATE_CHANGED`, emitting to Dart as:

```
{'type': 'deviceFound', 'name': ..., 'mac': ...}
{'type': 'discoveryFinished'}
{'type': 'bondStateChanged', 'mac': ..., 'bonded': bool}
```

The receiver is registered when `startDiscovery` is called and unregistered on
`stopDiscovery`/plugin detach — it never runs while no scan is active.

### Flutter: `lib/core/services/bluetooth_discovery_service.dart` (new)

Thin wrapper exposing:

```dart
abstract final class BluetoothDiscoveryService {
  static Future<bool> isBluetoothEnabled();          // PrintBluetoothThermal.bluetoothEnabled
  static Future<void> requestEnableBluetooth();       // fires ACTION_REQUEST_ENABLE, no result
  static Future<PermissionState> checkPermissions();
  static Future<PermissionState> requestPermissions();
  static Future<bool> isLocationServicesEnabled();     // true (no-op) on API 31+
  static Stream<BluetoothDiscoveryEvent> startDiscovery(); // starts native scan, returns event stream
  static Future<void> stopDiscovery();
  static Future<bool> pairAndWait(String mac, {Duration timeout = const Duration(seconds: 15)});
}

enum PermissionState { granted, denied, permanentlyDenied }

sealed class BluetoothDiscoveryEvent {}
class DeviceFoundEvent extends BluetoothDiscoveryEvent { final String name, mac; }
class DiscoveryFinishedEvent extends BluetoothDiscoveryEvent {}
class BondStateChangedEvent extends BluetoothDiscoveryEvent { final String mac; final bool bonded; }
```

`requestEnableBluetooth()` uses `android_intent_plus`'s `AndroidIntent` to fire
`android.bluetooth.adapter.action.REQUEST_ENABLE`. This intent doesn't return a result to Dart,
so the caller (the setup screen) re-checks `isBluetoothEnabled()` on
`AppLifecycleState.resumed` and continues the scan automatically if it's now on.

`checkPermissions()`/`requestPermissions()` are implemented with `permission_handler` rather
than raw platform-channel calls where possible (it already wraps the exact
`Permission.bluetoothScan` / `Permission.bluetoothConnect` / `Permission.locationWhenInUse`
checks needed here) — the custom `BluetoothDiscoveryPlugin` channel is reserved for the two
things no maintained package does for classic/SPP Bluetooth: discovery and pairing.

`print_bluetooth_thermal` is untouched — still used for `pairedBluetooths`, `connect`,
`writeBytes`, `disconnect`.

### `AndroidManifest.xml`

Explicit permission declarations (most already arrive transitively from
`print_bluetooth_thermal`'s manifest, but declaring them directly makes the SDK-version splits
correct and the requirement visible in this project):

```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

### `PrinterSetupScreen` — scan, permission, and pairing UX

Replaces the "Scan Paired Devices" button with **"Scan for Printers"**. Tapping it runs, in
order, bailing out to an inline prompt/message at the first unmet step:

1. **Permission not granted** → `requestPermissions()`. If denied, inline message + "Grant
   Permission" retry button; if permanently denied, "Open App Settings" instead
   (`permission_handler`'s `openAppSettings()`). **Must run before step 2** — see note below.
2. **Bluetooth adapter off** → dialog "Bluetooth is off. Turn it on to scan for printers?" →
   confirm fires `requestEnableBluetooth()`. On app resume, re-check and auto-continue.
3. **Pre-Android-12 and Location Services off** → inline message explaining discovery needs
   Location Services on this Android version, with a button opening system location settings.
   Skipped entirely on Android 12+.
4. All clear → `startDiscovery()`, subscribe to the event stream.

**Why permission comes first:** `print_bluetooth_thermal`'s native Android handler (confirmed
from its bundled source, v1.2.1) has a bug — on API 31+, if `BLUETOOTH_CONNECT` isn't yet
granted, its `onMethodCall` hits a branch that logs a warning and returns *without* calling
`result.success()`/`result.error()` for any method other than its own permission check,
including `bluetoothEnabled`. That leaves the Dart-side `await` hanging forever rather than
throwing. Since step 2 above (`isBluetoothEnabled()`) goes through that same plugin, checking
Bluetooth state before requesting permission would silently strand every fresh install with no
error and no permission prompt ever shown. Requesting permission first avoids the call
entirely until `BLUETOOTH_CONNECT` is granted.

This full sequence re-runs on every "Scan" tap (all checks are cheap — no caching needed), not
just on first screen load.

**Device list** — two sections over the same underlying state:

- **PAIRED** — from `PrintBluetoothThermal.pairedBluetooths`, refreshed on screen load and
  after any successful pairing.
- **AVAILABLE** — populated live from `DeviceFoundEvent`s during a scan; cleared at the start
  of each new scan. Events are batched into the list via a single `setState` per animation
  frame (not one per event) to avoid rebuild storms during a busy scan.

Tapping a **paired** device: unchanged — connects and saves it as the selected printer (existing
`connect()` flow).

Tapping an **available** device: shows a per-tile spinner (not a global one, so the rest of the
list stays interactive), calls `pairAndWait(mac)`. On success: connects and saves as the
selected printer immediately (one-tap pair-and-select, per your call), and the tile moves out
of AVAILABLE. On failure/timeout: inline error on that tile only.

Scan auto-stops after Android's own ~12s discovery window (surfaced via
`DiscoveryFinishedEvent`) or when the screen is disposed (`stopDiscovery()` +
cancel the event subscription in `dispose()`), so a scan never keeps running in the
background or after navigating away.

### `receipt_screen.dart` — two explicit print buttons

Replaces the single "Print Receipt" button:

- **"Print (Built-in)"** — visible whenever `BuiltInPrinter.isAvailable()` is true (uses the
  existing process-lifetime cache, so no extra channel round-trip per screen visit). Calls a
  new `PrintService.printReceiptBuiltIn()`.
- **"Print (Bluetooth)"** — visible only when a printer is currently saved
  (`PrintService.getSavedMac() != null`), same condition already used for the existing
  Bluetooth calibration buttons in `PrinterSetupScreen`. Calls a new
  `PrintService.printReceiptBluetooth()`.
- If neither condition holds, the existing disabled/empty state (pointing to Printer Setup) is
  shown instead of a dead button.
- Each button has its own independent loading/disabled state, so one printing does not block
  the other from being tapped.

`PrintService` gains two thin wrappers that skip the auto-dispatch in `_printDocument()` and
call the built-in/Bluetooth paths directly:

```dart
static Future<bool> printReceiptBuiltIn(Receipt receipt, {...}) {
  final document = ReceiptPrintDocument.build(receipt, ...);
  return BuiltInPrinter.print(document);
}

static Future<bool> printReceiptBluetooth(Receipt receipt, {...}) {
  final document = ReceiptPrintDocument.build(receipt, ...);
  return _printViaBluetooth(document);
}
```

`printReceipt()` (auto-dispatch) is only ever called from `ReceiptNotifier.print()`, whose sole
caller is the single-button flow this design replaces. That call site is updated to use the two
new explicit methods instead; `printReceipt()` itself is left in place rather than deleted,
since removing an otherwise-unused method isn't required for this feature.

## Error handling

- **Permission permanently denied**: "Open App Settings" instead of a retry that would
  silently no-op.
- **Bluetooth disabled mid-scan**: discovery stream ends; on `DiscoveryFinishedEvent` with zero
  `AVAILABLE` results, re-check `isBluetoothEnabled()` and re-show the enable-prompt rather
  than a bare "no devices found" message.
- **Pairing dialog cancelled by the user**: `BondStateChangedEvent(bonded: false)` — treated as
  a failed pair, inline error on that tile, no hang (bounded by `pairAndWait`'s timeout).
- **Device gets bonded by the OS mid-scan** (e.g. paired via a system prompt outside this app):
  `BondStateChangedEvent` moves it from AVAILABLE to PAIRED rather than leaving a stale
  duplicate entry.
- **Screen disposed mid-pair**: the in-flight `pairAndWait` future is not cancelled (Android
  has no API to cancel `createBond`), but its result is discarded via a mounted/disposed check
  before calling `setState` — no post-dispose crash.
- **Print failures**: unchanged UX — each button shows the existing "Couldn't print — check
  your printer and try again" snackbar on failure, scoped to the button that was pressed.

## Performance / jank notes

- Discovery events are batched into at most one `setState` per frame, not one per
  `DeviceFoundEvent` — a busy scan environment (many nearby Bluetooth devices) must not cause a
  rebuild storm.
- All native calls (`startDiscovery`, `pairDevice`, permission requests) are async and never
  block the Flutter UI thread; per-tile (not global) loading state keeps the rest of the device
  list interactive while one device is connecting/pairing.
- Discovery is stopped promptly on screen exit and the event-channel subscription is
  cancelled — no background scanning or leaked native receivers after leaving the screen.

## Testing

- Manual verification on physical Android hardware (discovery/pairing cannot be exercised on
  an emulator without a real second Bluetooth device nearby, and `createBond`/discovery
  behavior varies by OEM):
  - Scan with Bluetooth off → prompted → turn on → scan proceeds automatically.
  - Scan with permission not yet granted → grant → scan proceeds; deny → retry prompt; deny
    permanently → "Open App Settings" path.
  - Pre-Android-12 device with Location Services off → prompted, opens location settings.
  - Scan finds an unpaired printer → tap → system pairing dialog (if the device requires a
    PIN/confirm) → success moves it to PAIRED and selects it as the active printer.
  - Cancel a pairing request → inline error on that tile only, rest of list stays usable.
  - Receipt screen: built-in button visible/hidden correctly based on hardware; Bluetooth
    button visible only after a printer is saved; each prints independently and shows its own
    failure snackbar on error.
- Unit-testable in isolation: none of the native discovery/pairing logic (platform-channel
  bound), but `PrintService.printReceiptBuiltIn`/`printReceiptBluetooth` can be covered the
  same way existing `PrintService` methods are — asserting they build the same
  `ReceiptPrintDocument` and route to the expected printer path.
