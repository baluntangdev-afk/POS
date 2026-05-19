import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/line_item.dart';
import '../state/ordering_notifier.dart';
import 'line_item_dialog.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAndroid = context.breakpoint.isAndroid;
    final body = Column(
      children: [
        TopAppBar(title: 'Order Summary'),
        const Expanded(child: _LineItemListView()),
        const _SummaryView(),
        const _DiscountButton(),
        const _PaymentButton(),
      ],
    );
    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _LineItemListView extends ConsumerWidget {
  const _LineItemListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItems = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );
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
        itemCount: lineItems.length,
        separatorBuilder: (context, index) => Divider(
          height: r.spacingLg,
          thickness: 0.5,
        ),
        itemBuilder: (context, index) {
          final lineItem = lineItems[index];
          return _LineItemRow(lineItem: lineItem, index: index);
        },
      ),
    );
  }
}

class _LineItemRow extends ConsumerWidget {
  const _LineItemRow({required this.lineItem, required this.index});

  final LineItem lineItem;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: r.value(kiosk: 90.0, tablet: 72.0, phone: 56.0),
          height: r.value(kiosk: 90.0, tablet: 72.0, phone: 56.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorSet.background,
            image: DecorationImage(
              image: MemoryImage(lineItem.productImage),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Gap(r.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lineItem.variant.name.isNotEmpty ? "${lineItem.variant.name} " : ""}${lineItem.productName}',
                style: TextStyle(fontSize: r.fontMd),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Qty: ${lineItem.quantity}',
                style: TextStyle(fontSize: r.fontSm, color: ColorSet.text.withValues(alpha: 0.5)),
              ),
              if (lineItem.modifiers.isNotEmpty) ...[
                const Gap(4),
                Text(
                  'Add-ons: ${lineItem.modifiers.expand((m) => m.options).map((o) => o.name).join(', ')}',
                  style: TextStyle(fontSize: r.fontSm, color: ColorSet.text.withValues(alpha: 0.5)),
                ),
              ],
              Gap(r.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineItem.grossAmount.pesoFormatted,
                          style: TextStyle(
                            fontSize: r.fontLg,
                            fontWeight: FontWeight.w600,
                            color: ColorSet.secondary,
                          ),
                        ),
                        if (lineItem.discount != null)
                          Text(
                            'LESS: ${lineItem.discount!.code}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: r.fontCaption,
                              color: ColorSet.danger,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ItemActionButton(
                        label: 'Edit',
                        color: const Color(0xFF377FEB),
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
                      ),
                      Gap(r.spacingSm),
                      _ItemActionButton(
                        label: 'Delete',
                        color: ColorSet.danger,
                        onPressed: () =>
                            ref.read(orderingProvider.notifier).removeLineItem(index: index),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemActionButton extends StatelessWidget {
  const _ItemActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: ColorSet.light,
        padding: EdgeInsets.symmetric(
          horizontal: r.spacingMd,
          vertical: r.spacingSm,
        ),
        minimumSize: Size(0, r.value(kiosk: 40.0, tablet: 34.0, phone: 28.0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(fontSize: r.fontSm)),
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

class _DiscountButton extends ConsumerWidget {
  const _DiscountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.hButtonMargin, r.spacingLg, r.hButtonMargin, r.spacingMd),
      child: GradientButton.solid(
        label: 'Apply Discount',
        backgroundColor: ColorSet.light,
        foregroundColor: ColorSet.text,
        onPressed: !isLoading && lineItemCount > 0
            ? () => const DiscountRoute().push<void>(context)
            : null,
      ),
    );
  }
}

class _PaymentButton extends ConsumerWidget {
  const _PaymentButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.hButtonMargin, 0, r.hButtonMargin, r.spacingLg),
      child: GradientButton(
        label: 'Proceed to Payment',
        onPressed: !isLoading && lineItemCount > 0
            ? () => const PaymentRoute().push<void>(context)
            : null,
      ),
    );
  }
}
