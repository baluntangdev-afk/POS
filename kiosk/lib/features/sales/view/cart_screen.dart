import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../state/ordering_notifier.dart';
import 'line_item_dialog.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.breakpoint.isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        body: SafeArea(
          child: ResponsiveBuilder(
            kiosk: (context) => const _KioskCartLayout(),
            tablet: (context) => const _DefaultCartLayout(),
            phone: (context) => const _DefaultCartLayout(),
          ),
        ),
      );
    }
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: ResponsiveBuilder(
        kiosk: (context) => const _KioskCartLayout(),
        tablet: (context) => const _DefaultCartLayout(),
        phone: (context) => const _DefaultCartLayout(),
      ),
    );
  }
}

// ── Shared flat header ────────────────────────────────────────────────────────
class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.title});

  final String title;

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
            title,
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

// ── Kiosk: side-by-side list + summary panel ──────────────────────────────────
class _KioskCartLayout extends StatelessWidget {
  const _KioskCartLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _CartHeader(title: 'Order Summary'),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _LineItemListView()),
              _CartSummaryPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Default: vertical stack ───────────────────────────────────────────────────
class _DefaultCartLayout extends StatelessWidget {
  const _DefaultCartLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CartHeader(title: 'Order Summary'),
        Expanded(child: _LineItemListView()),
        _SummaryView(),
        _DiscountButton(),
        _PaymentButton(),
      ],
    );
  }
}

