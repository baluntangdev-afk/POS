import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      backgroundColor: ColorSet.background,
      body: const Column(
        children: [
          Expanded(child: _LineItemListView()),
          _SummaryView(),
          _DiscountButton(),
          _PaymentButton(),
        ],
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
              'Order Summary',
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
        padding: EdgeInsets.all(context.responsive.value(kiosk: 20, tablet: 16, phone: 12)),
        itemCount: lineItems.length,
        separatorBuilder:
            (context, index) => Divider(
              height: context.responsive.value(kiosk: 30, tablet: 20, phone: 16),
              thickness: 0.5,
            ),
        itemBuilder: (context, index) {
          final lineItem = lineItems[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.responsive.value(kiosk: 90, tablet: 72, phone: 56),
                height: context.responsive.value(kiosk: 90, tablet: 72, phone: 56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorSet.background,
                  image: DecorationImage(
                    image: MemoryImage(lineItem.productImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lineItem.variant.name.isNotEmpty ? "${lineItem.variant.name} " : ""}${lineItem.productName}',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 30, tablet: 20, phone: 14),
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Qty: ${lineItem.quantity}',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                        fontWeight: FontWeight.normal,
                        color: ColorSet.text.withValues(alpha: 0.5),
                      ),
                    ),
                    if (lineItem.modifiers.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        'Add-ons: ${lineItem.modifiers.expand((modifier) => modifier.options).map((option) => option.name).join(', ')}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                          fontWeight: FontWeight.normal,
                          color: ColorSet.text.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
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
                                  fontSize: context.responsive.value(
                                    kiosk: 36,
                                    tablet: 24,
                                    phone: 16,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: ColorSet.secondary,
                                ),
                              ),
                              if (lineItem.discount != null)
                                Text(
                                  'LESS: ${lineItem.discount!.code}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 16,
                                      tablet: 14,
                                      phone: 10,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: ColorSet.danger,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Button(
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
                                      updatedLineItem.copyWith(
                                        id: lineItem.id, // Retain id
                                      ),
                                      index: index,
                                    );
                              },
                              backgroundColor: const Color(0xFF377FEB),
                              foregroundColor: ColorSet.light,
                              label: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive.value(
                                    kiosk: 16,
                                    tablet: 12,
                                    phone: 8,
                                  ),
                                  vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                                ),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            Gap(context.responsive.value(kiosk: 8, tablet: 8, phone: 4)),
                            Button(
                              onPressed: () {
                                ref.read(orderingProvider.notifier).removeLineItem(index: index);
                              },
                              backgroundColor: ColorSet.danger,
                              foregroundColor: ColorSet.light,
                              label: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive.value(
                                    kiosk: 16,
                                    tablet: 12,
                                    phone: 8,
                                  ),
                                  vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                                ),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
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
                    fontSize: context.responsive.value(kiosk: 36, tablet: 24, phone: 18),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ).copyWith(fontWeight: isTotal ? FontWeight.w600 : FontWeight.w300),
                ),
                const Gap(16),
                Text(
                  amount.pesoFormatted,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 36, tablet: 24, phone: 18),
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
      height: context.responsive.value(kiosk: 64, tablet: 56, phone: 48),
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
        context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
        context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
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
            fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
            fontWeight: FontWeight.normal,
          ),
        ),
        foregroundColor: ColorSet.text,
        backgroundColor: ColorSet.light,
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
    return GestureDetector(
      onTap:
          !isLoading && lineItemCount > 0
              ? () {
                const PaymentRoute().push<void>(context);
              }
              : null,
      child: Container(
        height: context.responsive.value(kiosk: 64, tablet: 56, phone: 48),
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(
          context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
          0,
          context.responsive.value(kiosk: 64, tablet: 48, phone: 24),
          context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
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
            context.responsive.value(kiosk: 64, tablet: 56, phone: 48) / 2,
          ),
        ),
        child: Center(
          child: Text(
            'Proceed to Payment',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
              fontWeight: FontWeight.normal,
              color: lineItemCount == 0 ? const Color(0xFF9E9E9E) : ColorSet.light,
            ),
          ),
        ),
      ),
    );
  }
}
