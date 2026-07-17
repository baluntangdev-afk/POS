import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' hide Store;
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../services/device/device_serial_number.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier.dart';
import '../entities/payment.dart';
import '../entities/receipt_item.dart';
import '../entities/refund.dart';
import '../entities/store.dart';
import '../enums/sale_type.dart';
import '../state/ordering_notifier.dart';
import '../state/receipt_notifier.dart';
import 'void_transaction_dialog.dart';

class ReceiptScreen extends HookConsumerWidget {
  const ReceiptScreen({super.key, required this.receiptId, this.autoPrint = false});

  final String receiptId;
  final bool autoPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroid = context.breakpoint.isAndroid;
    final r = context.responsive;

    final autoPrinted = useRef(false);
    useEffect(() {
      if (!autoPrint) return null;
      final sub = ref.listenManual(receiptProvider(receiptId), (previous, next) {
        if (autoPrinted.value) return;
        if (next case AsyncData(:final value) when !value.isVoided) {
          autoPrinted.value = true;
          ReceiptNotifier.printAction.run(ref, (txn) {
            return txn.get(receiptProvider(receiptId).notifier).print();
          }).ignore();
        }
      });
      return sub.close;
    }, const []);

    ref.listen(receiptProvider(receiptId), (previous, next) async {
      if (next case AsyncError(:final error)) {
        await showMessageDialog(context, type: DialogType.error, message: error.message);
        if (context.mounted && context.canPop()) {
          context.pop();
        } else if (context.mounted) {
          const MenuRoute().go(context);
        }
      }
    });

    final isLoading = ref.watch(receiptProvider(receiptId).select((it) => it.isLoading));
    final isVoided = ref.watch(
      receiptProvider(receiptId).select((it) => it.value?.isVoided ?? false),
    );

