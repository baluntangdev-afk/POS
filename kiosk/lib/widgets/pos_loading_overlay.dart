import 'package:flutter/material.dart';

import '../styles/color_set.dart';
import '../theme/pos_design.dart';

Future<void> showPOSLoadingDialog(BuildContext context, {String? message}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => POSLoadingDialog(message: message),
  );
}

class POSLoadingDialog extends StatelessWidget {
  const POSLoadingDialog({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorSet.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorSet.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: POSColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class POSLoadingIndicator extends StatelessWidget {
  const POSLoadingIndicator({super.key, this.size = 48, this.color = ColorSet.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.2),
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
