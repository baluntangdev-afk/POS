# Automatic transaction CSV email — design

**Date:** 2026-09-01
**Status:** Approved
**Area:** `mobile/` — cashier accounting / CSV export

## Problem

The "Email transactions CSV" action currently calls `FlutterEmailSender.send()`, which
opens the device's email app with a pre-filled draft. The operator still has to tap
"Send" inside that app, and a kiosk device may not have an email app configured at all.

We want the CSV to be sent automatically — no email app, no draft, no backend server —
when the operator taps **Send** in the recipients dialog.

## Constraints

- **No backend.** Sending happens entirely from the Flutter app.
- **Mobile only.** No changes to `be/`. Verification via `dart analyze`.
- Sender account is fixed: `dposoftware130@gmail.com`.
- Sender credentials are baked into the build via `.env` (no in-app settings screen).
- Recipients are entered at send time; that UX does not change.

## Approach

Send mail directly over SMTP to `smtp.gmail.com` using the `mailer` package
(pure Dart, `^7.2.0`). Gmail requires an **App Password** (16 chars, 2FA must be on
for the sender account) — the normal account password will not authenticate.

Rejected alternatives:
- **Gmail API + OAuth** — needs an OAuth consent flow / service account; heavy.
- **Transactional email API (Resend, SendGrid, …)** — another third-party account +
  API key, and Gmail-as-sender needs domain verification. No benefit here.

## Components

### 1. Config — `lib/config/environment/`

Add two fields, following the existing `csvExportPassword` pattern:

- `AppEnv`: `String get senderEmail;` and `String get senderAppPassword;`
- `Env`:
  - `@EnviedField()` `senderEmail`
  - `@EnviedField(obfuscate: true)` `senderAppPassword`
- `.env.sample`: `SENDER_EMAIL=` and `SENDER_APP_PASSWORD=` with a comment noting the
  Gmail App Password requirement.
- `.env`: real values (`SENDER_EMAIL=dposoftware130@gmail.com`, `SENDER_APP_PASSWORD=<app password>`).
- Run `build_runner` to regenerate `env.g.dart`.

### 2. New service — `lib/core/services/report_email_sender.dart`

```dart
class ReportEmailSender {
  ReportEmailSender({required String senderEmail, required String senderAppPassword});

  Future<void> send({
    required List<String> recipients,
    required String subject,
    required String body,
    required File attachment,
  });
}

class ReportEmailException implements Exception { ... }
```

- Builds `gmail(senderEmail, senderAppPassword)`.
- Constructs `Message()` with `from = Address(senderEmail, 'DPO Software')`,
  `recipients`, `subject`, `text = body`, `attachments = [FileAttachment(attachment)]`.
- `await send(message, server, timeout: Duration(seconds: 20))`.
- Catches `MailerException`, `SocketException`, `TimeoutException` → throws
  `ReportEmailException` (keeps the original for logging).
- Provider `reportEmailSenderProvider` reads `appEnvProvider` for the two values.

### 3. Wire-in — `cashier_accounting_hub_screen.dart` `runEmail`

- Keep: recipients dialog, `ReportEmailRecipients.save`, `writeTransactionsTempFile`,
  the subject (`Transactions <label>`) and body strings, the `isExporting` spinner.
- Replace the `FlutterEmailSender.send(...)` call with
  `await ref.read(reportEmailSenderProvider).send(...)`.
- On success: snackbar `Sent to N recipient(s)`.
- On `ReportEmailException` / any error: snackbar
  `Couldn't send email — check the connection and try again.`
- No retry, no fallback — the separate **Download** action covers that need.
- Remove the `flutter_email_sender`-specific `PlatformException` handling.

### 4. Cleanup

- `pubspec.yaml`: remove `flutter_email_sender`, add `mailer: ^7.2.0`.
- Remove `import 'package:flutter_email_sender/...'` from the hub screen.
- Remove the `SENDTO` / `mailto` `<intent>` from `AndroidManifest.xml` `<queries>`
  (added only for `flutter_email_sender`; nothing else references `mailto`).
- `flutter pub get`.

### 5. Unchanged

`showReportEmailRecipientsDialog`, `ReportEmailRecipients` persistence.

## Data flow

```
Hub screen (Email action)
  → showReportEmailRecipientsDialog        (unchanged)
  → ReportEmailRecipients.save             (unchanged)
  → ReportCsvExporter.writeTransactionsTempFile → temp .csv File
  → ReportEmailSender.send(recipients, subject, body, attachment)
      → mailer: gmail(senderEmail, appPassword)
      → SMTP smtp.gmail.com:587 (STARTTLS)
  → snackbar (success / failure)
```

## Error handling

| Failure | Behaviour |
|---|---|
| No network / DNS / timeout | `ReportEmailException` → failure snackbar |
| Gmail auth rejected (bad app password) | `MailerException` → failure snackbar |
| Recipient rejected by server | `MailerException` → failure snackbar |
| Temp-file write fails | existing `Exception` branch → existing storage snackbar |

The operator can fall back to **Download** and send the file another way.

## Testing

`dart analyze` only. No new test files (standing preference for `mobile/` tasks).
Manual: trigger Email with a real recipient, confirm delivery and attachment.

## Security note

The App Password is embedded (obfuscated) in the APK. Acceptable for a locked-down
kiosk given the "no backend" constraint. Rotating it requires a rebuild + redeploy.
