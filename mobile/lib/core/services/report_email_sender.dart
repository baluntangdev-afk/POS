import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';

import '../../config/environment/app_env.dart';

final reportEmailSenderProvider = Provider<ReportEmailSender>((ref) {
  final env = ref.watch(appEnvProvider);
  return ReportEmailSender(
    senderEmail: env.senderEmail,
    senderAppPassword: env.senderAppPassword,
  );
});

/// Thrown when the report email could not be delivered. The original error is
/// kept in [cause] for logging; [message] is safe to show to the operator.
class ReportEmailException implements Exception {
  ReportEmailException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'ReportEmailException: $message';
}

/// Sends a report CSV as an email attachment straight over Gmail SMTP — no email
/// app, no backend. The sender account is fixed at build time via `.env`
/// ([AppEnv.senderEmail] / [AppEnv.senderAppPassword]); the app password must be
/// a Gmail App Password, not the normal account password.
class ReportEmailSender {
  ReportEmailSender({
    required String senderEmail,
    required String senderAppPassword,
  })  : _senderEmail = senderEmail,
        _senderAppPassword = senderAppPassword;

  final String _senderEmail;
  final String _senderAppPassword;

  static const _timeout = Duration(seconds: 20);

  Future<void> send({
    required List<String> recipients,
    required String subject,
    required String body,
    required File attachment,
  }) async {
    if (_senderEmail.isEmpty || _senderAppPassword.isEmpty) {
      throw ReportEmailException('Email sender is not configured on this build.');
    }

    final server = gmail(_senderEmail, _senderAppPassword);
    final message = mailer.Message()
      ..from = mailer.Address(_senderEmail, 'DPO Software')
      ..recipients.addAll(recipients)
      ..subject = subject
      ..text = body
      ..attachments.add(mailer.FileAttachment(attachment));

    try {
      await mailer.send(message, server, timeout: _timeout);
    } on mailer.MailerException catch (e) {
      throw ReportEmailException(
        'Could not send email — check the connection and try again.',
        e,
      );
    } on SocketException catch (e) {
      throw ReportEmailException(
        'Could not send email — check the connection and try again.',
        e,
      );
    } on TimeoutException catch (e) {
      throw ReportEmailException(
        'Could not send email — the request timed out.',
        e,
      );
    }
  }
}
