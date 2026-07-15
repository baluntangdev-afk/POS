import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/paginated_data.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier_daily_report.dart';
import '../entities/cashier_x_reading.dart';
import '../entities/z_reading.dart';
import '../state/cashier_report_history_notifier.dart';
import 'report_preview_widgets.dart';

const int _historyPageLimit = 10;

class CashierReportsScreen extends StatelessWidget {
  const CashierReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TopAppBar(title: 'Reports'),
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: ColorSet.primary,
              unselectedLabelColor: POSColors.textTertiary,
              indicatorColor: ColorSet.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.w700),
              tabs: [Tab(text: 'X-Reading'), Tab(text: 'Cashier Daily Report'), Tab(text: 'Z-Reading')],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [_XReadingHistoryTab(), _DailyReportHistoryTab(), _ZReadingHistoryTab()],
            ),
          ),
        ],
      ),
    );

    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _XReadingHistoryTab extends HookConsumerWidget {
  const _XReadingHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(cashierXReadingHistoryNotifierProvider.notifier)
            .getResults(page: page.value, limit: _historyPageLimit);
      });
      return null;
    }, [page.value]);

    final asyncState = ref.watch(cashierXReadingHistoryNotifierProvider);

    return _HistoryTabBody<CashierXReadingHistoryItem>(
      asyncState: asyncState,
      page: page,
      emptyMessage: 'No closed X-Readings yet',
      onRetry:
          () => ref
              .read(cashierXReadingHistoryNotifierProvider.notifier)
              .getResults(page: page.value, limit: _historyPageLimit),
      itemBuilder:
          (item) => _HistoryRow(
            period: formatReportPeriod(item.periodStart, item.periodEnd),
            generatedAt: item.generatedAt,
            amount: item.totalSales,
            transactionCount: item.completedTransactions,
            onTap: () => CashierReportHistoryDetailRoute(item.id).push<void>(context),
          ),
    );
  }
}

class _DailyReportHistoryTab extends HookConsumerWidget {
  const _DailyReportHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(cashierDailyReportHistoryNotifierProvider.notifier)
            .getResults(page: page.value, limit: _historyPageLimit);
      });
      return null;
    }, [page.value]);

    final asyncState = ref.watch(cashierDailyReportHistoryNotifierProvider);

    return _HistoryTabBody<CashierDailyReportHistoryItem>(
      asyncState: asyncState,
      page: page,
      emptyMessage: 'No closed daily reports yet',
      onRetry:
          () => ref
              .read(cashierDailyReportHistoryNotifierProvider.notifier)
              .getResults(page: page.value, limit: _historyPageLimit),
      itemBuilder:
          (item) => _HistoryRow(
            period: formatReportPeriod(item.periodStart, item.periodEnd),
            generatedAt: item.generatedAt,
            amount: item.grossSales,
            transactionCount: item.transactionCount,
            onTap: () => CashierDailyReportHistoryDetailRoute(item.id).push<void>(context),
          ),
    );
  }
}

class _ZReadingHistoryTab extends HookConsumerWidget {
  const _ZReadingHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(zReadingHistoryNotifierProvider.notifier)
            .getResults(page: page.value, limit: _historyPageLimit);
      });
      return null;
    }, [page.value]);

    final asyncState = ref.watch(zReadingHistoryNotifierProvider);

    return _HistoryTabBody<ZReadingHistoryItem>(
      asyncState: asyncState,
      page: page,
      emptyMessage: 'No closed Z-Readings yet',
      onRetry:
          () => ref
              .read(zReadingHistoryNotifierProvider.notifier)
              .getResults(page: page.value, limit: _historyPageLimit),
      itemBuilder:
          (item) => _HistoryRow(
            period: formatReportPeriod(item.periodStart, item.periodEnd),
            generatedAt: item.generatedAt,
            amount: item.totalSales,
            transactionCount: item.completedTransactions,
            onTap: () => ZReadingHistoryDetailRoute(item.id).push<void>(context),
          ),
    );
  }
}

class _HistoryTabBody<T> extends StatelessWidget {
  const _HistoryTabBody({
    required this.asyncState,
    required this.page,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onRetry,
  });

  final AsyncValue<PaginatedData<T>> asyncState;
  final ValueNotifier<int> page;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Padding(
      padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ColorSet.primary)),
        error: (error, _) => ReportErrorView(message: '$error', onRetry: onRetry),
        data: (paginated) {
          if (paginated.data.isEmpty) {
            return Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(fontSize: 14, color: POSColors.textTertiary),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: paginated.data.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => itemBuilder(paginated.data[index]),
                ),
              ),
              const SizedBox(height: 12),
              _HistoryPaginationRow(page: page, totalPages: paginated.totalPages),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.period,
    required this.generatedAt,
    required this.amount,
    required this.transactionCount,
    required this.onTap,
  });

  final String period;
  final DateTime generatedAt;
  final double amount;
  final int transactionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final decimalAmount = Decimal.parse(amount.toStringAsFixed(2));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(POSRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(POSRadius.lg),
        child: Container(
          padding: EdgeInsets.all(r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(POSRadius.lg),
            border: Border.all(color: POSColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w600,
                        color: POSColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Closed ${DateFormat.yMd().add_jm().format(generatedAt.toLocal())}',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                        color: POSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    decimalAmount.pesoFormatted,
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      fontWeight: FontWeight.w700,
                      color: ColorSet.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$transactionCount txns',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                      color: POSColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: POSColors.iconSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPaginationRow extends StatelessWidget {
  const _HistoryPaginationRow({required this.page, required this.totalPages});

  final ValueNotifier<int> page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: page.value > 1 ? () => page.value-- : null,
          child: const Icon(Icons.chevron_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Page ${totalPages > 0 ? page.value : 0} of $totalPages',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: page.value < totalPages ? () => page.value++ : null,
          child: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
