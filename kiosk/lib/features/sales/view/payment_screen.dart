import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/payment_method_entry_dto.dart';
import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../../menu/state/pos_terminal_notifier.dart';
import '../entities/payment.dart';
import '../state/ordering_notifier.dart';
import 'cash_payment_dialog.dart';
import 'reference_payment_dialog.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ref.read(orderingProvider.notifier).clearPayment();
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
class _PaymentHeader extends ConsumerWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (context.canPop()) {
                  ref.read(orderingProvider.notifier).clearPayment();
                  context.pop();
                }
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
              gradient: LinearGradient(colors: ColorSet.gradientBg),
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
class _PaymentMethodGrid extends ConsumerWidget {
  const _PaymentMethodGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final terminalAsync = ref.watch(posTerminalProvider);
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
        terminalAsync.when(
          loading: () => SizedBox(
            height: r.value<double>(kiosk: 160, tablet: 140, phone: 120),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SizedBox(
            height: r.value<double>(kiosk: 100, tablet: 90, phone: 80),
            child: Center(
              child: Text(
                'Unable to load payment methods.',
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                  color: POSColors.textSecondary,
                ),
              ),
            ),
          ),
          data: (terminal) {
            final methods = terminal.paymentMethods;
            if (methods.isEmpty) {
              return SizedBox(
                height: r.value<double>(kiosk: 100, tablet: 90, phone: 80),
                child: Center(
                  child: Text(
                    'No payment methods configured for this terminal.',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      color: POSColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            final spacing = r.value<double>(kiosk: 12, tablet: 10, phone: 8);
            return Column(
              children: [
                for (int i = 0; i < methods.length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  _PaymentMethodCard(
                    entry: methods[i],
                    payment: payment,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends HookConsumerWidget {
  const _PaymentMethodCard({
    required this.entry,
    required this.payment,
  });

  final PaymentMethodEntryDto entry;
  final Payment? payment;

  bool get _isCash => entry.paymentMethod == 'Cash';
  bool get _isCard => entry.paymentMethod == 'Credit Card';

  String get _displayName =>
      (entry.paymentMethodName?.isNotEmpty ?? false)
          ? entry.paymentMethodName!
          : switch (entry.paymentMethod) {
            'Cash' => 'Cash Payment',
            'Credit Card' => 'Credit / Debit Card',
            'GCash' => 'E-wallet / GCash',
            _ => entry.paymentMethod,
          };

  String get _iconPath => switch (entry.paymentMethod) {
    'Cash' => Assets.images.svg.icPaymentCash.path,
    'Credit Card' => Assets.images.svg.icPaymentCard.path,
    _ => Assets.images.svg.icPaymentQr.path,
  };

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final isHovered = useState(false);
    final r = context.responsive;

    final p = payment; // local copy so Dart can promote the nullable type
    final cashPayment = _isCash && p is CashPayment ? p : null;
    final cardPayment = _isCard && p is CardPayment ? p : null;
    final qrPayment = !_isCash && !_isCard && p is QRPayment && p.walletProvider == entry.paymentMethod ? p : null;
    final isSelected = cashPayment != null || cardPayment != null || qrPayment != null;
    final isEnabled = payment == null || isSelected;

    Future<void> onTap() async {
      final collectibleAmount = widgetRef.read(
        orderingProvider.select((it) => it.value?.sale.totalAmount ?? Decimal.zero),
      );
      final Payment? result;
      if (_isCash) {
        result = await showCashPaymentDialog(
          context,
          collectibleAmount: collectibleAmount,
          initialCashReceived: cashPayment?.cashReceived,
        );
      } else {
        result = await showReferencePaymentDialog(
          context,
          entry: entry,
          collectibleAmount: collectibleAmount,
        );
      }
      if (result != null) {
        widgetRef.read(orderingProvider.notifier).addPayment(result);
      }
    }

    final iconSize = r.value<double>(kiosk: 56, tablet: 48, phone: 40);
    final iconInner = r.value<double>(kiosk: 32, tablet: 26, phone: 22);
    final radioSize = r.value<double>(kiosk: 26, tablet: 22, phone: 20);

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
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 20, tablet: 16, phone: 14),
                  vertical: r.value<double>(kiosk: 18, tablet: 14, phone: 12),
                ),
                child: Row(
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: POSAnimation.normal,
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorSet.primary.withValues(alpha: 0.1)
                            : POSColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(POSRadius.lg),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          _iconPath,
                          width: iconInner,
                          height: iconInner,
                          colorFilter: isSelected
                              ? const ColorFilter.mode(ColorSet.primary, BlendMode.srcIn)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                    // Labels
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayName,
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                              fontWeight: FontWeight.w600,
                              color: isSelected ? ColorSet.primary : POSColors.textPrimary,
                            ),
                          ),
                          if (entry.paymentNumber?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.paymentNumber!,
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: POSColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (cashPayment != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${cashPayment.cashReceived.pesoFormatted}  ·  Change: ${cashPayment.change.pesoFormatted}',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: ColorSet.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (cardPayment != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ref: ${cardPayment.referenceNumber}  ·  ****${cardPayment.cardNumber}',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: ColorSet.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (qrPayment != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Ref: ${qrPayment.referenceNumber}',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                color: ColorSet.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                    // Radio indicator
                    AnimatedContainer(
                      duration: POSAnimation.fast,
                      width: radioSize,
                      height: radioSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? ColorSet.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? ColorSet.primary : POSColors.borderStrong,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
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
        ReceiptRoute(receipt.id, autoPrint: true).go(context);
      } else if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(context, error: error);
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
