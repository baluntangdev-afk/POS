import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/built_in_printer.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../transactions/view/refund_screen.dart';
import '../../transactions/view/void_transaction_dialog.dart';
import '../entities/receipt.dart';
import '../entities/receipt_item.dart';
import '../entities/refund.dart';
import '../entities/sale_payment.dart';
import '../state/ordering_notifier.dart';
import '../state/receipt_notifier.dart';

enum ReceiptType { order, transaction }

class ReceiptScreen extends HookConsumerWidget {
  const ReceiptScreen({super.key, required this.saleId, required this.type});

  final int saleId;
  final ReceiptType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printingBuiltIn = useState(false);
    final printingBluetooth = useState(false);
    final builtInAvailable = useState(false);
    final bluetoothConnected = useState(false);
    final receiptAsync = ref.watch(receiptProvider(saleId));

    useEffect(() {
      BuiltInPrinter.isAvailable().then((v) => builtInAvailable.value = v);
      PrintService.getSavedMac().then((v) => bluetoothConnected.value = v != null);
      return null;
    }, const []);

    Future<void> showPrintResult(bool ok) async {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Receipt printed' : 'Couldn\'t print — check your printer and try again',
          ),
        ),
      );
    }

    Future<void> printBuiltIn() async {
      printingBuiltIn.value = true;
      final ok = await ref.read(receiptProvider(saleId).notifier).printBuiltIn();
      printingBuiltIn.value = false;
      await showPrintResult(ok);
    }

    Future<void> printBluetooth() async {
      printingBluetooth.value = true;
      final ok = await ref.read(receiptProvider(saleId).notifier).printBluetooth();
      printingBluetooth.value = false;
      await showPrintResult(ok);
    }

    void handleBack() {
      switch (type) {
        case ReceiptType.order:
          context.go('/dashboard');
        case ReceiptType.transaction:
          context.pop();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Receipt'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _newOrder(context, ref),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('New Order'),
            ),
          ],
        ),
        body: receiptAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data:
              (receipt) => Column(
                children: [
                  _StatusBanner(receipt: receipt),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: _ReceiptPreview(receipt: receipt)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        // FilledButton.icon(
                        //   onPressed: () => _newOrder(context, ref),
                        //   icon: const Icon(Icons.add_shopping_cart_rounded),
                        //   label: const Text('New Order'),
                        //   style: FilledButton.styleFrom(
                        //     minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
                        //   ),
                        // ),
                        if (builtInAvailable.value) ...[
                          const Gap(AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed:
                                printingBuiltIn.value ? null : printBuiltIn,
                            icon:
                                printingBuiltIn.value
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.print_outlined),
                            label: const Text('Print (Built-in)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                AppSpacing.touchMin,
                              ),
                            ),
                          ),
                        ],
                        if (!builtInAvailable.value &&
                            bluetoothConnected.value) ...[
                          const Gap(AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed:
                                printingBluetooth.value ? null : printBluetooth,
                            icon:
                                printingBluetooth.value
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.bluetooth_rounded),
                            label: const Text('Print (Bluetooth)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                AppSpacing.touchMin,
                              ),
                            ),
                          ),
                        ],
                        if (!builtInAvailable.value &&
                            !bluetoothConnected.value) ...[
                          const Gap(AppSpacing.md),
                          Text(
                            'No printer configured. Go to Settings → Printer '
                            'Setup to connect one.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        // if (!receipt.isVoided) ...[
                        //   const Gap(AppSpacing.md),
                        //   OutlinedButton.icon(
                        //     onPressed: () => _refundReceipt(context, ref),
                        //     icon: const Icon(Icons.assignment_return_outlined),
                        //     label: const Text('Refund Items'),
                        //     style: OutlinedButton.styleFrom(
                        //       minimumSize: const Size(double.infinity, AppSpacing.touchMin),
                        //     ),
                        //   ),
                        // ],
                        if (!receipt.isVoided && !receipt.voidLocked) ...[
                          const Gap(AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () => _voidReceipt(context, ref),
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('Void Transaction'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              minimumSize: const Size(
                                double.infinity,
                                AppSpacing.touchMin,
                              ),
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ] else if (receipt.voidLocked) ...[
                          const Gap(AppSpacing.md),
                          Text(
                            'This transaction can no longer be voided — it is '
                            'already included in a closed X-Reading, Daily '
                            'Report, or Z-Reading.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  void _newOrder(BuildContext context, WidgetRef ref) {
    ref.invalidate(orderingProvider);
    context.go('/order');
  }

  Future<void> _refundReceipt(BuildContext context, WidgetRef ref) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RefundScreen(saleId: saleId)));
    ref.invalidate(receiptProvider(saleId));
  }

  Future<void> _voidReceipt(BuildContext context, WidgetRef ref) async {
    final receipt = ref.read(receiptProvider(saleId)).value;
    if (receipt == null) return;

    final voided = await VoidTransactionDialog.show(
      context,
      saleId: saleId,
      invoiceNumber: receipt.docNumber,
      totalAmount: receipt.totalAmount,
    );
    if (!voided) return;

    ref.invalidate(receiptProvider(saleId));
    ref.invalidate(orderingProvider);
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final isVoided = receipt.isVoided;
    final color = isVoided ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: isVoided ? AppColors.errorLight : AppColors.successLight,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              isVoided ? Icons.block_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVoided ? 'Transaction Voided' : 'Payment Successful',
                  style: AppTextStyles.headingSm.copyWith(color: color),
                ),
                Text(
                  isVoided && receipt.voidReason != null
                      ? 'Reason: ${receipt.voidReason}'
                      : receipt.docNumber,
                  style: AppTextStyles.bodySm.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Receipt preview (paper receipt look) ──────────────────────────────────────
class _ReceiptPreview extends ConsumerWidget {
  const _ReceiptPreview({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInfo = ref.watch(storeInfoProvider).value;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StoreInfoView(
                  storeName: storeInfo?.storeName,
                  address: storeInfo?.address,
                  tin: storeInfo?.tin,
                ),
                const Gap(8),
                const _ReceiptDivider(char: '*'),
                const Gap(4),
                _DocumentInfoView(receipt: receipt),
                const Gap(4),
                const _ReceiptDivider(char: '*'),
                const Gap(16),
                _ItemsView(
                  items: receipt.items,
                  refundedQuantities: receipt.refundedQuantities,
                ),
                const Gap(16),
                const _ReceiptDivider(char: '-'),
                const Gap(16),
                _SummaryView(receipt: receipt),
                if (receipt.hasRefunds) ...[
                  const Gap(16),
                  const _ReceiptDivider(char: '-'),
                  const Gap(16),
                  _RefundsView(
                    refunds: receipt.refunds,
                    originalTotal: receipt.totalAmount,
                  ),
                ],
                if (receipt.isVoided && receipt.voidReason != null) ...[
                  const Gap(16),
                  const _ReceiptDivider(char: '-'),
                  const Gap(8),
                  Text(
                    'VOID REASON:',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    receipt.voidReason!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Gap(16),
                _PaymentView(payment: receipt.payment),
                const Gap(32),
                Text('Thank You!', style: AppTextStyles.headingMd),
                const Gap(40),
              ],
            ),
          ),
          if (receipt.isVoided)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Opacity(
                        opacity: 0.25,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.error,
                              width: 6,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VOIDED',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.error,
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
    );
  }
}

class _StoreInfoView extends StatelessWidget {
  const _StoreInfoView({this.storeName, this.address, this.tin});

  final String? storeName;
  final String? address;
  final String? tin;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (storeName != null && storeName!.isNotEmpty)
          Text(
            storeName!,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSm,
          ),
        if (address != null && address!.isNotEmpty) ...[
          const Gap(4),
          Text(address!, textAlign: TextAlign.center, style: style),
        ],
        if (tin != null && tin!.isNotEmpty) ...[
          const Gap(4),
          Text('TIN: $tin', style: style),
        ],
        const Gap(12),
        Text(
          'Sales Invoice',
          style: AppTextStyles.headingSm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DocumentInfoView extends StatelessWidget {
  const _DocumentInfoView({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMd().add_jm().format(receipt.docDate.toLocal()),
              style: AppTextStyles.bodySm,
            ),
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm,
                children: [
                  const TextSpan(text: 'SI# '),
                  TextSpan(
                    text: receipt.docNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Cashier: ${receipt.cashierName}',
            style: AppTextStyles.bodySm,
          ),
        ),
      ],
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({required this.items, this.refundedQuantities = const {}});

  final List<ReceiptItem> items;
  final Map<int, int> refundedQuantities;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Description', style: AppTextStyles.labelLg),
            Text('Price', style: AppTextStyles.labelLg),
          ],
        ),
        const Gap(8),
        for (final item in items) _buildItemRow(item),
      ],
    );
  }

  Widget _buildItemRow(ReceiptItem item) {
    final refundedQty = item.isMain ? (refundedQuantities[item.id] ?? 0) : 0;
    final isFullyRefunded = item.isMain && refundedQty >= item.quantity;
    final isPartiallyRefunded =
        item.isMain && refundedQty > 0 && !isFullyRefunded;
    final lineStyle = AppTextStyles.bodySm.copyWith(
      decoration: isFullyRefunded ? TextDecoration.lineThrough : null,
      color: isFullyRefunded ? AppColors.textDisabled : AppColors.textPrimary,
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
              Expanded(
                child: Text(
                  '${item.quantity} ${item.description}',
                  style: lineStyle,
                ),
              ),
              Text(item.totalAmount.toStringAsFixed(2), style: lineStyle),
            ],
          ),
          if (item.isMain &&
              item.discountBeneficiaryName != null &&
              item.discountBeneficiaryName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                'LESS: ${item.discountType ?? 'Discount'} '
                '— ${item.discountBeneficiaryName} (${item.discountBeneficiaryId})',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isPartiallyRefunded)
            Text(
              '  (Refunded: $refundedQty of ${item.quantity})',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('VATable Sales', receipt.vatableAmount),
        if (receipt.vatExemptSales > 0)
          _row('VAT-Exempt Sales', receipt.vatExemptSales),
        _row('VAT', receipt.vatAmount),
        if (receipt.discountAmount > 0)
          _row('Discount', -receipt.discountAmount),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTextStyles.priceMd),
            Text(
              receipt.totalAmount.toStringAsFixed(2),
              style: AppTextStyles.priceMd,
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySm),
          const Spacer(),
          Text(amount.toStringAsFixed(2), style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

class _RefundsView extends StatelessWidget {
  const _RefundsView({required this.refunds, required this.originalTotal});

  final List<Refund> refunds;
  final double originalTotal;

  @override
  Widget build(BuildContext context) {
    final totalRefund = refunds.fold(
      0.0,
      (sum, refund) =>
          sum +
          refund.items
              .where((ri) => ri.isMain)
              .fold(0.0, (s, ri) => s + ri.refundAmount),
    );
    final netTotal = originalTotal - totalRefund;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REFUNDS',
              style: AppTextStyles.labelLg.copyWith(color: AppColors.error),
            ),
            Text(
              'Amount',
              style: AppTextStyles.labelLg.copyWith(color: AppColors.error),
            ),
          ],
        ),
        const Gap(8),
        for (final refund in refunds) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reason: ${refund.reason}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
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
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  Text(
                    '-${ri.refundAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          const Gap(6),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Refund',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '-${totalRefund.toStringAsFixed(2)}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
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
            Text('Net Total', style: AppTextStyles.headingSm),
            Text(netTotal.toStringAsFixed(2), style: AppTextStyles.headingSm),
          ],
        ),
      ],
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.payment});

  final SalePayment payment;

  @override
  Widget build(BuildContext context) {
    if (payment.method == 'cash') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cash', style: AppTextStyles.bodySm),
              Text(
                payment.cashReceived.toStringAsFixed(2),
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Change', style: AppTextStyles.bodySm),
              Text(
                payment.change.toStringAsFixed(2),
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_methodLabel(payment.method), style: AppTextStyles.bodySm),
            Text(
              payment.amountPaid.toStringAsFixed(2),
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
        if (payment.reference != null && payment.reference!.isNotEmpty) ...[
          const Gap(4),
          Center(
            child: Text(
              'Ref: ${payment.reference}',
              style: AppTextStyles.bodySm,
            ),
          ),
        ],
      ],
    );
  }

  String _methodLabel(String method) => switch (method) {
    'card' => 'Card',
    'ewallet' => 'E-Wallet',
    _ => method,
  };
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider({required this.char})
    : assert(char.length == 1, 'char should be 1 character long.');

  final String char;

  @override
  Widget build(BuildContext context) {
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
              style: AppTextStyles.bodySm.copyWith(fontSize: 10),
            );
          }),
        );
      },
    );
  }
}
