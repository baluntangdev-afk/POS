import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../merchant/domain/entities/device_registration.dart';
import '../../../merchant/domain/entities/device_startup_result.dart';
import '../../../merchant/presentation/dialogs/device_status_dialog.dart';
import '../../../merchant/presentation/dialogs/merchant_form_dialog.dart';
import '../../../merchant/state/merchant_notifier.dart';
import '../../../orders/presentation/widgets/orders_body.dart';
import '../../../orders/state/orders_feed_notifier.dart';
import '../widgets/dashboard_toolbar.dart';

/// Cadence of the dashboard's device-approval poll while the device is still
/// pending. Each tick is an idempotent `POST /devices/register` replay, so the
/// live feed connects on its own within one interval of the merchant admin
/// granting approval — no restart, no manual "Check status" tap.
const _approvalPollInterval = Duration(seconds: 15);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  bool _startupHandled = false;
  bool _startupComplete = false;
  bool _recheckInFlight = false;
  bool _statusDialogVisible = false;
  Timer? _approvalPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMerchant();
      // Boot the WebSocket feed (kept alive via ref.keepAlive in the notifier).
      ref.read(ordersFeedNotifierProvider);
    });
  }

  @override
  void dispose() {
    _stopApprovalPoll();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-probe device approval whenever the app returns to the foreground while
  /// still waiting on it — the merchant admin approves from elsewhere, so a
  /// warm resume is the moment the status is most likely to have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Nothing to gain from polling a suspended app; the resume branch and the
      // deviceStartupProvider listener restart it.
      _stopApprovalPoll();
      return;
    }
    unawaited(_recheckDeviceStatus());
    if (_shouldPollForApproval) _startApprovalPoll();
  }

  /// True while the device has a resolved, non-approved enrollment that a
  /// merchant-admin approval could still flip. Still-loading (`null`) and
  /// `tokenUnavailable` (a separate failure with its own surfaced error) don't
  /// qualify.
  bool get _shouldPollForApproval {
    final result = ref.read(deviceStartupProvider).value;
    return result != null && !result.isApproved && !result.tokenUnavailable;
  }

  void _startApprovalPoll() {
    if (_approvalPoll != null) return;
    _approvalPoll = Timer.periodic(
      _approvalPollInterval,
      (_) => unawaited(_recheckDeviceStatus()),
    );
  }

  void _stopApprovalPoll() {
    _approvalPoll?.cancel();
    _approvalPoll = null;
  }

  Future<void> _recheckDeviceStatus() async {
    // Wait for the cold-start flow to run its own probe first — otherwise a
    // `resumed` event fired right after launch races `_checkMerchant`.
    if (!mounted || !_startupComplete || _recheckInFlight) return;
    if (ref.read(merchantProvider).value == null) return;
    // Nothing to gain once the device is approved.
    if (ref.read(deviceStartupProvider).value?.isApproved ?? false) return;

    _recheckInFlight = true;
    try {
      final result =
          await ref.read(merchantProvider.notifier).recheckDeviceStatus();
      if (!mounted) return;
      await _handleDeviceStatus(
        result.status,
        result.justApproved,
        result.reviewNote,
      );
      if (!mounted) return;
      unawaited(
        ref.read(ordersFeedNotifierProvider.notifier).checkConnection(),
      );
    } catch (_) {
      // Best-effort — the existing error paths surface a real failure.
    } finally {
      _recheckInFlight = false;
    }
  }

  Future<void> _checkMerchant() async {
    if (!mounted || _startupHandled) return;
    _startupHandled = true;
    try {
      await _runStartupCheck();
    } finally {
      _startupComplete = true;
    }
  }

  Future<void> _runStartupCheck() async {
    final merchant = await ref.read(merchantProvider.future);
    if (!mounted) return;

    if (merchant != null) {
      final result = await ref.read(deviceStartupProvider.future);
      if (!mounted) return;
      await _handleDeviceStatus(
        result.status,
        result.justApproved,
        result.reviewNote,
      );
      if (!mounted) return;
      unawaited(
        ref.read(ordersFeedNotifierProvider.notifier).checkConnection(),
      );
      return;
    }

    DeviceRegistration? registration;
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MerchantFormDialog(
        isRegistration: true,
        onSubmit: (id, name) async {
          registration = await ref
              .read(merchantProvider.notifier)
              .register(merchantId: id, merchantName: name);
        },
      ),
    );
    if (!mounted || submitted != true || registration == null) return;
    await _handleDeviceStatus(
      registration!.status,
      false,
      registration!.reviewNote,
    );
    // A fresh enrolment lands as `pending`; `register()` doesn't refresh
    // deviceStartupProvider, so the build() listener won't see the change —
    // kick the poll off here. The first tick refreshes the provider and the
    // listener takes over from there.
    if (mounted && registration!.status != DeviceStatus.approved) {
      _startApprovalPoll();
    }
  }

  /// Toast on a fresh approval, dismissible dialog for every other state,
  /// silence when token minting failed (`status == null`) or the device is
  /// already approved. If the merchant taps "Check again" in the dialog, the
  /// fresh result is folded back in — a snackbar on approval, or the dialog
  /// again while still pending.
  Future<void> _handleDeviceStatus(
    String? status,
    bool justApproved,
    String? reviewNote,
  ) async {
    if (!mounted || status == null) return;

    if (status == DeviceStatus.approved) {
      _stopApprovalPoll();
      // A poll tick (or the resume probe) may land approval while the
      // "waiting for approval" dialog is still on screen — close it so the
      // merchant just sees the dashboard connect.
      if (_statusDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (justApproved) {
        AppSnackbar.success(context, 'Device approved — you\'re all set.');
      }
      return;
    }

    // The 15s poll routes back through here on every pending tick; don't stack
    // a second dialog on top of the one already showing.
    if (_statusDialogVisible) return;

    _statusDialogVisible = true;
    final DeviceStartupResult? rechecked;
    try {
      rechecked = await DeviceStatusDialog.show(
        context,
        status: status,
        merchantName: ref.read(merchantProvider).value?.merchantName,
        reviewNote: reviewNote,
      );
    } finally {
      _statusDialogVisible = false;
    }
    if (!mounted || rechecked == null) return;
    await _handleDeviceStatus(
      rechecked.status,
      rechecked.justApproved,
      rechecked.reviewNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Start/stop the approval poll as the device's enrollment status resolves
    // and changes. Fires on the initial load→data transition too, so the
    // common "already registered, still pending" launch is covered without an
    // explicit kick-off.
    ref.listen(deviceStartupProvider, (_, next) {
      final result = next.value;
      if (result == null) return;
      if (result.isApproved || result.tokenUnavailable) {
        _stopApprovalPoll();
      } else {
        _startApprovalPoll();
      }
    });

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
