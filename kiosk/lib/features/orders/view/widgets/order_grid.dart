import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../../entities/order_event.dart';
import '../order_format.dart';
import 'order_card.dart';

/// Main content area for the Orders screen: a header (selected fulfillment
/// type, order count, running total) above a responsive grid of order
/// cards. Replaces the old single-column list — with only one fulfillment
/// type's orders on screen at a time (see [OrderFulfillmentNav]), the full
/// window width is available, so cards wrap into as many columns as fit.
class OrderGrid extends StatelessWidget {
  const OrderGrid({
    super.key,
    required this.title,
    required this.accentColor,
    required this.events,
    required this.activeTotal,
  });

  final String title;
  final Color accentColor;
  final IList<OrderEvent> events;
  final num activeTotal;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.scale(4), 0, r.scale(4), r.scale(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: r.scale(21), fontWeight: FontWeight.w800, color: POSColors.textPrimary, letterSpacing: -0.3),
              ),
              SizedBox(width: r.scale(10)),
              Text(
                '${events.length} ${events.length == 1 ? 'order' : 'orders'}',
                style: TextStyle(fontSize: r.scale(13), fontWeight: FontWeight.w600, color: POSColors.textTertiary),
              ),
              const Spacer(),
              Text(
                'Total  ',
                style: TextStyle(fontSize: r.scale(13), fontWeight: FontWeight.w500, color: POSColors.textSecondary),
              ),
              Text(
                formatOrderMoney(activeTotal, null),
                style: TextStyle(fontSize: r.scale(15), fontWeight: FontWeight.w800, color: POSColors.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? _EmptyGrid(title: title)
              : GridView.builder(
                  padding: EdgeInsets.only(bottom: r.scale(16)),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: r.value<double>(kiosk: 280, tablet: 260, phone: 340),
                    mainAxisExtent: r.scale(178),
                    crossAxisSpacing: r.scale(14),
                    mainAxisSpacing: r.scale(14),
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) => OrderCard(event: events[index], accentColor: accentColor),
                ),
        ),
      ],
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Text(
        'No ${title == 'All' ? '' : '${title.toLowerCase()} '}orders yet',
        style: TextStyle(fontSize: r.scale(14), fontWeight: FontWeight.w500, color: POSColors.textTertiary),
      ),
    );
  }
}
