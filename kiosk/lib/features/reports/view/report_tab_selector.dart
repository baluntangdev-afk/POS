import 'package:flutter/material.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../state/sales_report_state.dart';

class ReportTabSelector extends StatelessWidget {
  const ReportTabSelector({super.key, required this.selectedTab, required this.onTabChanged});

  final ReportTab selectedTab;
  final void Function(ReportTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(responsive.scale(15)),
        decoration: BoxDecoration(
          color: ColorSet.background,
          borderRadius: BorderRadius.circular(responsive.scale(17)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              ReportTab.values.map((tab) {
                final isSelected = tab == selectedTab;
                return Padding(
                  padding: EdgeInsets.only(right: responsive.scale(13)),
                  child: GestureDetector(
                    onTap: () => onTabChanged(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.scale(25),
                        vertical: responsive.scale(15),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorSet.secondary : ColorSet.transparent,
                        borderRadius: BorderRadius.circular(responsive.scale(13)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: responsive.scale(40),
                            color: isSelected ? ColorSet.light : Colors.grey.shade600,
                          ),
                          SizedBox(width: responsive.scale(15)),
                          Text(
                            tab.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? ColorSet.light : Colors.grey.shade600,
                              fontSize: responsive.scale(25),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
