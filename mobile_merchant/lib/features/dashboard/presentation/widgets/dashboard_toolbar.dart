import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../merchant/domain/entities/device_startup_result.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../merchant/presentation/dialogs/device_status_dialog.dart';
import '../../../merchant/presentation/dialogs/merchant_form_dialog.dart';
import '../../../merchant/state/merchant_notifier.dart';
import 'connection_status_indicator.dart';

class DashboardToolbar extends ConsumerWidget {
  const DashboardToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantAsync = ref.watch(merchantProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: w > 600 ? 28 : 16),
          child: Row(
            children: [
              Expanded(
                child: _Brand(merchant: merchantAsync.value),
              ),
              const SizedBox(width: 12),
              const _DeviceStatusButton(),
              ConnectionStatusIndicator(showLabel: w > 600),
              const SizedBox(width: 12),
              Container(width: 1, height: 28, color: AppColors.border),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () async {
                  final current = merchantAsync.value;
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => MerchantFormDialog(
                      isRegistration: false,
                      initialMerchantId: current?.merchantId,
                      initialMerchantName: current?.merchantName,
                      onSubmit: (id, name) => ref
                          .read(merchantProvider.notifier)
                          .save(merchantId: id, merchantName: name),
                    ),
                  );
                  if ((saved ?? false) && context.mounted) {
                    AppSnackbar.success(context, 'Merchant settings saved.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown only while the device is enrolled but not approved (`pending` /
/// `deactivated`). Tapping re-opens [DeviceStatusDialog], whose "Check again"
/// re-runs the approval probe — the merchant's only way back to that check
/// once the startup dialog has been dismissed, short of restarting the app.
class _DeviceStatusButton extends ConsumerWidget {
  const _DeviceStatusButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(deviceStartupProvider).value;
    if (startup == null || startup.status == null || startup.isApproved) {
      return const SizedBox.shrink();
    }

    final status = startup.status;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: status == DeviceStatus.deactivated
            ? 'Device deactivated — tap for details'
            : 'Waiting for approval — tap to re-check',
        icon: Icon(
          status == DeviceStatus.deactivated
              ? Icons.block_rounded
              : Icons.hourglass_top_rounded,
          color: AppColors.warning,
          size: 22,
        ),
        onPressed: () async {
          final result = await DeviceStatusDialog.show(
            context,
            status: status,
            merchantName: ref.read(merchantProvider).value?.merchantName,
            reviewNote: startup.reviewNote,
          );
          if (result != null && result.isApproved && context.mounted) {
            AppSnackbar.success(context, 'Device approved — you\'re all set.');
          }
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.merchant});

  final Merchant? merchant;

  @override
  Widget build(BuildContext context) {
    final hasMerchant = merchant != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.shopping_cart_rounded,
            color: AppColors.textOnPrimary,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Carti',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'vo',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMerchant)
                Text(
                  '${merchant!.merchantName} | ${merchant!.merchantId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live clock. Ticks every 30s — matches the source app; the minute display
/// never drifts more than 30s and there's no seconds field to keep smooth.
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final min = _now.minute.toString().padLeft(2, '0');
    final period = _now.hour < 12 ? 'AM' : 'PM';
    final dayStr = _days[_now.weekday - 1];
    final monStr = _months[_now.month - 1];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$hour:$min $period',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        Text(
          '$dayStr, $monStr ${_now.day}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
