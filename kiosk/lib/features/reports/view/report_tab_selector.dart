import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../state/sales_report_state.dart';

class ReportTabSelector extends StatelessWidget {
  const ReportTabSelector({super.key, required this.selectedTab, required this.onTabChanged});

  final ReportTab selectedTab;
  final void Function(ReportTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.lg),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReportTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return _TabItem(
            tab: tab,
            isSelected: isSelected,
            onTap: () => onTabChanged(tab),
            responsive: r,
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.responsive,
  });

  final ReportTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final ResponsiveValue responsive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(POSRadius.md),
      child: AnimatedContainer(
        duration: POSAnimation.normal,
        curve: POSAnimation.ease,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: ColorSet.gradientBg,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.value<double>(kiosk: 20, tablet: 16, phone: 12),
                vertical: responsive.value<double>(kiosk: 10, tablet: 8, phone: 7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: responsive.value<double>(kiosk: 18, tablet: 16, phone: 14),
                    color: isSelected ? Colors.white : POSColors.textTertiary,
                  ),
                  SizedBox(width: responsive.scale(8)),
                  Text(
                    tab.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : POSColors.textSecondary,
                      fontSize: responsive.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
