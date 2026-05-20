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
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/payment.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_dialog.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;
    final r = context.responsive;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PaymentHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.value<double>(kiosk: 40, tablet: 28, phone: 20)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: r.value<double>(kiosk: 860, tablet: 680, phone: 480),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _OrderTotalCard(),
                    SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
                    const _PaymentSummaryRows(),
                    SizedBox(height: r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
                    const _PaymentMethodGrid(),
                    SizedBox(height: r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
                    const _ConfirmButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isAndroid) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cancel Payment?'),
              content: const Text(
                'Going back will cancel the current payment selection.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Stay'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
                  child: const Text('Cancel Payment'),
                ),
              ],
            ),
          );
          if ((confirmed ?? false) && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: AndroidScaffold(
          backgroundColor: ColorSet.background,
          body: SafeArea(child: body),
        ),
      );
    }

    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 68, tablet: 60, phone: 52);
    final btnH = r.value<double>(kiosk: 44, tablet: 40, phone: 36);

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 24, tablet: 16, phone: 12),
      ),
      child: Row(
        children: [
          SizedBox(
            height: btnH,
            child: OutlinedButton.icon(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
              ),
              label: Text(
                'Back',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.6), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 20, tablet: 17, phone: 15),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          SizedBox(width: r.value<double>(kiosk: 90, tablet: 76, phone: 64)),
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
    final r = context.responsive;
    final totalAmount = ref.watch(
      orderingProvider.select((it) => it.value?.sale.totalAmount ?? Decimal.zero),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accent top stripe
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: ColorSet.gradientBg,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: r.value<double>(kiosk: 28, tablet: 22, phone: 18),
              horizontal: r.value<double>(kiosk: 48, tablet: 36, phone: 24),
            ),
            child: Column(
              children: [
                Text(
                  'Order Total',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 13, phone: 12),
                    color: POSColors.textTertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    totalAmount.pesoFormatted,
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 72, tablet: 52, phone: 40),
                      fontWeight: FontWeight.w900,
                      color: ColorSet.primary,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── VAT breakdown rows ────────────────────────────────────────────────────────
class _PaymentSummaryRows extends ConsumerWidget {
  const _PaymentSummaryRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
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
        ];
      }),
    );

    if (computations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 24, tablet: 18, phone: 14),
        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
      ),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.lg),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Column(
        children: computations.map((c) {
          final (:label, :amount) = c;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                    color: POSColors.textSecondary,
                  ),
                ),
                Text(
                  amount.pesoFormatted,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                    color: POSColors.textSecondary,
                    fontWeight: FontWeight.w500,
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

// ── Payment method grid ───────────────────────────────────────────────────────
class _PaymentMethodGrid extends HookConsumerWidget {
  const _PaymentMethodGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final paymentMethods = useMemoized(
      () => <({String image, String name, bool enabled})>[
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
            fontWeight: FontWeight.w700,
            color: POSColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < paymentMethods.length; i++) ...[
              if (i > 0)
                SizedBox(width: r.value<double>(kiosk: 16, tablet: 12, phone: 10)),
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
        ),
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
    final isHovered = useState(false);
    final r = context.responsive;

    final CashPayment? cashPayment =
        index == 0 && payment is CashPayment ? payment as CashPayment : null;
    final isSelected = cashPayment != null;
    final isEnabled = method.enabled && payment == null;

    Future<void> onTap() async {
      final collectibleAmount = widgetRef.read(
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
        widgetRef.read(orderingProvider.notifier).addPayment(result);
      }
    }

    final accent = isSelected ? ColorSet.primary : POSColors.borderDefault;

    return Opacity(
      opacity: isEnabled || isSelected ? 1.0 : 0.45,
      child: MouseRegion(
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: AnimatedContainer(
          duration: POSAnimation.normal,
          decoration: BoxDecoration(
            color: isSelected
                ? ColorSet.primary.withValues(alpha: 0.06)
                : isHovered.value && isEnabled
                    ? POSColors.surfaceSubtle
                    : Colors.white,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            border: Border.all(
              color: isSelected
                  ? ColorSet.primary
                  : isHovered.value && isEnabled
                      ? ColorSet.primary.withValues(alpha: 0.3)
                      : POSColors.borderDefault,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ColorSet.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : POSShadow.card,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(POSRadius.xl),
              onTap: isEnabled ? onTap : null,
              child: Padding(
                padding: EdgeInsets.all(
                  r.value<double>(kiosk: 24, tablet: 18, phone: 14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container
                    AnimatedContainer(
                      duration: POSAnimation.normal,
                      width: r.value<double>(kiosk: 72, tablet: 60, phone: 50),
                      height: r.value<double>(kiosk: 72, tablet: 60, phone: 50),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorSet.primary.withValues(alpha: 0.1)
                            : POSColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(POSRadius.lg),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          method.image,
                          width: r.value<double>(kiosk: 40, tablet: 32, phone: 28),
                          height: r.value<double>(kiosk: 40, tablet: 32, phone: 28),
                          colorFilter: isSelected
                              ? const ColorFilter.mode(
                                  ColorSet.primary,
                                  BlendMode.srcIn,
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 15, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorSet.primary : POSColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!method.enabled) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: POSColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(POSRadius.full),
                        ),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                            color: POSColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                    if (cashPayment != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ColorSet.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(POSRadius.sm),
                        ),
                        child: Text(
                          '${cashPayment.cashReceived.pesoFormatted} | Change: ${cashPayment.change.pesoFormatted}',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                            color: ColorSet.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                    AnimatedContainer(
                      duration: POSAnimation.fast,
                      width: r.value<double>(kiosk: 28, tablet: 24, phone: 20),
                      height: r.value<double>(kiosk: 28, tablet: 24, phone: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? ColorSet.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? ColorSet.primary : POSColors.borderStrong,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
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
    final r = context.responsive;
    final (:isLoading, :hasPayment) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, hasPayment: it.value?.sale.payment != null),
      ),
    );

    ref.listen(orderingProvider.select((it) => it.whenData((data) => data.receipt)), (_, next) {
      if (next case AsyncData(value: final receipt) when receipt != null) {
        ReceiptRoute(receipt.id).go(context);
      } else if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save sale: $error')),
        );
      }
    });

    final isEnabled = !isLoading && hasPayment;
    final height = r.value<double>(kiosk: 72, tablet: 64, phone: 56);
    const radius = POSRadius.full;

    if (!isEnabled) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: POSColors.borderStrong,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Text(
            'Confirm Payment',
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 15),
              fontWeight: FontWeight.w600,
              color: POSColors.textDisabled,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: ColorSet.gradientBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: POSShadow.button,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: isLoading
              ? null
              : () => ref.read(orderingProvider.notifier).confirmSale(),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  isLoading ? 'Processing...' : 'Confirm Payment',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 15),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
