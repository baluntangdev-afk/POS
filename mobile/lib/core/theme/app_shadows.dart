import 'package:flutter/material.dart';

/// Shared elevation tokens, mirrored from the kiosk app's `POSShadow`
/// (kiosk/lib/theme/pos_design.dart) so both apps read as one product.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
