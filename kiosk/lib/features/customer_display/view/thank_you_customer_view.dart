import 'package:flutter/material.dart';

import '../../../theme/pos_design.dart';
import '../entities/customer_display_snapshot.dart';

class ThankYouCustomerView extends StatelessWidget {
  const ThankYouCustomerView({super.key, required this.snapshot});

  final CustomerDisplayThankYou snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: POSGradient.primary),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 96),
            const SizedBox(height: POSSpacing.lg),
            const Text(
              'THANK YOU!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: POSSpacing.sm),
            const Text(
              'Your order has been completed.',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: POSSpacing.md),
            Text(
              'Order #${snapshot.docNumber}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
