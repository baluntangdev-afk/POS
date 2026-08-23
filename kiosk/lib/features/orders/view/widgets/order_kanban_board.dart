import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../../entities/order_event.dart';
import '../order_format.dart';
import '../order_status.dart';
import 'order_card.dart';

/// Main content area for the Orders screen: a header (selected fulfillment
/// type, order count, running total) above a status Kanban board — one
/// column per [OrderKanbanColumn], each holding that column's order cards.
///
/// Columns reflow (never scroll sideways) as the window narrows: on a full
/// kiosk width every column fits in a single row and only a column's own
/// card list scrolls; below that, columns wrap into a scrollable grid of
/// rows so the *board* scrolls vertically instead of ever requiring a
/// horizontal scroll gesture — important on a touchscreen kiosk, where a
/// sideways swipe is easy to trigger by accident and easy to miss entirely.
class OrderKanbanBoard extends StatelessWidget {
  const OrderKanbanBoard({
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

    final grouped = <OrderKanbanColumn, List<OrderEvent>>{
      for (final column in kOrderKanbanColumns) column: [],
    };
    for (final event in events) {
      grouped[kanbanColumnFor(classifyOrderStatus(event))]!.add(event);
    }
    // Terminal columns (nothing more happens to an order once it lands here)
    // only show up once they actually have an order in them — otherwise an
    // empty "Fulfilled"/"Cancelled" column sits there wasting a full column's
    // worth of space, and on narrower widths pushes the grid into a second
    // row that's mostly dead air. Active columns always show, even at zero,
    // since kitchen staff track those counts continuously.
    const terminalColumns = {OrderKanbanColumn.fulfilled, OrderKanbanColumn.cancelled, OrderKanbanColumn.unknown};
    final visibleColumns =
        kOrderKanbanColumns
            .where((c) => !terminalColumns.contains(c) || grouped[c]!.isNotEmpty)
            .toList();

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
                style: TextStyle(
                  fontSize: r.scale(21),
                  fontWeight: FontWeight.w800,
                  color: POSColors.textPrimary,
                  letterSpacing: -0.3,
                ),
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
          child:
              events.isEmpty
                  ? _EmptyBoard(title: title)
                  : _BoardBody(columns: visibleColumns, grouped: grouped, accentColor: accentColor),
        ),
      ],
    );
  }
}

/// Picks how many columns share a row for the given board width. Chosen so
/// a full kiosk window shows every column at once, and each narrower step
/// still keeps individual columns wide enough to read a card comfortably.
int _crossAxisCountFor(double width, int columnCount) {
  if (width >= 820) return columnCount;
  if (width >= 700) return 3;
  if (width >= 460) return 2;
  return 1;
}

class _BoardBody extends StatelessWidget {
  const _BoardBody({required this.columns, required this.grouped, required this.accentColor});

