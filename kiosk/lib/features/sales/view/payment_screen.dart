import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/payment.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_dialog.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;
    final body = Column(
      children: [
        TopAppBar(title: 'Payment Method'),
        const Expanded(child: _PaymentMethodListView()),
        const _SummaryView(),
        const _ConfirmButton(),
      ],
    );
    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _PaymentMethodListView extends HookConsumerWidget {
  const _PaymentMethodListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethods = useMemoized(
      () => <({String image, String name, bool enabled})>[
        (image: Assets.images.svg.icPaymentCash.path, name: 'Cash Payment', enabled: true),
        (image: Assets.images.svg.icPaymentCard.path, name: 'Credit or Debit Card', enabled: false),
        (image: Assets.images.svg.icPaymentQr.path, name: 'E-wallet Payment', enabled: false),
      ].toIList(),
    );
    final selectedMethod = useState(paymentMethods.first);
    final payment = ref.watch(orderingProvider.select((it) => it.value?.sale.payment));
    final r = context.responsive;

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.fromLTRB(r.hPagePadding, r.spacingMd, r.hPagePadding, 0),
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
        padding: EdgeInsets.all(r.spacingLg),
        itemCount: paymentMethods.length,
        separatorBuilder: (context, index) => Gap(r.spacingLg),
        itemBuilder: (context, index) {
          final method = paymentMethods[index];
          final isEnabled = method.enabled && payment == null;
          final cashPayment = index == 0 && payment is CashPayment ? payment : null;
          return GestureDetector(
            onTap: isEnabled
                ? () async {
                    selectedMethod.value = method;
                    final collectibleAmount = ref.read(
                      orderingProvider.select(
                          (it) => it.value?.sale.totalAmount ?? Decimal.zero),
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
                  vertical: r.spacingLg,
                  horizontal: r.spacingLg,
                ),
                decoration: BoxDecoration(
                  color: cashPayment != null ? const Color(0xFFF2FCFF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cashPayment != null
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
                      method.image,
                      width: r.value(kiosk: 50.0, tablet: 40.0, phone: 30.0),
                    ),
                    Gap(r.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: TextStyle(
                              fontSize: r.fontLg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!method.enabled)
                            Text(
                              'Coming soon',
                              style: TextStyle(
                                fontSize: r.fontSm,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (cashPayment != null)
                            Padding(
                              padding: EdgeInsets.only(top: r.spacingSm),
                              child: Text(
                                '${cashPayment.cashReceived.pesoFormatted} | Change: ${cashPayment.change.pesoFormatted}',
                                style: TextStyle(
                                  fontSize: r.fontBody,
                                  color: ColorSet.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      cashPayment != null
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: cashPayment != null
                          ? ColorSet.secondary
                          : ColorSet.dark.withValues(alpha: 0.2),
                      size: r.iconSm,
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
          if (sale.vatExemptSales > Decimal.zero)
            (label: 'VAT-Exempt Sales', amount: sale.vatExemptSales),
          (label: 'VAT', amount: sale.vatAmount),
          if (sale.discountAmount > Decimal.zero)
            (label: 'Discount', amount: -sale.discountAmount),
          (label: 'Total', amount: sale.totalAmount),
        ];
      }),
    );
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.hButtonMargin, r.spacingLg, r.hButtonMargin, 0),
      child: Column(
        children: computations.map((comp) {
          final isTotal = comp.label == 'Total';
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  comp.label,
                  style: TextStyle(
                    fontSize: r.fontLg,
                    fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300,
                    height: 1.25,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(16),
              Text(
                comp.amount.pesoFormatted,
                style: TextStyle(
                  fontSize: r.fontLg,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300,
                  color: ColorSet.secondary,
                  height: 1.25,
                ),
              ),
            ],
          );
        }).toList(),
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

    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.hButtonMargin, r.spacingLg, r.hButtonMargin, r.spacingLg),
      child: GradientButton(
        label: isLoading ? 'Processing...' : 'Confirm',
        isLoading: isLoading,
        onPressed: !isLoading && hasPayment
            ? () => ref.read(orderingProvider.notifier).confirmSale()
            : null,
      ),
    );
  }
}
