import 'package:flutter/material.dart';

import '../../../widgets/supervisor_authorization_dialog.dart';

/// Refund-specific wrapper over the shared [SupervisorAuthorizationDialog].
class RefundAuthorizationDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await SupervisorAuthorizationDialog.show(
      context,
      title: 'Authorization Required',
      warningMessage:
          'Refunds require admin or supervisor authorization. Enter your credentials to proceed.',
      ctaLabel: 'Authorize Refund',
      ctaIcon: Icons.assignment_return_rounded,
    );
    return result != null;
  }
}