// ── Right summary panel (kiosk only) ─────────────────────────────────────────
class _CartSummaryPanel extends ConsumerWidget {
  const _CartSummaryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;

    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return <({String label, Decimal amount})>[];
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

    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );

    return Container(
      width: r.value<double>(kiosk: 380, tablet: 320, phone: 280),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
              vertical: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorSet.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(POSRadius.sm),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: ColorSet.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Breakdown rows
                  ...computations.map((c) {
                    final (:label, :amount) = c;
                    final isTotal = label == 'Total';

                    if (isTotal) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                            vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                          ),
                          decoration: BoxDecoration(
                            color: ColorSet.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(POSRadius.md),
                            border: Border.all(
                              color: ColorSet.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                                  fontWeight: FontWeight.w700,
                                  color: POSColors.textPrimary,
                                ),
                              ),
                              Text(
                                amount.pesoFormatted,
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 22, tablet: 18, phone: 16),
                                  fontWeight: FontWeight.w800,
                                  color: ColorSet.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                              color: POSColors.textSecondary,
                            ),
                          ),
                          Text(
                            amount.pesoFormatted,
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                              color: POSColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Spacer(),

                  if (lineItemCount > 0) ...[
                    SizedBox(
                      height: r.value<double>(kiosk: 52, tablet: 48, phone: 44),
                      child: OutlinedButton.icon(
                        onPressed: !isLoading
                            ? () => const DiscountRoute().push<void>(context)
                            : null,
                        icon: const Icon(Icons.local_offer_outlined, size: 16),
                        label: Text(
                          'Apply Discount',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorSet.primary,
                          side: BorderSide(
                            color: ColorSet.primary.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(POSRadius.md),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                  ],

                  _ProceedButton(isLoading: isLoading, lineItemCount: lineItemCount),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProceedButton extends StatelessWidget {
  const _ProceedButton({required this.isLoading, required this.lineItemCount});

  final bool isLoading;
  final int lineItemCount;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isEnabled = !isLoading && lineItemCount > 0;
    final height = r.value<double>(kiosk: 60, tablet: 56, phone: 52);
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
            'Proceed to Payment',
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
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
          onTap: () => const PaymentRoute().push<void>(context),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Line items list ───────────────────────────────────────────────────────────
class _LineItemListView extends ConsumerWidget {
  const _LineItemListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItems = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );
    final isAndroid = context.breakpoint.isAndroid;
    final r = context.responsive;

    if (lineItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: POSColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 36,
                color: POSColors.iconSubtle,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add items from the menu to get started',
              style: TextStyle(fontSize: 14, color: POSColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
      itemCount: lineItems.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) {
        final lineItem = lineItems[index];
        final imgSize = r.value<double>(kiosk: 72, tablet: 60, phone: 52);

        final card = Container(
          constraints: BoxConstraints(
            minHeight: r.value<double>(kiosk: 90, tablet: 80, phone: 72),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            boxShadow: POSShadow.card,
          ),
          padding: EdgeInsets.all(r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product image
              Container(
                width: imgSize,
                height: imgSize,
                decoration: BoxDecoration(
                  color: ColorSet.background,
                  borderRadius: BorderRadius.circular(POSRadius.lg),
                  image: DecorationImage(
                    image: MemoryImage(lineItem.productImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${lineItem.variant.name.isNotEmpty ? "${lineItem.variant.name} " : ""}${lineItem.productName}',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                        fontWeight: FontWeight.w600,
                        color: POSColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Qty: ${lineItem.quantity}',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                        color: POSColors.textTertiary,
                      ),
                    ),
                    if (lineItem.modifiers.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lineItem.modifiers
                            .expand((m) => m.options)
                            .map((o) => o.name)
                            .join(', '),
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                          color: POSColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),

              // Price + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lineItem.grossAmount.pesoFormatted,
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                      fontWeight: FontWeight.w700,
                      color: POSColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (lineItem.discount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(orderingProvider.notifier)
                            .clearDiscount(index: index),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.value<double>(kiosk: 7, tablet: 6, phone: 5),
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorSet.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(POSRadius.xs),
                            border: Border.all(
                              color: ColorSet.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LESS: ${lineItem.discount!.code}',
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                  color: ColorSet.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.close_rounded,
                                size: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                color: ColorSet.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.edit_outlined,
                        color: ColorSet.primary,
                        size: r.value<double>(kiosk: 40, tablet: 36, phone: 32),
                        onTap: () async {
                          final updated = await showLineItemDialog(
                            context,
                            productId: lineItem.productId,
                            initialQuantity: lineItem.quantity,
                            initialVariant: lineItem.variant,
                            initialModifiers: lineItem.modifiers,
                          );
                          if (updated == null || !context.mounted) return;
                          ref
                              .read(orderingProvider.notifier)
                              .replaceLineItem(
                                updated.copyWith(id: lineItem.id),
                                index: index,
                              );
                        },
                      ),
                      SizedBox(width: r.value<double>(kiosk: 6, tablet: 5, phone: 4)),
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        color: ColorSet.danger,
                        size: r.value<double>(kiosk: 40, tablet: 36, phone: 32),
                        onTap: () {
                          ref.read(orderingProvider.notifier).removeLineItem(index: index);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        if (!isAndroid) return card;

        return Dismissible(
          key: ValueKey(lineItem.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: ColorSet.danger,
              borderRadius: BorderRadius.circular(POSRadius.xl),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          ),
          onDismissed: (_) {
            final removed = lineItem;
            ref.read(orderingProvider.notifier).removeLineItem(index: index);
            ScaffoldMessenger.of(context).clearMaterialBanners();
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: Text(
                  '${removed.productName} removed',
                  style: const TextStyle(color: POSColors.textPrimary),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearMaterialBanners();
                      ref.read(orderingProvider.notifier).addLineItem(removed);
                    },
                    child: const Text('UNDO'),
                  ),
                ],
              ),
            );
          },
          child: card,
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(POSRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(POSRadius.sm),
          onTap: onTap,
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}

// ── Summary view (tablet / phone) ─────────────────────────────────────────────
class _SummaryView extends ConsumerWidget {
  const _SummaryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return <({String label, Decimal amount})>[];
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

    final hPad = r.value<double>(kiosk: 64, tablet: 48, phone: 24);

    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
      padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        children: [
          ...computations.map((c) {
            final (:label, :amount) = c;
            final isTotal = label == 'Total';

            if (isTotal) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: POSColors.borderDefault, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                          fontWeight: FontWeight.w700,
                          color: POSColors.textPrimary,
                        ),
                      ),
                      Text(
                        amount.pesoFormatted,
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 24, tablet: 20, phone: 18),
                          fontWeight: FontWeight.w800,
                          color: ColorSet.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
          }),
        ],
      ),
    );
  }
}

// ── Discount button (tablet / phone) ─────────────────────────────────────────
class _DiscountButton extends ConsumerWidget {
  const _DiscountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );
    final hPad = r.value<double>(kiosk: 64, tablet: 48, phone: 24);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 8),
      child: SizedBox(
        height: r.value<double>(kiosk: 56, tablet: 52, phone: 48),
        child: OutlinedButton.icon(
          onPressed: !isLoading && lineItemCount > 0
              ? () => const DiscountRoute().push<void>(context)
              : null,
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: Text(
            'Apply Discount',
            style: TextStyle(fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14)),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorSet.primary,
            side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payment button (tablet / phone) ──────────────────────────────────────────
class _PaymentButton extends ConsumerWidget {
  const _PaymentButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );

    final hPad = r.value<double>(kiosk: 64, tablet: 48, phone: 24);
    final vPad = r.value<double>(kiosk: 24, tablet: 20, phone: 16);
    final height = r.value<double>(kiosk: 72, tablet: 64, phone: 56);
    final isEnabled = !isLoading && lineItemCount > 0;
    const radius = POSRadius.full;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
      child: isEnabled
          ? DecoratedBox(
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
                  onTap: () => const PaymentRoute().push<void>(context),
                  child: SizedBox(
                    height: height,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(
              height: height,
              decoration: BoxDecoration(
                color: POSColors.borderStrong,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Center(
                child: Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 15),
                    fontWeight: FontWeight.w600,
                    color: POSColors.textDisabled,
                  ),
                ),
              ),
            ),
    );
  }
}
