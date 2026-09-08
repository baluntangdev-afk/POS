import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/device_startup_result.dart';
import '../../state/merchant_notifier.dart';
import '../device_status_visual.dart';

/// Dismissible, informational dialog shown on startup when the device is not
/// (yet) approved. The merchant can't self-approve, but "Check again" re-runs
/// the approval probe without a full restart.
///
/// Copy + iconography come from the shared [DeviceStatusVisual] so this dialog
/// and the persistent [DeviceRegistrationStatusCard] stay aligned with
/// `mobile/`.
///
/// [show] resolves to the [DeviceStartupResult] from a "Check again" tap, or
/// `null` when the merchant just acknowledged and closed.
class DeviceStatusDialog extends ConsumerStatefulWidget {
  const DeviceStatusDialog({
    required this.status,
    this.merchantName,
    this.reviewNote,
    super.key,
  });

  final String? status;
  final String? merchantName;
  final String? reviewNote;

  static Future<DeviceStartupResult?> show(
    BuildContext context, {
    required String? status,
    String? merchantName,
    String? reviewNote,
  }) =>
      showDialog<DeviceStartupResult>(
        context: context,
        barrierDismissible: true,
        builder: (_) => DeviceStatusDialog(
          status: status,
          merchantName: merchantName,
          reviewNote: reviewNote,
        ),
      );

  @override
  ConsumerState<DeviceStatusDialog> createState() => _DeviceStatusDialogState();
}

class _DeviceStatusDialogState extends ConsumerState<DeviceStatusDialog> {
  bool _checking = false;

  Future<void> _checkAgain() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result =
          await ref.read(merchantProvider.notifier).recheckDeviceStatus();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = DeviceStatusVisual.of(widget.status, widget.merchantName);
    final note = widget.reviewNote?.trim() ?? '';

    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: visual.color.withAlpha(28),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(visual.icon, color: visual.color, size: 20),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              visual.dialogTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visual.body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (note.isNotEmpty) ...[
              const Gap(AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(88, 44),
          ),
          child: Text(visual.primaryButtonText),
        ),
        FilledButton(
          onPressed: _checking ? null : _checkAgain,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(120, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : const Text('Check again'),
        ),
      ],
    );
  }
}
