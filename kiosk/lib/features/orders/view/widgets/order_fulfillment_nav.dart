import 'package:flutter/material.dart';

import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../order_fulfillment_spec.dart';

/// Left sidebar (kiosk/tablet) or horizontal chip row (phone) listing every
/// visible [OrderFulfillmentSpec], with a count badge per item. Selecting one
/// drives which orders [OrderGrid] shows.
class OrderFulfillmentNav extends StatelessWidget {
  const OrderFulfillmentNav({
    super.key,
    required this.specs,
    required this.counts,
    required this.selected,
    required this.onSelect,
    required this.vertical,
  });

  final List<OrderFulfillmentSpec> specs;
  final Map<OrdersFilter, int> counts;
  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelect;

  /// True for the sidebar layout (kiosk/tablet); false for the horizontal
  /// chip-row layout used on phone-sized windows.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) return _VerticalNav(specs: specs, counts: counts, selected: selected, onSelect: onSelect);
    return _HorizontalNav(specs: specs, counts: counts, selected: selected, onSelect: onSelect);
  }
}

class _VerticalNav extends StatelessWidget {
  const _VerticalNav({required this.specs, required this.counts, required this.selected, required this.onSelect});

  final List<OrderFulfillmentSpec> specs;
  final Map<OrdersFilter, int> counts;
  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final width = r.value<double>(kiosk: 232, tablet: 196);

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: r.scale(12), horizontal: r.scale(10)),
      decoration: const BoxDecoration(
        color: POSColors.surfaceElevated,
        border: Border(right: BorderSide(color: POSColors.borderDefault)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(r.scale(10), r.scale(6), r.scale(10), r.scale(10)),
            child: Text(
              'FULFILLMENT',
              style: TextStyle(
                fontSize: r.scale(11),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: POSColors.textTertiary,
              ),
            ),
          ),
          for (final spec in specs)
            Padding(
              padding: EdgeInsets.only(bottom: r.scale(4)),
              child: _NavTile(
                spec: spec,
                count: counts[spec.filter] ?? 0,
                active: spec.filter == selected,
                onTap: () => onSelect(spec.filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.spec, required this.count, required this.active, required this.onTap});

  final OrderFulfillmentSpec spec;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final accent = spec.accentColor;
    final iconBoxSize = r.scale(30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(POSRadius.md),
        child: Stack(
          children: [
            if (active)
              Positioned(
                left: 0,
                top: r.scale(8),
                bottom: r.scale(8),
                child: Container(width: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(11)),
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(POSRadius.md),
              ),
              child: Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: active ? accent.withValues(alpha: 0.16) : POSColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(spec.icon, size: r.scale(16), color: active ? accent : POSColors.textTertiary),
                  ),
                  SizedBox(width: r.scale(10)),
                  Expanded(
                    child: Text(
                      spec.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.scale(14),
                        fontWeight: FontWeight.w600,
                        color: active ? accent : POSColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: r.scale(6)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(2)),
                    decoration: BoxDecoration(
                      color: active ? accent.withValues(alpha: 0.16) : POSColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: r.scale(11.5),
                        fontWeight: FontWeight.w700,
                        color: active ? accent : POSColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal, scrollable chip row for phone-sized windows — a fixed-width
/// sidebar would eat too much of a narrow screen to leave room for the
/// order grid.
class _HorizontalNav extends StatelessWidget {
  const _HorizontalNav({required this.specs, required this.counts, required this.selected, required this.onSelect});

  final List<OrderFulfillmentSpec> specs;
  final Map<OrdersFilter, int> counts;
  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Container(
      padding: EdgeInsets.symmetric(vertical: r.scale(10)),
      decoration: const BoxDecoration(
        color: POSColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.scale(12)),
        child: Row(
          children: [
            for (final spec in specs) ...[
              _NavChip(
                spec: spec,
                count: counts[spec.filter] ?? 0,
                active: spec.filter == selected,
                onTap: () => onSelect(spec.filter),
              ),
              SizedBox(width: r.scale(8)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.spec, required this.count, required this.active, required this.onTap});

  final OrderFulfillmentSpec spec;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final accent = spec.accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(POSRadius.full),
        child: Container(
          constraints: BoxConstraints(minHeight: r.scale(40)),
          padding: EdgeInsets.symmetric(horizontal: r.scale(14), vertical: r.scale(8)),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : POSColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(POSRadius.full),
            border: Border.all(color: active ? accent.withValues(alpha: 0.4) : POSColors.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: r.scale(15), color: active ? accent : POSColors.textTertiary),
              SizedBox(width: r.scale(6)),
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: r.scale(13),
                  fontWeight: FontWeight.w600,
                  color: active ? accent : POSColors.textSecondary,
                ),
              ),
              SizedBox(width: r.scale(6)),
              Text(
                '$count',
                style: TextStyle(fontSize: r.scale(12.5), fontWeight: FontWeight.w700, color: active ? accent : POSColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
