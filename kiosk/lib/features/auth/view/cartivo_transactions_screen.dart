import 'package:flutter/material.dart';

import '../../../theme/pos_design.dart';
import '../../../widgets/cartivo_app_bar.dart';

class CartivoTransactionsScreen extends StatelessWidget {
  const CartivoTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: POSColors.surfaceSubtle,
      appBar: const CartivoAppBar(),
      body: const Center(
        child: Text(
          'Coming soon',
          style: TextStyle(
            color: POSColors.textTertiary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
