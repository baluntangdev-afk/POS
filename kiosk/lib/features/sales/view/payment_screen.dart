import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/payment.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_dialog.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PaymentHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                context.responsive.value(kiosk: 40.0, tablet: 28.0, phone: 20.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive.value(kiosk: 860.0, tablet: 680.0, phone: 480.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _OrderTotalCard(),
                      SizedBox(
                        height: context.responsive.value(kiosk: 20.0, tablet: 16.0, phone: 12.0),
                      ),
                      const _PaymentSummaryRows(),
                      SizedBox(
                        height: context.responsive.value(kiosk: 32.0, tablet: 24.0, phone: 16.0),
                      ),
                      const _PaymentMethodGrid(),
                      SizedBox(
                        height: context.responsive.value(kiosk: 32.0, tablet: 24.0, phone: 16.0),
                      ),
                      const _ConfirmButton(),
                    ],
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

// ── White header ──────────────────────────────────────────────────────────────
class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

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
              if (context.canPop()) context.pop();
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
          const Spacer(),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 16.0),
              fontWeight: FontWeight.w600,
              color: ColorSet.dark,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: context.responsive.value<double>(kiosk: 110, tablet: 90, phone: 76),
          ),
        ],
      ),
    );
  }
}

// ── Order total card ──────────────────────────────────────────────────────────
class _OrderTotalCard extends ConsumerWidget {
  const _OrderTotalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = ref.watch(
      orderingProvider.select((it) => it.value?.sale.totalAmount ?? Decimal.zero),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.responsive.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
        horizontal: context.responsive.value(kiosk: 48.0, tablet: 36.0, phone: 24.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Order Total',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20.0, tablet: 16.0, phone: 14.0),
              color: const Color(0xFF888888),
            ),
          ),
          Gap(context.responsive.value(kiosk: 8.0, tablet: 6.0, phone: 4.0)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              totalAmount.pesoFormatted,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 72.0, tablet: 52.0, phone: 40.0),
                fontWeight: FontWeight.w900,
                color: ColorSet.primary,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── VAT summary rows ──────────────────────────────────────────────────────────
class _PaymentSummaryRows extends ConsumerWidget {
  const _PaymentSummaryRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return const <({String label, Decimal amount})>[];
        return [
          (label: 'VATable Sales', amount: sale.vatableAmount),
          if (sale.vatExemptSales > Decimal.zero) ...[
            (label: 'VAT-Exempt Sales', amount: sale.vatExemptSales),
          ],
          (label: 'VAT', amount: sale.vatAmount),
          if (sale.discountAmount > Decimal.zero) ...[
            (label: 'Discount', amount: -sale.discountAmount),
          ],
        ];
      }),
    );

    if (computations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 24.0, tablet: 18.0, phone: 12.0),
        vertical: context.responsive.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: computations.map((c) {
          final (:label, :amount) = c;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 15.0, tablet: 13.0, phone: 12.0),
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  amount.pesoFormatted,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 15.0, tablet: 13.0, phone: 12.0),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Payment method grid (3-column on kiosk, single column on phone) ───────────
class _PaymentMethodGrid extends HookConsumerWidget {
  const _PaymentMethodGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethods = useMemoized(
      () =>
          <({String image, String name, bool enabled})>[
            (image: Assets.images.svg.icPaymentCash.path, name: 'Cash Payment', enabled: true),
            (
              image: Assets.images.svg.icPaymentCard.path,
              name: 'Credit or Debit Card',
              enabled: false,
            ),
            (image: Assets.images.svg.icPaymentQr.path, name: 'E-wallet Payment', enabled: false),
          ].toIList(),
    );
    final payment = ref.watch(orderingProvider.select((it) => it.value?.sale.payment));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paymentMethods.length; i++) ...[
          if (i > 0)
            SizedBox(
              width: context.responsive.value(kiosk: 20.0, tablet: 16.0, phone: 12.0),
            ),
          Expanded(
            child: _PaymentMethodCard(
              method: paymentMethods[i],
              index: i,
              payment: payment,
              paymentMethods: paymentMethods,
              ref: ref,
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodCard extends HookConsumerWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.index,
    required this.payment,
    required this.paymentMethods,
    required this.ref,
  });

  final ({String image, String name, bool enabled}) method;
  final int index;
  final Payment? payment;
  final IList<({String image, String name, bool enabled})> paymentMethods;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final cashPayment = index == 0 && payment is CashPayment ? payment as CashPayment : null;
    final isSelected = cashPayment != null;
    final isEnabled = method.enabled && payment == null;

    return GestureDetector(
      onTap:
          isEnabled
              ? () async {
                final collectibleAmount = widgetRef.read(
                  orderingProvider.select(
                    (it) => it.value?.sale.totalAmount ?? Decimal.zero,
                  ),
                );
                final Payment? result;
                switch (index) {
                  case 0:
                    result = await showCashPaymentDialog(
                      context,
                      collectibleAmount: collectibleAmount,
                    );
                  default:
                    result = null;
                }
                if (result != null) {
                  widgetRef.read(orderingProvider.notifier).addPayment(result);
                }
              }
              : null,
      child: Opacity(
        opacity: isEnabled || isSelected ? 1.0 : 0.4,
        child: Container(
          padding: EdgeInsets.all(
            context.responsive.value(kiosk: 24.0, tablet: 18.0, phone: 14.0),
          ),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? ColorSet.primary.withValues(alpha: 0.06)
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? ColorSet.primary : const Color(0xFFDDDDDD),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                method.image,
                width: context.responsive.value(kiosk: 56.0, tablet: 44.0, phone: 36.0),
                height: context.responsive.value(kiosk: 56.0, tablet: 44.0, phone: 36.0),
              ),
              Gap(context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 10.0)),
              Text(
                method.name,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 18.0, tablet: 15.0, phone: 13.0),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? ColorSet.primary : ColorSet.dark,
                ),
                textAlign: TextAlign.center,
              ),
              if (!method.enabled)
                Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 13.0, tablet: 12.0, phone: 11.0),
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (cashPayment != null) ...[
                const Gap(8),
                Text(
                  '${cashPayment.cashReceived.pesoFormatted} | Change: ${cashPayment.change.pesoFormatted}',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 13.0, tablet: 12.0, phone: 11.0),
                    color: ColorSet.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Gap(12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? ColorSet.primary : const Color(0xFFCCCCCC),
                size: context.responsive.value(kiosk: 28.0, tablet: 24.0, phone: 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm button ────────────────────────────────────────────────────────────
class _ConfirmButton extends ConsumerWidget {
  const _ConfirmButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isLoading, :hasPayment) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, hasPayment: it.value?.sale.payment != null),
      ),
    );
    ref.listen(orderingProvider.select((it) => it.whenData((data) => data.receipt)), (_, next) {
      if (next case AsyncData(value: final receipt) when receipt != null) {
        ReceiptRoute(receipt.id).go(context);
      } else if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save sale: $error')));
      }
    });

    return GestureDetector(
      onTap:
          !isLoading && hasPayment ? () => ref.read(orderingProvider.notifier).confirmSale() : null,
      child: Container(
        height: context.responsive.value(kiosk: 72.0, tablet: 64.0, phone: 52.0),
        decoration: BoxDecoration(
          gradient:
              !isLoading && hasPayment
                  ? LinearGradient(
                    colors: [
                      ColorSet.secondary.withValues(alpha: 0.85),
                      ColorSet.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: !hasPayment ? const Color(0xFFE0E0E0) : null,
          borderRadius: BorderRadius.circular(
            context.responsive.value(kiosk: 36.0, tablet: 32.0, phone: 26.0),
          ),
        ),
        child: Center(
          child: Text(
            isLoading ? 'Processing...' : 'Confirm Payment',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 15.0),
              fontWeight: FontWeight.w600,
              color: !hasPayment ? const Color(0xFF9E9E9E) : ColorSet.light,
            ),
          ),
        ),
      ),
    );
  }
}
