import 'package:flutter/material.dart';

import '../../../styles/fallback_theme.dart';
import 'customer_display_page.dart';

class CustomerDisplayApp extends StatelessWidget {
  const CustomerDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: fallbackTheme,
      home: const CustomerDisplayPage(),
    );
  }
}
