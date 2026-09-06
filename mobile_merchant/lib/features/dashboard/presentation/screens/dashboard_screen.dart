import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/dashboard_toolbar.dart';

/// Landing screen. The toolbar is wired up; the body below it is intentionally
/// empty — dashboard content is a later iteration (see `features/README.md`).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: const [
            DashboardToolbar(),
            Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