  final List<OrderKanbanColumn> columns;
  final Map<OrderKanbanColumn, List<OrderEvent>> grouped;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final gap = r.scale(12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _crossAxisCountFor(constraints.maxWidth, columns.length);
        final singleRow = crossAxisCount >= columns.length;

        if (singleRow) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _KanbanColumn(
                    column: columns[i],
                    events: grouped[columns[i]]!.toIList(),
                    accentColor: accentColor,
                  ),
                ),
              ],
            ],
          );
        }

        // More columns than fit in one row: fall back to a scrollable grid
        // so the board grows *down*, not sideways — each row gets a fixed
        // height and the grid itself provides the vertical scroll.
        return GridView.builder(
          padding: EdgeInsets.only(bottom: r.scale(4)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: r.value<double>(kiosk: 360, tablet: 320, phone: 300),
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
          ),
          itemCount: columns.length,
          itemBuilder:
              (context, index) => _KanbanColumn(
                column: columns[index],
                events: grouped[columns[index]]!.toIList(),
                accentColor: accentColor,
              ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  const _KanbanColumn({required this.column, required this.events, required this.accentColor});

  final OrderKanbanColumn column;
  final IList<OrderEvent> events;
  final Color accentColor;

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

/// Animates order cards in and out as they cross between columns, instead of
/// the list just snapping to its new contents. Cards are matched by
/// [OrderData.id] between rebuilds: anything that dropped out of [widget.events]
/// (moved to another column, or the order list itself changed) fades and
/// shrinks out; anything new fades and grows in. This mirrors how a card
/// visually "arrives" in the next column when its status changes.
class _KanbanColumnState extends State<_KanbanColumn> {
  final _listKey = GlobalKey<AnimatedListState>();
  static const _animationDuration = Duration(milliseconds: 280);
  late final List<OrderEvent> _events = widget.events.toList();

  @override
  void didUpdateWidget(_KanbanColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncList(widget.events);
  }

  void _syncList(IList<OrderEvent> newEvents) {
    for (var i = _events.length - 1; i >= 0; i--) {
      final id = _events[i].data.id;
      if (!newEvents.any((e) => e.data.id == id)) {
        final removed = _events.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _AnimatedOrderCard(event: removed, accentColor: widget.accentColor, animation: animation),
          duration: _animationDuration,
        );
      }
    }
    for (var i = 0; i < newEvents.length; i++) {
      final id = newEvents[i].data.id;
      if (i >= _events.length || _events[i].data.id != id) {
        _events.insert(i, newEvents[i]);
        _listKey.currentState?.insertItem(i, duration: _animationDuration);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final (label, columnAccent) = kanbanColumnStyle(widget.column);
    final total = widget.events.fold<num>(0, (sum, e) => sum + e.data.total);

    return Container(
      decoration: BoxDecoration(color: POSColors.surfaceOverlay, borderRadius: BorderRadius.circular(POSRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(r.scale(14), r.scale(14), r.scale(14), r.scale(10)),
            child: Row(
              children: [
                Container(
                  width: r.scale(9),
                  height: r.scale(9),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: columnAccent),
                ),
                SizedBox(width: r.scale(8)),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: r.scale(13.5), fontWeight: FontWeight.w700, color: POSColors.textPrimary),
                  ),
                ),
                SizedBox(width: r.scale(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.scale(9), vertical: r.scale(2)),
                  decoration: BoxDecoration(
                    color: columnAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(POSRadius.full),
                  ),
                  child: Text(
                    '${widget.events.length}',
                    style: TextStyle(fontSize: r.scale(11.5), fontWeight: FontWeight.w700, color: columnAccent),
                  ),
                ),
              ],
            ),
          ),
          if (widget.events.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(r.scale(14), 0, r.scale(14), r.scale(10)),
              child: Text(
                formatOrderMoney(total, null),
                style: TextStyle(fontSize: r.scale(11), fontWeight: FontWeight.w600, color: POSColors.textTertiary),
              ),
            ),
          Expanded(
            child:
                _events.isEmpty
                    ? _EmptyColumn(label: label)
                    : AnimatedList(
                      key: _listKey,
                      padding: EdgeInsets.fromLTRB(r.scale(10), 0, r.scale(10), r.scale(10)),
                      initialItemCount: _events.length,
                      itemBuilder:
                          (context, index, animation) => _AnimatedOrderCard(
                            event: _events[index],
                            accentColor: widget.accentColor,
                            animation: animation,
                          ),
                    ),
          ),
        ],
      ),
    );
  }
}

/// Fades and grows an [OrderCard] in as it's inserted into a column's
/// [AnimatedList], and does the reverse as it's removed — the visual cue
/// that a card just arrived from (or left for) another status column.
class _AnimatedOrderCard extends StatelessWidget {
  const _AnimatedOrderCard({required this.event, required this.accentColor, required this.animation});

  final OrderEvent event;
  final Color accentColor;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curved,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Padding(
            padding: EdgeInsets.only(bottom: r.scale(10)),
            child: OrderCard(key: ValueKey(event.data.id), event: event, accentColor: accentColor),
          ),
        ),
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: EdgeInsets.fromLTRB(r.scale(10), 0, r.scale(10), r.scale(10)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: r.scale(22)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(POSRadius.sm),
          border: Border.all(color: POSColors.borderStrong, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          'No ${label.toLowerCase()} orders',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: r.scale(12.5), fontWeight: FontWeight.w500, color: POSColors.textTertiary),
        ),
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.title});

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