    final bodyContent = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: ColorSet.gradientBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Column(
                children: [
                  // Header
                  Container(
                    height: r.value<double>(kiosk: 100, tablet: 80, phone: 64),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.value<double>(kiosk: 48, tablet: 32, phone: 20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: r.value<double>(kiosk: 16, tablet: 12, phone: 10)),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Receipt',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 22, tablet: 18, phone: 15),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Transaction complete',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Status indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                            vertical: r.value<double>(kiosk: 8, tablet: 6, phone: 5),
                          ),
                          decoration: BoxDecoration(
                            color:
                                isVoided
                                    ? ColorSet.danger.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(POSRadius.full),
                            border: Border.all(
                              color:
                                  isVoided
                                      ? ColorSet.danger.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isVoided ? ColorSet.danger : ColorSet.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isVoided ? ColorSet.danger : ColorSet.success)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isVoided ? 'Transaction Voided' : 'Payment Successful',
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Receipt preview
                  Expanded(child: _ReceiptPreview(receiptId: receiptId)),
                  // Action buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.value<double>(kiosk: 48, tablet: 32, phone: 20),
                      r.value<double>(kiosk: 20, tablet: 16, phone: 12),
                      r.value<double>(kiosk: 48, tablet: 32, phone: 20),
                      r.value<double>(kiosk: 32, tablet: 24, phone: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: _PrintButton(receiptId: receiptId)),
                        SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                        const Expanded(child: _NewOrderButton()),
                        SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                        const Expanded(child: _CloseButton()),
                        if (!isVoided) ...[
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          Expanded(child: _VoidButton(receiptId: receiptId)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
    );

    if (isAndroid) {
      return AndroidScaffold(
        statusBarIconBrightness: Brightness.light,
        extendBodyBehindAppBar: true,
        body: SafeArea(top: false, bottom: false, child: bodyContent),
      );
    }

    return WindowsScaffold(extendBodyBehindAppBar: true, body: bodyContent);
  }
}

// ── Receipt preview (scrollable thermal receipt) ──────────────────────────────
class _ReceiptPreview extends ConsumerWidget {
  const _ReceiptPreview({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(receiptId).select((it) => it.value));
    final r = context.responsive;

    if (receipt == null) return const SizedBox.shrink();

    // Map receiptItemId → total refunded quantity across all refunds
    final refundedQties = <String, int>{};
    for (final refund in receipt.refunds) {
      for (final ri in refund.items) {
        refundedQties[ri.receiptItemId] = (refundedQties[ri.receiptItemId] ?? 0) + ri.quantity;
      }
    }

    return SingleChildScrollView(
      child: Center(
        child: Stack(
          children: [
            Container(
              width: r.value<double>(kiosk: 400, tablet: 360, phone: 320),
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 20, tablet: 18, phone: 14),
                vertical: r.value<double>(kiosk: 32, tablet: 24, phone: 16),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(POSRadius.xs),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StoreInfoView(store: receipt.store),
                  const Gap(8),
                  const _ReceiptDivider(char: '*'),
                  const Gap(4),
                  _DocumentInfoView(
                    docNumber: receipt.docNumber,
                    docDate: receipt.docDate,
                    cashier: receipt.cashier,
                  ),
                  const Gap(4),
                  const _ReceiptDivider(char: '*'),
                  Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                  _ItemsView(items: receipt.items.toList(), refundedQuantities: refundedQties),
                  Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                  const _ReceiptDivider(char: '-'),
                  Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                  _SummaryView(
                    vatableSales: receipt.vatableSales,
                    vatExemptSales: receipt.vatExemptSales,
                    vatAmount: receipt.vatAmount,
                    discountAmount: receipt.discountAmount,
                    totalAmount: receipt.totalAmount,
                  ),
                  if (receipt.refunds.isNotEmpty) ...[
                    Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                    const _ReceiptDivider(char: '-'),
                    Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                    _RefundsView(
                      refunds: receipt.refunds.toList(),
                      originalTotal: receipt.totalAmount,
                    ),
                  ],
                  if (receipt.isVoided && receipt.voidReason != null) ...[
                    Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                    const _ReceiptDivider(char: '-'),
                    Gap(r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
                    Text(
                      'VOID REASON:',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 10),
                        fontWeight: FontWeight.bold,
                        color: ColorSet.danger,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      receipt.voidReason!,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 10),
                        color: ColorSet.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                  _PaymentView(payment: receipt.payment),
                  Gap(r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
                  Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 24, tablet: 18, phone: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(r.value<double>(kiosk: 80, tablet: 56, phone: 40)),
                ],
              ),
            ),
            // VOIDED diagonal stamp overlay
            if (receipt.isVoided)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(POSRadius.xs),
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.35,
                        child: Opacity(
                          opacity: 0.25,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: ColorSet.danger, width: 6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'VOIDED',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 52, tablet: 44, phone: 36),
                                fontWeight: FontWeight.w900,
                                color: ColorSet.danger,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt internal widgets (thermal print format — unchanged) ───────────────

class _StoreInfoView extends ConsumerWidget {
  const _StoreInfoView({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Store(:legalName, :addressLine1, :addressLine2, :tin) = store;
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12));
    final serialNumber = ref.watch(deviceSerialNumberProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Assets.images.cartivoLogo.image(height: r.value<double>(kiosk: 32, tablet: 28, phone: 24)),
        Gap(r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
        Text(
          [legalName, addressLine1, addressLine2].join('\n'),
          textAlign: TextAlign.center,
          style: style,
        ),
        Text('TIN: $tin', style: style),
        if (serialNumber != null) Text('S/N: $serialNumber', style: style),
        Text(
          'Sales Invoice',
          style: TextStyle(
            fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DocumentInfoView extends StatelessWidget {
  const _DocumentInfoView({required this.docNumber, required this.docDate, required this.cashier});

  final String docNumber;
  final DateTime docDate;
  final Cashier cashier;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMd().add_jm().format(docDate.toLocal()),
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'SI# '),
                  TextSpan(text: docNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
          ],
        ),
        const Gap(4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Cashier: ${cashier.id} - ${cashier.fullName}',
            style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
          ),
        ),
      ],
    );
  }
}

class _SaleTypeView extends StatelessWidget {
  const _SaleTypeView({required this.type});

  final SaleType type;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      children: [
        const Expanded(child: _ReceiptDivider(char: '-')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            type.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Expanded(child: _ReceiptDivider(char: '-')),
      ],
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({required this.items, this.refundedQuantities = const {}});

  final List<ReceiptItem> items;
  final Map<String, int> refundedQuantities;

  // Groups items by their main item's category, preserving first-appearance
  // order. Add-on/modifier lines stay attached to the main item that
  // precedes them regardless of their own category. Uncategorized items are
  // collected into an "Other" group placed last.
  List<_CategoryGroup> _groupByCategory() {
    final clusters = <List<ReceiptItem>>[];
    for (final item in items) {
      if (item.isMain || clusters.isEmpty) {
        clusters.add([item]);
      } else {
        clusters.last.add(item);
      }
    }

    final itemsByCategory = <String?, List<ReceiptItem>>{};
    for (final cluster in clusters) {
      itemsByCategory.putIfAbsent(cluster.first.category, () => []).addAll(cluster);
    }

    final otherItems = itemsByCategory.remove(null);
    return [
      for (final entry in itemsByCategory.entries)
        _CategoryGroup(category: entry.key, items: entry.value),
      if (otherItems != null) _CategoryGroup(category: 'Other', items: otherItems),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
            Text(
              'Price',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
          ],
        ),
        Gap(r.value<double>(kiosk: 10, tablet: 8, phone: 5)),
        for (final group in _groupByCategory()) ...[
          Padding(
            padding: EdgeInsets.only(top: r.value<double>(kiosk: 6, tablet: 6, phone: 4)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                group.category.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 10),
                  color: POSColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          ...group.items.map((item) => _buildItemRow(context, item)),
        ],
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, ReceiptItem item) {
    final r = context.responsive;
    final refundedQty = item.isMain ? (refundedQuantities[item.id] ?? 0) : 0;
    final isFullyRefunded = item.isMain && refundedQty >= item.quantity;
    final isPartiallyRefunded = item.isMain && refundedQty > 0 && !isFullyRefunded;
    final lineStyle = TextStyle(
      fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
      decoration: isFullyRefunded ? TextDecoration.lineThrough : null,
      color: isFullyRefunded ? POSColors.textTertiary : null,
    );

    return Padding(
      padding: EdgeInsets.only(left: item.isMain ? 0 : 8, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text('${item.quantity} ${item.description}', style: lineStyle)),
              Text(
                item.isMain || item.grossAmount > Decimal.zero ? item.grossAmount.withCommas : '',
                style: lineStyle,
              ),
            ],
          ),
          if (item.isMain && (item.saleType != null || item.note != null))
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Row(
                children: [
                  if (item.saleType != null)
                    Text(
                      '[${item.saleType!.displayName}] ',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (item.note != null)
                    Flexible(
                      child: Text(
                        item.note!,
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          if (isPartiallyRefunded)
            Text(
              '  (Refunded: $refundedQty of ${item.quantity})',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 11, tablet: 11, phone: 10),
                color: ColorSet.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({required String? category, required this.items})
    : category = category ?? 'Other';

  final String category;
  final List<ReceiptItem> items;
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.vatableSales,
    required this.vatExemptSales,
    required this.vatAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  final Decimal vatableSales;
  final Decimal vatExemptSales;
  final Decimal vatAmount;
  final Decimal discountAmount;
  final Decimal totalAmount;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'VATable Sales',
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
            const Spacer(),
            Text(
              vatableSales.withCommas,
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
          ],
        ),
        const Gap(4),
        if (vatExemptSales > Decimal.zero) ...[
          Row(
            children: [
              Text(
                'VAT-Exempt Sales',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              const Spacer(),
              Text(
                vatExemptSales.withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
          const Gap(4),
        ],
        Row(
          children: [
            Text(
              'VAT',
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
            const Spacer(),
            Text(
              vatAmount.withCommas,
              style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
            ),
          ],
        ),
        const Gap(4),
        if (discountAmount > Decimal.zero) ...[
          Row(
            children: [
              Text(
                'Discount',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              const Spacer(),
              Text(
                (-discountAmount).withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
          const Gap(4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 24, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              totalAmount.withCommas,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 24, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RefundsView extends StatelessWidget {
  const _RefundsView({required this.refunds, required this.originalTotal});

  final List<Refund> refunds;
  final Decimal originalTotal;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final totalRefund = refunds.fold(Decimal.zero, (sum, refund) {
      return sum +
          refund.items.where((ri) => ri.isMain).fold(Decimal.zero, (s, ri) => s + ri.refundAmount);
    });
    final netTotal = originalTotal - totalRefund;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REFUNDS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                color: ColorSet.danger,
              ),
            ),
            Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                color: ColorSet.danger,
              ),
            ),
          ],
        ),
        Gap(r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
        for (final refund in refunds) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reason: ${refund.reason}',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                color: POSColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Gap(2),
          for (final ri in refund.items.where((ri) => ri.isMain))
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${ri.quantity} ${ri.description}',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                        color: ColorSet.danger,
                      ),
                    ),
                  ),
                  Text(
                    '-${ri.refundAmount.withCommas}',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                      color: ColorSet.danger,
                    ),
                  ),
                ],
              ),
            ),
          Gap(r.value<double>(kiosk: 6, tablet: 4, phone: 4)),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Refund',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                fontWeight: FontWeight.bold,
                color: ColorSet.danger,
              ),
            ),
            Text(
              '-${totalRefund.withCommas}',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12),
                fontWeight: FontWeight.bold,
                color: ColorSet.danger,
              ),
            ),
          ],
        ),
        const Gap(6),
        const _ReceiptDivider(char: '-'),
        const Gap(6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Net Total',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              netTotal.withCommas,
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    if (payment case CashPayment(:final cashReceived, :final change)) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              Text(
                cashReceived.withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              Text(
                change.withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
        ],
      );
    } else if (payment case CardPayment(
      :final referenceNumber,
      :final cardType,
      :final cardNumber,
    )) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$cardType ($cardNumber)',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              Text(
                payment.paidAmount.withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
          const Gap(4),
          Center(
            child: Text(
              'Ref: $referenceNumber',
              style: TextStyle(fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 10)),
            ),
          ),
        ],
      );
    } else if (payment case QRPayment(:final referenceNumber, :final walletProvider)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                walletProvider,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
              Text(
                payment.paidAmount.withCommas,
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
              ),
            ],
          ),
          const Gap(4),
          Center(
            child: Text(
              'Ref: $referenceNumber',
              style: TextStyle(fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 10)),
            ),
          ),
        ],
      );
    } else if (payment is ZeroPayment) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'ZERO PAYMENT',
          style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 14, phone: 12)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider({required this.char})
    : assert(char.length == 1, 'char should be 1 character long.');

  final String char;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6;
        final dashCount = (boxWidth / dashWidth).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Text(
              char,
              style: TextStyle(fontSize: r.value<double>(kiosk: 10, tablet: 10, phone: 8)),
            );
          }),
        );
      },
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _PrintButton extends ConsumerWidget {
  const _PrintButton({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final hasReceipt = ref.watch(receiptProvider(receiptId).select((it) => it.hasValue));
    final printAction = ReceiptNotifier.printAction;
    final printStatus = ref.watch(printAction);

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
    });

    if (!hasReceipt) return const SizedBox.shrink();

    final isPending = printStatus is MutationPending;
    final isSuccess = printStatus is MutationSuccess;
    final label =
        isPending
            ? 'Printing...'
            : isSuccess
            ? 'Reprint'
            : 'Print Receipt';
    final height = r.value<double>(kiosk: 64, tablet: 56, phone: 48);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isPending ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap:
              isPending
                  ? null
                  : () {
                    printAction.run(ref, (txn) {
                      return txn.get(receiptProvider(receiptId).notifier).print();
                    }).ignore();
                  },
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPending)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(
                    isSuccess ? Icons.print_outlined : Icons.print_rounded,
                    color: Colors.white,
                    size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewOrderButton extends ConsumerWidget {
  const _NewOrderButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 64, tablet: 56, phone: 48);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            ref.invalidate(orderingProvider);
            const OrderingRoute().go(context);
          },
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_shopping_cart_rounded,
                  color: ColorSet.primary,
                  size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'New Order',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w700,
                    color: ColorSet.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends ConsumerWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 64, tablet: 56, phone: 48);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            ref.invalidate(orderingProvider);
            if (context.canPop()) {
              context.pop();
            } else {
              const MenuRoute().go(context);
            }
          },
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Close',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoidButton extends ConsumerWidget {
  const _VoidButton({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final receipt = ref.watch(receiptProvider(receiptId).select((it) => it.value));

    if (receipt == null || receipt.isVoided) return const SizedBox.shrink();

    final height = r.value<double>(kiosk: 64, tablet: 56, phone: 48);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorSet.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ColorSet.danger.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () async {
            final voided = await VoidTransactionDialog.show(
              context,
              salesOrderId: receipt.id,
              invoiceNumber: receipt.docNumber,
              totalAmount: receipt.totalAmount,
            );
            if (voided && context.mounted) {
              ref.invalidate(orderingProvider);
              const MenuRoute().go(context);
            }
          },
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block_rounded,
                  color: ColorSet.danger,
                  size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Void',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w600,
                    color: ColorSet.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
