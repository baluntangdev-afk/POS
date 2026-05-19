import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier.dart';
import '../entities/payment.dart';
import '../entities/receipt_item.dart';
import '../entities/store.dart';
import '../enums/sale_type.dart';
import '../state/receipt_notifier.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(receiptProvider(receiptId), (previous, next) async {
      if (next case AsyncError(:final error)) {
        await showMessageDialog(context, type: DialogType.error, message: '$error');

        if (context.mounted && context.canPop()) {
          context.pop();
        } else if (context.mounted) {
          const SalesRoute().go(context);
        }
      }
    });

    final isLoading = ref.watch(receiptProvider(receiptId).select((it) => it.isLoading));

    return WindowsScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.only(
          top: context.responsive.value(kiosk: 140, tablet: 110, phone: 90),
          bottom: context.responsive.value(kiosk: 64, tablet: 48, phone: 32),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorSet.secondary.withValues(alpha: 0.85),
              ColorSet.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  spacing: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                  children: [
                    Expanded(child: _ReceiptPreview(receiptId: receiptId)),
                    // Action buttons row
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _PrintButton(receiptId: receiptId)),
                          SizedBox(
                            width: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          ),
                          Expanded(child: const _NewOrderButton()),
                          SizedBox(
                            width: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          ),
                          Expanded(child: const _CloseButton()),
                        ],
                      ),
                    ),
                    SizedBox(height: context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
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
      height: context.responsive.value(kiosk: 120, tablet: 90, phone: 70),
      decoration: const BoxDecoration(color: ColorSet.transparent),
      child: Center(
        child: Text(
          'Order Receipt',
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 36, tablet: 28, phone: 20),
            fontWeight: FontWeight.w600,
            color: ColorSet.light,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReceiptPreview extends ConsumerWidget {
  const _ReceiptPreview({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(receiptId).select((it) => it.value));

    if (receipt == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Container(
        width: context.responsive.value(kiosk: 400, tablet: 360, phone: 320),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.value(kiosk: 16, tablet: 16, phone: 12),
          vertical: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        ),
        decoration: BoxDecoration(
          color: ColorSet.light,
          borderRadius: BorderRadius.circular(2.0),
          boxShadow: [
            BoxShadow(
              color: ColorSet.dark.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
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
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            _SaleTypeView(type: receipt.type),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            _ItemsView(items: receipt.items.toList()),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            const _ReceiptDivider(char: '-'),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            _SummaryView(
              vatableSales: receipt.vatableSales,
              vatExemptSales: receipt.vatExemptSales,
              vatAmount: receipt.vatAmount,
              discountAmount: receipt.discountAmount,
              totalAmount: receipt.totalAmount,
            ),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            _PaymentView(payment: receipt.payment),
            Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
            Text(
              'Thank You!',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(context.responsive.value(kiosk: 128, tablet: 80, phone: 48)),
          ],
        ),
      ),
    );
  }
}

class _StoreInfoView extends StatelessWidget {
  const _StoreInfoView({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final Store(:legalName, :addressLine1, :addressLine2, :tin) = store;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Assets.images.png.imgAdtoKart.image(
          height: context.responsive.value(kiosk: 32, tablet: 28, phone: 24),
        ),
        Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
        Text(
          [legalName, addressLine1, addressLine2].join('\n'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        Text(
          'TIN: $tin',
          style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        Text(
          'Sales Invoice',
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat.yMd().add_jm().format(docDate.toLocal()),
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'SI# '),
                  TextSpan(text: docNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
          ],
        ),
        const Gap(4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Cashier: ${cashier.id} - ${cashier.fullName}',
            style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
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
    return Row(
      children: [
        const Expanded(child: _ReceiptDivider(char: '-')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            type.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
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
  const _ItemsView({required this.items});

  final List<ReceiptItem> items;

  @override
  Widget build(BuildContext context) {
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
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
            Text(
              'Price',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
          ],
        ),
        Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(left: item.isMain ? 0 : 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} ${item.description}',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                    ),
                  ),
                ),
                Text(
                  item.isMain || item.grossAmount > Decimal.zero ? item.grossAmount.withCommas : '',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'VATable Sales',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
            const Spacer(),
            Text(
              vatableSales.withCommas,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
          ],
        ),
        const Gap(4),
        if (vatExemptSales > Decimal.zero) ...[
          Row(
            children: [
              Text(
                'VAT-Exempt Sales',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Spacer(),
              Text(
                vatExemptSales.withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
            ],
          ),
          const Gap(4),
        ],
        Row(
          children: [
            Text(
              'VAT',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
            const Spacer(),
            Text(
              vatAmount.withCommas,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
              ),
            ),
          ],
        ),
        const Gap(4),
        if (discountAmount > Decimal.zero) ...[
          Row(
            children: [
              Text(
                'Discount',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Spacer(),
              Text(
                (-discountAmount).withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
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
                fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              totalAmount.withCommas,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
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
    if (payment case CashPayment(:final cashReceived, :final change)) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Gap(8),
              Text(
                cashReceived.withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Gap(8),
              Text(
                change.withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
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
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Gap(8),
              Text(
                payment.paidAmount.withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
            ],
          ),
          const Gap(4),
          Center(
            child: Text(
              'Ref: $referenceNumber',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 12, tablet: 12, phone: 10),
              ),
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
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
              const Gap(8),
              Text(
                payment.paidAmount.withCommas,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                ),
              ),
            ],
          ),
          const Gap(4),
          Center(
            child: Text(
              'Ref: $referenceNumber',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 12, tablet: 12, phone: 10),
              ),
            ),
          ),
        ],
      );
    } else if (payment is ZeroPayment) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'ZERO PAYMENT',
          style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
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
              style: TextStyle(fontSize: context.responsive.value(kiosk: 10, tablet: 10, phone: 8)),
            );
          }),
        );
      },
    );
  }
}

class _PrintButton extends ConsumerWidget {
  const _PrintButton({required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReceipt = ref.watch(receiptProvider(receiptId).select((it) => it.hasValue));
    final printAction = ReceiptNotifier.printAction;
    final printStatus = ref.watch(printAction);

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showMessageDialog(context, type: DialogType.error, message: '$error');
      }
    });

    if (!hasReceipt) return const SizedBox.shrink();

    return GestureDetector(
      onTap:
          printStatus is! MutationPending
              ? () {
                printAction.run(ref, (txn) {
                  return txn.get(receiptProvider(receiptId).notifier).print();
                }).ignore();
              }
              : null,
      child: Container(
        height: context.responsive.value(kiosk: 72, tablet: 64, phone: 52),
        width: double.infinity,
        decoration: BoxDecoration(
          color: printStatus is! MutationPending ? ColorSet.secondary : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Text(
            printStatus is MutationPending
                ? 'Printing...'
                : printStatus is MutationSuccess
                ? 'Reprint'
                : 'Print Receipt',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 14),
              fontWeight: FontWeight.w600,
              color: printStatus is! MutationPending ? ColorSet.light : const Color(0xFF9E9E9E),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewOrderButton extends StatelessWidget {
  const _NewOrderButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => const SalesRoute().go(context),
      child: Container(
        height: context.responsive.value(kiosk: 72, tablet: 64, phone: 52),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: ColorSet.gradientBg,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Text(
            'New Order',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 14),
              fontWeight: FontWeight.w600,
              color: ColorSet.light,
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
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          const SalesRoute().go(context);
        }
      },
      child: Container(
        height: context.responsive.value(kiosk: 72, tablet: 64, phone: 52),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: ColorSet.danger, width: 2),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Text(
            'Close',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 14),
              fontWeight: FontWeight.w600,
              color: ColorSet.danger,
            ),
          ),
        ),
      ),
    );
  }
}
