import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/debounce.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/receipt.dart';
import '../state/receipt_notifier.dart';
import '../state/transactions_notifier.dart';

class TransactionsScreen extends HookConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);
    final limit = useState(10);
    final soNumber = useState<String?>(null);
    final soDate = useState<DateTime?>(null);
    final sort = useState<String?>(null);

    final totalPages = ref.watch(transactionsProvider.select((it) => it.value?.totalPages ?? 1));

    useEffect(() {
      page.value = 1;
      return null;
    }, [limit.value, soNumber.value, soDate.value]);

    useEffect(() {
      Future.microtask(() {
        ref.read(transactionsProvider.notifier).getResults(
          page: page.value,
          limit: limit.value,
          soNumber: soNumber.value,
          soDate: soDate.value,
          sort: sort.value,
        );
      });
      return null;
    }, [page.value, limit.value, soNumber.value, soDate.value, sort.value]);

    final isAndroid = context.breakpoint.isAndroid;
    final isPhone = context.breakpoint.isPhone;
    final r = context.responsive;

    final body = SizedBox.expand(
      child: Column(
        children: [
          const TopAppBar(title: 'Transactions'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(r.value<double>(kiosk: 28, tablet: 20, phone: 14)),
              child: Column(
                spacing: r.value<double>(kiosk: 14, tablet: 12, phone: 8),
                children: [
                  _PaginationControls(
                    page: page,
                    limit: limit,
                    totalPages: totalPages,
                    soNumber: soNumber,
                    soDate: soDate,
                  ),
                  Expanded(
                    child: isAndroid
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final useTable = constraints.maxWidth >= 800;
                              return useTable
                                  ? _TransactionsTable(sort: sort)
                                  : _TransactionsMobileList(sort: sort);
                            },
                          )
                        : isPhone
                            ? _TransactionsMobileList(sort: sort)
                            : _TransactionsTable(sort: sort),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

// ── Pagination + filter controls ──────────────────────────────────────────────
class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.soNumber,
    required this.soDate,
  });

  final ValueNotifier<int> page;
  final ValueNotifier<int> limit;
  final int totalPages;
  final ValueNotifier<String?> soNumber;
  final ValueNotifier<DateTime?> soDate;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isPhone = context.breakpoint.isPhone;

    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        spacing: r.value<double>(kiosk: 12, tablet: 10, phone: 8),
        children: [
          if (isPhone) ...[
            _SearchField(soNumber: soNumber),
            _DateFilterField(soDate: soDate),
          ] else
            Row(
              spacing: r.value<double>(kiosk: 12, tablet: 10, phone: 8),
              children: [
                Expanded(child: _SearchField(soNumber: soNumber)),
                Expanded(child: _DateFilterField(soDate: soDate)),
              ],
            ),
          _PaginationRow(page: page, limit: limit, totalPages: totalPages),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.soNumber});

  final ValueNotifier<String?> soNumber;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final debounce = useDebounce(const Duration(milliseconds: 300));
        return TextBoxFormField.singleLine(
          hint: 'Search invoice number...',
          prefixIcon: Icon(
            Icons.search_rounded,
            size: context.responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
            color: POSColors.iconSubtle,
          ),
          style: TextStyle(
            fontSize: context.responsive.value<double>(kiosk: 14, tablet: 14, phone: 13),
          ),
          onChanged: (value) {
            debounce(() {
              soNumber.value = value;
            });
          },
        );
      },
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({required this.soDate});

  final ValueNotifier<DateTime?> soDate;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        return TextBoxFormField.readOnly(
          controller: TextEditingController()
            ..text = soDate.value != null
                ? DateFormat('MM/dd/yyyy').format(soDate.value!.toLocal())
                : 'Filter by date...',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: soDate.value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            soDate.value = picked;
          },
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            size: context.responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
            color: POSColors.iconSubtle,
          ),
          style: TextStyle(
            fontSize: context.responsive.value<double>(kiosk: 14, tablet: 14, phone: 13),
          ),
        );
      },
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({required this.page, required this.limit, required this.totalPages});

  final ValueNotifier<int> page;
  final ValueNotifier<int> limit;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isPhone = context.breakpoint.isPhone;
    final btnH = r.value<double>(kiosk: 44, tablet: 40, phone: 36);

    return Row(
      children: [
        // Previous
        SizedBox(
          height: btnH,
          child: OutlinedButton.icon(
            onPressed: page.value > 1 ? () => page.value-- : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: isPhone ? const SizedBox.shrink() : const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorSet.primary,
              side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Page ${totalPages > 0 ? page.value : 0} of $totalPages',
          style: TextStyle(
            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
          ),
        ),
        const Spacer(),
        // Rows dropdown
        Container(
          height: btnH,
          padding: EdgeInsets.symmetric(
            horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: POSColors.borderDefault),
            borderRadius: BorderRadius.circular(POSRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: limit.value,
              isDense: true,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                color: POSColors.textPrimary,
              ),
              items: [10, 25, 50, 100].map((rows) {
                return DropdownMenuItem(value: rows, child: Text('$rows rows'));
              }).toList(),
              onChanged: (value) {
                if (value != null) limit.value = value;
              },
            ),
          ),
        ),
        SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
        // Next
        SizedBox(
          height: btnH,
          child: OutlinedButton.icon(
            onPressed: page.value < totalPages ? () => page.value++ : null,
            icon: isPhone ? const SizedBox.shrink() : const Text('Next'),
            label: const Icon(Icons.chevron_right_rounded),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorSet.primary,
              side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Desktop / Tablet Table ────────────────────────────────────────────────────
class _TransactionsTable extends ConsumerWidget {
  const _TransactionsTable({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final asyncState = ref.watch(transactionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value<double>(kiosk: 20, tablet: 16, phone: 12),
              vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: ColorSet.gradientBg,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: _SortableHeader(
                    title: 'Invoice #',
                    sortField: 'soNumber',
                    currentSort: sort,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _SortableHeader(
                    title: 'Date',
                    sortField: 'soDate',
                    currentSort: sort,
                  ),
                ),
                const Expanded(flex: 2, child: _TableHeader(title: 'Time')),
                Expanded(
                  flex: 2,
                  child: _SortableHeader(
                    title: 'Total',
                    sortField: 'finalTotalAmount',
                    currentSort: sort,
                  ),
                ),
                const Expanded(flex: 3, child: _TableHeader(title: 'Actions')),
              ],
            ),
          ),
          Expanded(
            child: asyncState.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: ColorSet.primary,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading transactions...',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                        color: POSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ColorSet.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: ColorSet.danger,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load transactions',
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                          fontWeight: FontWeight.w600,
                          color: POSColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                          color: POSColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                if (data.data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: POSColors.surfaceSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: POSColors.iconSubtle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: POSColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your filters',
                          style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: data.data.length,
                  itemBuilder: (context, index) {
                    return _TransactionRow(receipt: data.data[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: context.responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.title,
    required this.sortField,
    required this.currentSort,
  });

  final String title;
  final String sortField;
  final ValueNotifier<String?> currentSort;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isAsc = currentSort.value == '$sortField:asc';
    final isDesc = currentSort.value == '$sortField:desc';
    final isActive = isAsc || isDesc;

    return GestureDetector(
      onTap: () {
        if (isAsc) {
          currentSort.value = '$sortField:desc';
        } else if (isDesc) {
          currentSort.value = null;
        } else {
          currentSort.value = '$sortField:asc';
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(4),
          Icon(
            isAsc
                ? Icons.arrow_upward_rounded
                : isDesc
                    ? Icons.arrow_downward_rounded
                    : Icons.unfold_more_rounded,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
            size: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends HookWidget {
  const _TransactionRow({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isExpanded = useState(false);

    return Column(
      children: [
        Material(
          color: isExpanded.value
              ? ColorSet.primary.withValues(alpha: 0.03)
              : Colors.transparent,
          child: InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 20, tablet: 16, phone: 12),
                vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  // Expand indicator
                  Expanded(
                    child: AnimatedRotation(
                      turns: isExpanded.value ? 0.25 : 0,
                      duration: POSAnimation.normal,
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: ColorSet.primary,
                        size: r.value<double>(kiosk: 22, tablet: 18, phone: 16),
                      ),
                    ),
                  ),
                  // Invoice number
                  Expanded(
                    flex: 2,
                    child: Text(
                      receipt.docNumber,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w600,
                        color: POSColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Date
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(receipt.docDate.toLocal()),
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12),
                        color: POSColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Time
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('hh:mm a').format(receipt.docDate.toLocal()),
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12),
                        color: POSColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Total
                  Expanded(
                    flex: 2,
                    child: Text(
                      receipt.totalAmount.pesoFormatted,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w700,
                        color: ColorSet.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Actions
                  Consumer(
                    builder: (context, ref, _) {
                      return Expanded(
                        flex: 3,
                        child: ResponsiveBuilder(
                          kiosk: (context) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TableActionBtn(
                                label: 'Reprint',
                                icon: Icons.print_outlined,
                                color: ColorSet.primary,
                                onTap: () => ReceiptRoute(receipt.id).push<void>(context),
                              ),
                              const SizedBox(width: 8),
                              _TableActionBtn(
                                label: 'Refund',
                                icon: Icons.assignment_return_outlined,
                                color: ColorSet.warning,
                                onTap: () async {
                                  await RefundRoute(receipt.id).push<void>(context);
                                  ref.invalidate(receiptProvider(receipt.id));
                                },
                              ),
                            ],
                          ),
                          tablet: (context) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TableActionBtn(
                                label: 'Reprint',
                                icon: Icons.print_outlined,
                                color: ColorSet.primary,
                                onTap: () => ReceiptRoute(receipt.id).push<void>(context),
                              ),
                              const SizedBox(height: 6),
                              _TableActionBtn(
                                label: 'Refund',
                                icon: Icons.assignment_return_outlined,
                                color: ColorSet.warning,
                                onTap: () async {
                                  await RefundRoute(receipt.id).push<void>(context);
                                  ref.invalidate(receiptProvider(receipt.id));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        _ExpandedItems(isExpanded: isExpanded, receipt: receipt),
      ],
    );
  }
}

class _TableActionBtn extends StatelessWidget {
  const _TableActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return SizedBox(
      height: r.value<double>(kiosk: 36, tablet: 32, phone: 28),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
        label: Text(
          label,
          style: TextStyle(fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(POSRadius.sm),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: r.value<double>(kiosk: 10, tablet: 8, phone: 6),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ── Mobile card list ──────────────────────────────────────────────────────────
class _TransactionsMobileList extends ConsumerWidget {
  const _TransactionsMobileList({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(transactionsProvider);
    return asyncState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: ColorSet.primary,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading transactions:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: ColorSet.danger),
          ),
        ),
      ),
      data: (data) {
        if (data.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: POSColors.iconSubtle,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No transactions found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: POSColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: data.data.length,
          itemBuilder: (context, index) => _TransactionCard(receipt: data.data[index]),
        );
      },
    );
  }
}

class _TransactionCard extends HookConsumerWidget {
  const _TransactionCard({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedRotation(
                          turns: isExpanded.value ? 0.25 : 0,
                          duration: POSAnimation.normal,
                          curve: Curves.easeInOut,
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: ColorSet.primary,
                            size: 20,
                          ),
                        ),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            receipt.docNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: POSColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          receipt.totalAmount.pesoFormatted,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ColorSet.primary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        const Gap(26),
                        const Icon(Icons.calendar_today_rounded, size: 12, color: POSColors.iconSubtle),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            DateFormat('MM/dd/yyyy').format(receipt.docDate.toLocal()),
                            style: const TextStyle(fontSize: 12, color: POSColors.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(12),
                        const Icon(Icons.access_time_rounded, size: 12, color: POSColors.iconSubtle),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            DateFormat('hh:mm a').format(receipt.docDate.toLocal()),
                            style: const TextStyle(fontSize: 12, color: POSColors.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => ReceiptRoute(receipt.id).push<void>(context),
                          icon: const Icon(Icons.print_outlined, size: 15),
                          label: const Text('Reprint'),
                          style: TextButton.styleFrom(foregroundColor: ColorSet.primary),
                        ),
                        const Gap(4),
                        TextButton.icon(
                          onPressed: () async {
                            await RefundRoute(receipt.id).push<void>(context);
                            ref.invalidate(receiptProvider(receipt.id));
                          },
                          icon: const Icon(Icons.assignment_return_outlined, size: 15),
                          label: const Text('Refund'),
                          style: TextButton.styleFrom(foregroundColor: ColorSet.warning),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _ExpandedItems(isExpanded: isExpanded, receipt: receipt),
        ],
      ),
    );
  }
}

// ── Expanded items section ────────────────────────────────────────────────────
class _ExpandedItems extends ConsumerWidget {
  const _ExpandedItems({required this.isExpanded, required this.receipt});

  final ValueNotifier<bool> isExpanded;
  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    return AnimatedSize(
      duration: POSAnimation.normal,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded.value
          ? Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(
                  receiptProvider(receipt.id).select((it) {
                    return it.whenData(
                      (data) => (items: data.items, refunds: data.refunds),
                    );
                  }),
                );

                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorSet.primary,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  );
                }

                if (state.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Failed to load items: ${state.error}',
                        style: const TextStyle(fontSize: 12, color: ColorSet.danger),
                      ),
                    ),
                  );
                }

                final items = state.value?.items ?? const IList.empty();
                final refunds = state.value?.refunds ?? const IList.empty();

                if (items.isEmpty && refunds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
                      ),
                    ),
                  );
                }

                return Container(
                  padding: EdgeInsets.all(r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                  decoration: const BoxDecoration(
                    color: POSColors.surfaceSubtle,
                    border: Border(top: BorderSide(color: POSColors.borderDefault)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Items section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ColorSet.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(POSRadius.full),
                            ),
                            child: Text(
                              'Line Items (${receipt.items.where((e) => e.isMain).length})',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                                fontWeight: FontWeight.w600,
                                color: ColorSet.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...items.map((item) => Padding(
                            padding: EdgeInsets.only(left: item.isMain ? 0 : 16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity} ${item.description}',
                                      style: TextStyle(
                                        fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                        color: POSColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.isMain || item.grossAmount > Decimal.zero
                                        ? item.grossAmount.withCommas
                                        : '',
                                    style: TextStyle(
                                      fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                      color: POSColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      // Refunds
                      ...refunds.map((refund) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ColorSet.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(POSRadius.full),
                                    ),
                                    child: Text(
                                      'Refund (${refund.items.where((e) => e.isMain).length})',
                                      style: TextStyle(
                                        fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                                        fontWeight: FontWeight.w600,
                                        color: ColorSet.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${refund.reason}',
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                                  color: POSColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              ...refund.items.map((refundItem) => Padding(
                                    padding: EdgeInsets.only(
                                      left: refundItem.isMain ? 0 : 16,
                                      top: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${refundItem.quantity} ${refundItem.description}',
                                            style: TextStyle(
                                              fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                              color: POSColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          (refundItem.isMain ||
                                                  refundItem.refundAmount > Decimal.zero)
                                              ? '-${refundItem.refundAmount.withCommas}'
                                              : '',
                                          style: TextStyle(
                                            fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                            color: ColorSet.danger,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          )),
                    ],
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
