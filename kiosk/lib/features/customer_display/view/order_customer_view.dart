import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../entities/customer_display_catalog.dart';
import '../entities/customer_display_snapshot.dart';
import 'customer_display_header.dart';
import 'menu_showcase.dart';

const _tealDeeper = Color(0xFF0A363E);

class OrderCustomerView extends StatelessWidget {
  const OrderCustomerView({super.key, required this.snapshot, required this.catalog});

  final CustomerDisplayOrdering snapshot;
  final CustomerDisplayCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ColorSet.background,
      child: Column(
        children: [
          CustomerDisplayHeader(
            storeName: catalog?.storeName ?? '',
            storeLogoUrl: catalog?.storeLogoUrl,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 62,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFFE4E1D9))),
                    ),
                    child: MenuShowcase(categories: catalog?.categories ?? const [], compact: true),
                  ),
                ),
                Expanded(
                  flex: 38,
                  child: _OrderPanel(snapshot: snapshot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  const _OrderPanel({required this.snapshot});

  final CustomerDisplayOrdering snapshot;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _tealDeeper,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(POSSpacing.lg, POSSpacing.lg, POSSpacing.lg, POSSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOUR ORDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                _LivePill(),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: POSSpacing.lg),
              itemCount: snapshot.items.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: POSSpacing.lg),
              itemBuilder: (context, index) {
                final item = snapshot.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}×',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ColorSet.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.variantLabel != null && item.variantLabel != 'Regular'
                                ? '${item.productName} (${item.variantLabel})'
                                : item.productName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        Text(
                          item.lineTotal.pesoFormatted,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                    if (item.discountAmount > Decimal.zero) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 12, color: ColorSet.secondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.discountLabel ?? 'Discount',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: ColorSet.secondary,
                                ),
                              ),
                            ),
                            Text(
                              '-${item.discountAmount.pesoFormatted}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ColorSet.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(color: Colors.black26),
            child: Padding(
              padding: const EdgeInsets.all(POSSpacing.lg),
              child: Column(
                children: [
                  _TotalsRow(label: 'Subtotal', amount: snapshot.subtotal),
                  if (snapshot.discount > Decimal.zero)
                    _TotalsRow(label: 'Discount', amount: -snapshot.discount),
                  if (snapshot.tax > Decimal.zero) _TotalsRow(label: 'Tax', amount: snapshot.tax),
                  const Divider(color: Colors.white24, height: POSSpacing.lg),
                  _TotalsRow(label: 'Total', amount: snapshot.total, emphasize: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: ColorSet.secondary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.label, required this.amount, this.emphasize = false});

  final String label;
  final Decimal amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasize ? 22 : 13,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
      color: emphasize ? Colors.white : Colors.white.withValues(alpha: 0.72),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: POSSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(amount.pesoFormatted, style: style),
        ],
      ),
    );
  }
}
