import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared gradient tokens, mirrored from the kiosk app's `POSGradient`
/// (kiosk/lib/theme/pos_design.dart) so both apps read as one product.
abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
