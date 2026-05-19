import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/debounce.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_box_form_field.dart';
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
        ref
            .read(transactionsProvider.notifier)
            .getResults(
              page: page.value,
              limit: limit.value,
              soNumber: soNumber.value,
              soDate: soDate.value,
              sort: sort.value,
            );
      });
      return null;
    }, [page.value, limit.value, soNumber.value, soDate.value, sort.value]);

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 68.0, tablet: 60.0, phone: 52.0)),
        child: const _TopAppBar(),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        child: Column(
          spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          children: [
            _PaginationControls(
              page: page,
              limit: limit,
              totalPages: totalPages,
              soNumber: soNumber,
              soDate: soDate,
            ),
            Expanded(child: _TransactionsTable(sort: sort)),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.responsive.value(kiosk: 68.0, tablet: 60.0, phone: 52.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 24.0, tablet: 16.0, phone: 12.0),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios,
              size: context.responsive.value(kiosk: 18.0, tablet: 15.0, phone: 13.0),
            ),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorSet.primary,
              side: const BorderSide(color: ColorSet.primary, width: 2),
              minimumSize: Size(
                context.responsive.value(kiosk: 110.0, tablet: 90.0, phone: 76.0),
                context.responsive.value(kiosk: 52.0, tablet: 44.0, phone: 38.0),
              ),
              textStyle: TextStyle(
                fontSize: context.responsive.value(kiosk: 15.0, tablet: 13.0, phone: 12.0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Expanded(
            child: Text(
              'Transactions',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 16.0),
                fontWeight: FontWeight.w600,
                color: ColorSet.dark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: context.responsive.value<double>(kiosk: 110, tablet: 90, phone: 76),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Row(
            spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
            children: [
              Expanded(
                child: HookBuilder(
                  builder: (context) {
                    final debounce = useDebounce(const Duration(milliseconds: 300));
                    return TextBoxFormField.singleLine(
                      hint: 'Search invoice number...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        color: Colors.grey.shade500,
                      ),
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      ),
                      onChanged: (value) {
                        debounce(() {
                          soNumber.value = value;
                        });
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: soDate.value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    soDate.value = picked;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.value(kiosk: 12, tablet: 12, phone: 8),
                      vertical: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffa9a9a9)),
                      borderRadius: BorderRadius.circular(
                        context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                          color: Colors.grey.shade500,
                        ),
                        Gap(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
                        Expanded(
                          child: Text(
                            soDate.value != null
                                ? DateFormat('MM/dd/yyyy').format(soDate.value!.toLocal())
                                : 'Filter by date...',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                              color: soDate.value != null ? Colors.black87 : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        if (soDate.value != null)
                          GestureDetector(
                            onTap: () => soDate.value = null,
                            child: Icon(
                              Icons.close,
                              size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Button(
                label: const Text('Previous'),
                onPressed: page.value > 1 ? () => page.value-- : null,
                leading: const Icon(Icons.keyboard_arrow_left),
              ),
              const Spacer(),
              Text(
                'Page ${totalPages > 0 ? page.value : 0} of $totalPages',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 16, tablet: 16, phone: 12),
                  vertical: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(
                    context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
                  ),
                ),
                child: DropdownButton<int>(
                  value: limit.value,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                    color: Colors.black87,
                  ),
                  items:
                      [10, 25, 50, 100].map((rows) {
                        return DropdownMenuItem(value: rows, child: Text('$rows rows'));
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      limit.value = value;
                    }
                  },
                ),
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Button(
                label: const Text('Next'),
                onPressed: page.value < totalPages ? () => page.value++ : null,
                trailing: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsTable extends ConsumerWidget {
  const _TransactionsTable({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(transactionsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorSet.secondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
                topRight: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
              ),
            ),
            padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: _SortableHeader(
                    title: 'Invoice Number',
                    sortField: 'soNumber',
                    currentSort: sort,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _SortableHeader(title: 'Date', sortField: 'soDate', currentSort: sort),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                      ),
                      child: Text(
                        'Error loading transactions:\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                          color: ColorSet.danger,
                        ),
                      ),
                    ),
                  ),
              data: (data) {
                if (data.data.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions found.',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: data.data.length,
                  itemBuilder: (context, index) {
                    final receipt = data.data[index];
                    return _TransactionRow(receipt: receipt);
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
        color: Colors.white,
        fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({required this.title, required this.sortField, required this.currentSort});

  final String title;
  final String sortField;
  final ValueNotifier<String?> currentSort;

  @override
  Widget build(BuildContext context) {
    final isAsc = currentSort.value == '$sortField:asc';
    final isDesc = currentSort.value == '$sortField:desc';
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
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(4),
          Icon(
            isAsc
                ? Icons.arrow_upward
                : isDesc
                ? Icons.arrow_downward
                : Icons.swap_vert,
            color: (isAsc || isDesc) ? Colors.white : Colors.white.withValues(alpha: 0.5),
            size: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
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
    final isExpanded = useState(false);
    return Column(
      children: [
        GestureDetector(
          onTap: () => isExpanded.value = !isExpanded.value,
          child: Container(
            padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedRotation(
                    turns: isExpanded.value ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      color: ColorSet.primary,
                      size: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    receipt.docNumber,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('MM/dd/yyyy').format(receipt.docDate.toLocal()),
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('hh:mm a').format(receipt.docDate.toLocal()),
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    receipt.totalAmount.pesoFormatted,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return Expanded(
                      flex: 3,
                      child: ResponsiveBuilder(
                        kiosk: (context) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Button(
                                  label: const Text('Reprint'),
                                  onPressed: () {
                                    ReceiptRoute(receipt.id).push<void>(context);
                                  },
                                ),
                              ),
                              const Gap(8),
                              Flexible(
                                child: Button(
                                  label: const Text('Refund'),
                                  onPressed: () async {
                                    await RefundRoute(receipt.id).push<void>(context);
                                    ref.invalidate(receiptProvider(receipt.id));
                                  },
                                  backgroundColor: ColorSet.warning,
                                ),
                              ),
                            ],
                          );
                        },
                        tablet: (context) {
                          return Column(
                            children: [
                              Button(
                                label: const Text('Reprint'),
                                onPressed: () {
                                  ReceiptRoute(receipt.id).push<void>(context);
                                },
                              ),
                              const Gap(6),
                              Button(
                                label: const Text('Refund'),
                                onPressed: () async {
                                  await RefundRoute(receipt.id).push<void>(context);
                                  ref.invalidate(receiptProvider(receipt.id));
                                },
                                backgroundColor: ColorSet.warning,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              isExpanded.value
                  ? Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(
                        receiptProvider(receipt.id).select((it) {
                          return it.whenData((data) {
                            return (items: data.items, refunds: data.refunds);
                          });
                        }),
                      );

                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Failed to load items: ${state.error}'),
                          ),
                        );
                      }

                      final items = state.value?.items ?? const IList.empty();
                      final refunds = state.value?.refunds ?? const IList.empty();

                      if (items.isEmpty && refunds.isEmpty) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16), child: Text('No item found')),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Line Items (${receipt.items.where((e) => e.isMain).length})',
                              style: TextStyle(
                                fontSize: context.responsive.value(
                                  kiosk: 14,
                                  tablet: 14,
                                  phone: 12,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            ...items.map(
                              (item) => Padding(
                                padding: EdgeInsets.only(left: item.isMain ? 0 : 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity} ${item.description}',
                                        style: TextStyle(
                                          fontSize: context.responsive.value(
                                            kiosk: 14,
                                            tablet: 14,
                                            phone: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.isMain || item.grossAmount > Decimal.zero
                                          ? item.grossAmount.withCommas
                                          : '',
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 14,
                                          tablet: 14,
                                          phone: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...refunds.map(
                              (refund) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Gap(8),
                                  Text(
                                    'Refund (${refund.items.where((e) => e.isMain).length})',
                                    style: TextStyle(
                                      fontSize: context.responsive.value(
                                        kiosk: 14,
                                        tablet: 14,
                                        phone: 12,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: ColorSet.text,
                                    ),
                                  ),
                                  Text(
                                    'Reason: ${refund.reason}',
                                    style: TextStyle(
                                      fontSize: context.responsive.value(
                                        kiosk: 12,
                                        tablet: 12,
                                        phone: 10,
                                      ),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  ...refund.items.map(
                                    (refundItem) => Padding(
                                      padding: EdgeInsets.only(left: refundItem.isMain ? 0 : 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${refundItem.quantity} ${refundItem.description}',
                                              style: TextStyle(
                                                fontSize: context.responsive.value(
                                                  kiosk: 14,
                                                  tablet: 14,
                                                  phone: 12,
                                                ),
                                                color: ColorSet.text,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            (refundItem.isMain ||
                                                    refundItem.refundAmount > Decimal.zero)
                                                ? '-${refundItem.refundAmount.withCommas}'
                                                : '',
                                            style: TextStyle(
                                              fontSize: context.responsive.value(
                                                kiosk: 14,
                                                tablet: 14,
                                                phone: 12,
                                              ),
                                              color: ColorSet.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
