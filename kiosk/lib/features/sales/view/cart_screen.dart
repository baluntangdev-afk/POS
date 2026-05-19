import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/button.dart';
import '../../../widgets/windows_scaffold.dart';
import '../state/ordering_notifier.dart';
import 'line_item_dialog.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

// ── White header bar ──────────────────────────────────────────────────────────
class _CartHeader extends StatelessWidget {
  const _CartHeader();

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
            'Order Summary',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 16.0),
              fontWeight: FontWeight.w600,
              color: ColorSet.dark,
            ),
          ),
          const Spacer(),
          // Balance the back button so the title is centered
          SizedBox(
            width: context.responsive.value<double>(kiosk: 110, tablet: 90, phone: 76),
          ),
        ],
      ),
    );
  }
}

// ── Kiosk: header + Row(items | 360px summary panel) ─────────────────────────
class _KioskCartLayout extends StatelessWidget {
  const _KioskCartLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CartHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _LineItemListView()),
              const _CartSummaryPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tablet / phone: header + items + summary + buttons (vertical) ─────────────
class _DefaultCartLayout extends StatelessWidget {
  const _DefaultCartLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CartHeader(),
        const Expanded(child: _LineItemListView()),
        const _SummaryView(),
        const _DiscountButton(),
        const _PaymentButton(),
      ],
    );
  }
}

// ── Right summary panel (kiosk only, 360px) ───────────────────────────────────
class _CartSummaryPanel extends ConsumerWidget {
  const _CartSummaryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return <({String label, Decimal amount})>[];
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

    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE8E6E1))),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Order Total',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Gap(12),
          const Divider(),
          const Gap(12),
          ...computations.map((computation) {
            final (:label, :amount) = computation;
            final isTotal = label == 'Total';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTotal ? 20 : 15,
                      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w400,
                      color: isTotal ? ColorSet.dark : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    amount.pesoFormatted,
                    style: TextStyle(
                      fontSize: isTotal ? 22 : 15,
                      fontWeight: isTotal ? FontWeight.w800 : FontWeight.w400,
                      color: isTotal ? ColorSet.primary : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          if (lineItemCount > 0) ...[
            OutlinedButton(
              onPressed:
                  !isLoading ? () => const DiscountRoute().push<void>(context) : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.5)),
                foregroundColor: ColorSet.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Discount'),
            ),
            const Gap(12),
          ],
          GestureDetector(
            onTap:
                !isLoading && lineItemCount > 0
                    ? () => const PaymentRoute().push<void>(context)
                    : null,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient:
                    !isLoading && lineItemCount > 0
                        ? const LinearGradient(
                          colors: ColorSet.gradientBg,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color: lineItemCount == 0 ? const Color(0xFFE0E0E0) : null,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: lineItemCount == 0 ? const Color(0xFF9E9E9E) : Colors.white,
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

// ── Line items list ───────────────────────────────────────────────────────────
class _LineItemListView extends ConsumerWidget {
  const _LineItemListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItems = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 12.0),
        16,
        context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 12.0),
        16,
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(context.responsive.value(kiosk: 4.0, tablet: 4.0, phone: 4.0)),
        itemCount: lineItems.length,
        separatorBuilder: (context, index) => const Gap(12),
        itemBuilder: (context, index) {
          final lineItem = lineItems[index];
          return Container(
            constraints: BoxConstraints(
              minHeight: context.responsive.value(kiosk: 88.0, tablet: 80.0, phone: 72.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(
              context.responsive.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: context.responsive.value(kiosk: 80.0, tablet: 64.0, phone: 52.0),
                  height: context.responsive.value(kiosk: 80.0, tablet: 64.0, phone: 52.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorSet.background,
                    image: DecorationImage(
                      image: MemoryImage(lineItem.productImage),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Gap(context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 10.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lineItem.variant.name.isNotEmpty ? "${lineItem.variant.name} " : ""}${lineItem.productName}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Qty: ${lineItem.quantity}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (lineItem.modifiers.isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          'Add-ons: ${lineItem.modifiers.expand((modifier) => modifier.options).map((option) => option.name).join(', ')}',
                          style: TextStyle(
                            fontSize: context.responsive.value(
                              kiosk: 13.0,
                              tablet: 12.0,
                              phone: 11.0,
                            ),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Gap(context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lineItem.grossAmount.pesoFormatted,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 15.0),
                        fontWeight: FontWeight.w700,
                        color: ColorSet.secondary,
                      ),
                    ),
                    if (lineItem.discount != null)
                      Text(
                        'LESS: ${lineItem.discount!.code}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                          color: ColorSet.danger,
                        ),
                      ),
                    const Gap(8),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          onPressed: () async {
                            final updatedLineItem = await showLineItemDialog(
                              context,
                              productId: lineItem.productId,
                              initialQuantity: lineItem.quantity,
                              initialVariant: lineItem.variant,
                              initialModifiers: lineItem.modifiers,
                            );
                            if (updatedLineItem == null || !context.mounted) return;
                            ref
                                .read(orderingProvider.notifier)
                                .replaceLineItem(
                                  updatedLineItem.copyWith(id: lineItem.id),
                                  index: index,
                                );
                          },
                          size: context.responsive.value(kiosk: 52.0, tablet: 44.0, phone: 36.0),
                        ),
                        Gap(context.responsive.value(kiosk: 8.0, tablet: 6.0, phone: 4.0)),
                        _QtyButton(
                          icon: Icons.delete_outline,
                          onPressed: () {
                            ref.read(orderingProvider.notifier).removeLineItem(index: index);
                          },
                          size: context.responsive.value(kiosk: 52.0, tablet: 44.0, phone: 36.0),
                          color: ColorSet.danger,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    this.color = ColorSet.primary,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          foregroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Icon(icon, size: size * 0.4),
      ),
    );
  }
}

// ── Summary view (tablet/phone only) ─────────────────────────────────────────
class _SummaryView extends ConsumerWidget {
  const _SummaryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return <({String label, Decimal amount})>[];
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
        context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
        24,
        context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
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
                    fontSize: context.responsive.value(kiosk: 24.0, tablet: 18.0, phone: 15.0),
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w300,
                    height: 1.3,
                  ),
                ),
                const Gap(16),
                Text(
                  amount.pesoFormatted,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24.0, tablet: 18.0, phone: 15.0),
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w300,
                    color: ColorSet.secondary,
                    height: 1.3,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Discount button (tablet/phone only) ───────────────────────────────────────
class _DiscountButton extends ConsumerWidget {
  const _DiscountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );
    return Container(
      height: context.responsive.value(kiosk: 64.0, tablet: 56.0, phone: 48.0),
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
        context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 16.0),
        context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
        context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
      ),
      child: Button(
        onPressed:
            !isLoading && lineItemCount > 0
                ? () {
                  const DiscountRoute().push<void>(context);
                }
                : null,
        label: Text(
          'Apply Discount',
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
          ),
        ),
        foregroundColor: ColorSet.text,
        backgroundColor: ColorSet.light,
      ),
    );
  }
}

