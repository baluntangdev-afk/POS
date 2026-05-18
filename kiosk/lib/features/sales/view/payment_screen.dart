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
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/payment.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_dialog.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowsScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      backgroundColor: ColorSet.background,
      body: const Column(
        children: [Expanded(child: _PaymentMethodListView()), _SummaryView(), _ConfirmButton()],
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
      child: Row(
        children: [
          Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_ios,
              color: ColorSet.light,
              size: context.responsive.value(kiosk: 48, tablet: 32, phone: 24),
            ),
          ),
          Expanded(
            child: Text(
              'Payment Method',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 36, tablet: 28, phone: 20),
                fontWeight: FontWeight.w600,
                color: ColorSet.light,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Gap(context.responsive.value(kiosk: 80, tablet: 56, phone: 40)),
        ],
      ),
    );
  }
}

class _PaymentMethodListView extends HookConsumerWidget {
  const _PaymentMethodListView();

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
    final selectedMethod = useState(paymentMethods.first);
    final payment = ref.watch(orderingProvider.select((it) => it.value?.sale.payment));

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        16,
        context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        itemCount: paymentMethods.length,
        separatorBuilder:
            (context, index) => Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 12)),
        itemBuilder: (context, index) {
          final paymentMethod = paymentMethods[index];
          final isEnabled = paymentMethod.enabled && payment == null;
          final cashPayment = index == 0 && payment is CashPayment ? payment : null;
          return GestureDetector(
            onTap:
                isEnabled
                    ? () async {
                      selectedMethod.value = paymentMethod;
                      final collectibleAmount = ref.read(
                        orderingProvider.select((it) => it.value?.sale.totalAmount ?? Decimal.zero),
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
                        ref.read(orderingProvider.notifier).addPayment(result);
                      }
                    }
                    : null,
            child: Opacity(
              opacity: isEnabled || cashPayment != null ? 1.0 : 0.4,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                  horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                ),
                decoration: BoxDecoration(
                  color: cashPayment != null ? const Color(0xFFF2FCFF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        cashPayment != null
                            ? ColorSet.secondary
                            : ColorSet.dark.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      paymentMethod.image,
                      width: context.responsive.value(kiosk: 50, tablet: 40, phone: 30),
                    ),
                    Gap(context.responsive.value(kiosk: 20, tablet: 16, phone: 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paymentMethod.name,
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 36, tablet: 24, phone: 18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!paymentMethod.enabled)
                            Text(
                              'Coming soon',
                              style: TextStyle(
                                fontSize: context.responsive.value(
                                  kiosk: 20,
                                  tablet: 16,
                                  phone: 12,
                                ),
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (cashPayment != null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                              ),
                              child: Text(
                                '${cashPayment.cashReceived.pesoFormatted} | Change: ${cashPayment.change.pesoFormatted}',
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 22,
                                    tablet: 16,
                                    phone: 13,
                                  ),
                                  color: ColorSet.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      cashPayment != null ? Icons.check_circle : Icons.radio_button_unchecked,
                      color:
                          cashPayment != null
                              ? ColorSet.secondary
                              : ColorSet.dark.withValues(alpha: 0.2),
                      size: context.responsive.value(kiosk: 28, tablet: 24, phone: 20),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView();

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
          (label: 'Total', amount: sale.totalAmount),
        ];
      }),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
        32,
        context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
        0,
      ),
      child: Column(
        children: [
          ...computations.map((computation) {
            final (:label, :amount) = computation;
            final isTotal = label == 'Total';
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 32, tablet: 24, phone: 18),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ).copyWith(fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300),
                ),
                const Gap(16),
                Text(
                  amount.pesoFormatted,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 32, tablet: 24, phone: 18),
                    fontWeight: FontWeight.w600,
                    color: ColorSet.secondary,
                    height: 1.25,
                  ).copyWith(fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

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
        showNetworkErrorDialog(context, error: error);
      }
    });
    return GestureDetector(
      onTap:
          !isLoading && hasPayment ? () => ref.read(orderingProvider.notifier).confirmSale() : null,
      child: Container(
        height: context.responsive.value(kiosk: 64, tablet: 56, phone: 48),
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(
          context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
          32,
          context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
          32,
        ),
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
            context.responsive.value(kiosk: 64, tablet: 56, phone: 48) / 2,
          ),
        ),
        child: Center(
          child: Text(
            isLoading ? 'Processing...' : 'Confirm',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
              fontWeight: FontWeight.normal,
              color: !hasPayment ? const Color(0xFF9E9E9E) : ColorSet.light,
            ),
          ),
        ),
      ),
    );
  }
}
