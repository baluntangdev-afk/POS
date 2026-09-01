import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/csv/report_csv_exporter.dart';
import '../../../core/services/report_email_recipients.dart';
import '../../../core/services/report_email_sender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/report_email_recipients_dialog.dart';

class _HubTile {
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final String route;
  final String historyRoute;

  const _HubTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.route,
    required this.historyRoute,
  });
}

const _kTiles = [
  _HubTile(
    label: 'X-Reading',
    description: 'Per-cashier running sales snapshot',
    icon: Icons.receipt_long_rounded,
    accent: Color(0xFF1B7A8C),
    route: '/cashier-accounting/x-reading',
    historyRoute: '/cashier-accounting/x-reading/history',
  ),
  _HubTile(
    label: 'Daily Report',
    description: 'Per-cashier VAT & cash summary',
    icon: Icons.summarize_rounded,
    accent: Color(0xFF27AE60),
    route: '/cashier-accounting/daily-report',
    historyRoute: '/cashier-accounting/daily-report/history',
  ),
  _HubTile(
    label: 'Z-Reading',
    description: 'Store-wide end-of-day closing',
    icon: Icons.point_of_sale_rounded,
    accent: Color(0xFF8E44AD),
    route: '/cashier-accounting/z-reading',
    historyRoute: '/cashier-accounting/z-reading/history',
  ),
];

class CashierAccountingHubScreen extends StatelessWidget {
  const CashierAccountingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Cashier Accounting'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: const [_ExportPopupButton()],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _kTiles.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.md),
          itemBuilder: (context, i) => _HubCard(tile: _kTiles[i]),
        ),
      ),
    );
  }
}

class _ExportPopupButton extends HookConsumerWidget {
  const _ExportPopupButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExporting = useState(false);

    Future<DateTimeRange?> pickRange() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final result = await showCalendarDatePicker2Dialog(
        context: context,
        dialogSize: const Size(325, 400),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        dialogBackgroundColor: AppColors.surface,
        value: [DateTime(now.year, now.month, 1), today],
        config: CalendarDatePicker2WithActionButtonsConfig(
          calendarType: CalendarDatePicker2Type.range,
          firstDate: DateTime(2020),
          lastDate: today,
          currentDate: today,
          selectedDayHighlightColor: AppColors.primary,
          selectedRangeHighlightColor:
              AppColors.primary.withValues(alpha: 0.12),
          dayTextStyle:
              AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
          selectedDayTextStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
          ),
          todayTextStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          disabledDayTextStyle:
              AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
          weekdayLabelTextStyle:
              AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
          controlsTextStyle: AppTextStyles.labelLg.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          okButtonTextStyle: AppTextStyles.labelLg.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          cancelButtonTextStyle:
              AppTextStyles.labelLg.copyWith(color: AppColors.textSecondary),
        ),
      );

      if (result == null || result.isEmpty || result.first == null) return null;
      final start = result.first!;
      final end =
          result.length > 1 && result[1] != null ? result[1]! : start;
      return DateTimeRange(start: start, end: end);
    }

    Future<void> runDownload(DateTime from, DateTime to) async {
      isExporting.value = true;
      try {
        final exporter = ref.read(reportCsvExporterProvider);
        final filename = await exporter.exportTransactions(from: from, to: to);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Downloads/$filename')),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed — check storage space')),
          );
        }
      } finally {
        if (context.mounted) isExporting.value = false;
      }
    }

    Future<void> runEmail(DateTime from, DateTime to) async {
      final recipients = await showReportEmailRecipientsDialog(context);
      if (recipients == null || recipients.isEmpty) return;

      try {
        await ReportEmailRecipients.save(recipients);
      } on Exception {
        // non-fatal: failing to remember recipients shouldn't block emailing
      }

      isExporting.value = true;
      try {
        final exporter = ref.read(reportCsvExporterProvider);
        final file = await exporter.writeTransactionsTempFile(from: from, to: to);
        final dateFmt = DateFormat('yyyy-MM-dd');
        final label = '${dateFmt.format(from)} to ${dateFmt.format(to)}';
        await ref.read(reportEmailSenderProvider).send(
              recipients: recipients,
              subject: 'Transactions $label',
              body: 'Attached: all transactions from $label.',
              attachment: file,
            );
        if (context.mounted) {
          final n = recipients.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent to $n recipient${n == 1 ? '' : 's'}'),
            ),
          );
        }
      } on ReportEmailException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed — check storage space')),
          );
        }
      } finally {
        if (context.mounted) isExporting.value = false;
      }
    }

    Future<void> onSelected(String value) async {
      final range = await pickRange();
      if (range == null) return;
      final from = DateTime(
          range.start.year, range.start.month, range.start.day);
      final to = DateTime(
          range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);

      switch (value) {
        case 'download':
          await runDownload(from, to);
        case 'email':
          await runEmail(from, to);
      }
    }

    if (isExporting.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Export transactions',
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 12),
              Text('Download file'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email_outlined, size: 20),
              SizedBox(width: 12),
              Text('Email'),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubCard extends HookWidget {
  final _HubTile tile;
  const _HubCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        context.push(tile.route);
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isPressed.value ? tile.accent.withValues(alpha: 0.5) : AppColors.border,
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tile.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(tile.icon, size: 28, color: tile.accent),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.label,
                    style: AppTextStyles.headingSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    tile.description,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(tile.historyRoute),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('History'),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