// ── Payment button (tablet/phone only) ────────────────────────────────────────
class _PaymentButton extends ConsumerWidget {
  const _PaymentButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );
    return GestureDetector(
      onTap:
          !isLoading && lineItemCount > 0
              ? () {
                const PaymentRoute().push<void>(context);
              }
              : null,
      child: Container(
        height: context.responsive.value(kiosk: 80.0, tablet: 64.0, phone: 52.0),
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(
          context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
          0,
          context.responsive.value(kiosk: 64.0, tablet: 48.0, phone: 24.0),
          context.responsive.value(kiosk: 32.0, tablet: 24.0, phone: 16.0),
        ),
        decoration: BoxDecoration(
          gradient:
              !isLoading && lineItemCount > 0
                  ? LinearGradient(
                    colors: [
                      ColorSet.secondary.withValues(alpha: 0.85),
                      ColorSet.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: lineItemCount == 0 ? const Color(0xFFE0E0E0) : null,
          borderRadius: BorderRadius.circular(
            context.responsive.value(kiosk: 80.0, tablet: 64.0, phone: 52.0) / 2,
          ),
        ),
        child: Center(
          child: Text(
            'Proceed to Payment',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 15.0),
              fontWeight: FontWeight.w600,
              color: lineItemCount == 0 ? const Color(0xFF9E9E9E) : ColorSet.light,
            ),
          ),
        ),
      ),
    );
  }
}
