import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../merchant/presentation/dialogs/merchant_form_dialog.dart';
import '../../../merchant/state/merchant_notifier.dart';
import '../../../orders/presentation/widgets/orders_body.dart';
import '../../../orders/state/orders_feed_notifier.dart';
import '../widgets/dashboard_toolbar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _registrationShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMerchant();
      // Boot the WebSocket feed (kept alive via ref.keepAlive in the notifier).
      ref.read(ordersFeedNotifierProvider);
    });
  }

  Future<void> _checkMerchant() async {
    if (!mounted) return;
    final merchant = await ref.read(merchantProvider.future);
    if (!mounted || _registrationShown) return;
    if (merchant != null) {
      unawaited(ref.read(merchantProvider.notifier).refreshToken());
      unawaited(ref.read(ordersFeedNotifierProvider.notifier).checkConnection());
    }
    if (merchant == null) {
      _registrationShown = true;
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MerchantFormDialog(
          isRegistration: true,
          onSubmit: (id, name) => ref
              .read(merchantProvider.notifier)
              .register(merchantId: id, merchantName: name),
        ),
      );
      if (mounted) {
        AppSnackbar.success(
          context,
          'Device registered successfully! You\'re all set.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: const [
            DashboardToolbar(),
            Expanded(child: OrdersBody()),
          ],
        ),
      ),
    );
  }
}
