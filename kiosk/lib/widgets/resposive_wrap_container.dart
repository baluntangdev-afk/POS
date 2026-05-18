import 'package:flutter/material.dart';

class ResponsiveWrapContainer extends StatelessWidget {
  const ResponsiveWrapContainer({
    super.key,
    this.rowItems = 4,
    this.spacing = 8.0,
    this.padding = EdgeInsets.zero,
    required this.items,
    this.decoration,
    this.equalWidth = false,
  });

  final double spacing;
  final EdgeInsetsGeometry padding;
  final int rowItems;
  final bool equalWidth;
  final List<Widget> items;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final maxPerRow = rowItems;

          final totalSpacing = spacing * (maxPerRow - 1);
          final evenWidth = (parentWidth - totalSpacing) / maxPerRow;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(items.length, (index) {
              final rowIndex = index ~/ maxPerRow;
              final start = rowIndex * maxPerRow;
              final end = (start + maxPerRow).clamp(0, items.length);
              final rowChildrenCount = items.sublist(start, end).length;

              final itemWidth = (parentWidth - (rowChildrenCount - 1) * spacing) / rowChildrenCount;
              return SizedBox(width: equalWidth ? evenWidth : itemWidth, child: items[index]);
            }),
          );
        },
      ),
    );
  }
}
