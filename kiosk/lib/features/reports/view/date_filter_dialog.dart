import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/responsive/responsive_value.dart';
import '../state/sales_report_state.dart';

const _kTealColor = Color(0xFF5BBCBF);

class DateFilterDialog extends HookConsumerWidget {
  const DateFilterDialog({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onCustomDateChanged,
  });

  final DateFilter selectedFilter;
  final void Function(DateFilter) onFilterChanged;
  final void Function(DateTime, DateTime) onCustomDateChanged;

  static const _presetFilters = [
    DateFilter.today,
    DateFilter.yesterday,
    DateFilter.thisMonth,
    DateFilter.lastMonth,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final customStartDate = useState<DateTime?>(null);
    final customEndDate = useState<DateTime?>(null);
    final isCustomMode = useState(selectedFilter == DateFilter.custom);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth =
        screenWidth < 400
            ? screenWidth * 0.9
            : responsive.value<double>(kiosk: 340, tablet: 320, phone: 300);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          responsive.value<double>(kiosk: 12, tablet: 11, phone: 10),
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12),
        vertical: responsive.value<double>(kiosk: 24, tablet: 20, phone: 16),
      ),
      child: Builder(
        builder:
            (context) => Container(
              width: dialogWidth,
              padding: EdgeInsets.fromLTRB(
                responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
                responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
                responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
                responsive.value<double>(kiosk: 16, tablet: 14, phone: 12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  responsive.value<double>(kiosk: 12, tablet: 11, phone: 10),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date Filter',
                        style: TextStyle(
                          fontSize: responsive.scale(21),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          size: responsive.value<double>(kiosk: 20, tablet: 18, phone: 16),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),

                  // 2-column radio grid for preset filters
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2),
                    crossAxisSpacing: responsive.value<double>(kiosk: 4, tablet: 3, phone: 2),
                    childAspectRatio: responsive.value<double>(kiosk: 3.5, tablet: 3.2, phone: 3.0),
                    children:
                        _presetFilters.map((filter) {
                          final isSelected = !isCustomMode.value && filter == selectedFilter;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              isCustomMode.value = false;
                              customStartDate.value = null;
                              customEndDate.value = null;
                              onFilterChanged(filter);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: responsive.scale(25),
                                  color: isSelected ? _kTealColor : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    filter.displayName,
                                    style: TextStyle(
                                      fontSize: responsive.scale(18),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? _kTealColor : Colors.grey.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                  // OR divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: responsive.scale(17),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                  // From field
                  Text(
                    'From:',
                    style: TextStyle(
                      fontSize: responsive.scale(16),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 6, tablet: 5, phone: 4)),
                  _DateTimeField(
                    dateTime: customStartDate.value,
                    hintText: 'mm/dd/yyyy',
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: customStartDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && context.mounted) {
                        customStartDate.value = DateTime(date.year, date.month, date.day);
                        isCustomMode.value = true;
                      }
                    },
                    onClear: () {
                      customStartDate.value = null;
                      customEndDate.value = null;
                    },
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                  // To field
                  Text(
                    'To:',
                    style: TextStyle(
                      fontSize: responsive.scale(16),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 6, tablet: 5, phone: 4)),
                  _DateTimeField(
                    dateTime: customEndDate.value,
                    hintText: 'mm/dd/yyyy',
                    enabled: customStartDate.value != null,
                    onTap: () async {
                      if (customStartDate.value == null) return; // Prevent opening if From is empty

                      final date = await showDatePicker(
                        context: context,
                        initialDate: customEndDate.value ?? customStartDate.value,
                        firstDate: customStartDate.value!,
                        lastDate: DateTime.now(),
                      );
                      if (date != null && context.mounted) {
                        customEndDate.value = DateTime(date.year, date.month, date.day, 23, 59);
                        isCustomMode.value = true;
                      }
                    },
                    onClear: () {
                      customEndDate.value = null;
                    },
                  ),
                  SizedBox(height: responsive.value<double>(kiosk: 16, tablet: 14, phone: 12)),

                  // Filter button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isCustomMode.value &&
                            customStartDate.value != null &&
                            customEndDate.value != null) {
                          // Validate that From date is not later than To date
                          if (customStartDate.value!.isAfter(customEndDate.value!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('From date cannot be later than To date'),
                                backgroundColor: Colors.red.shade600,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          onCustomDateChanged.call(customStartDate.value!, customEndDate.value!);
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kTealColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value<double>(kiosk: 28, tablet: 24, phone: 20),
                          vertical: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: responsive.scale(19),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.dateTime,
    required this.hintText,
    required this.onTap,
    required this.onClear,
    this.enabled = true,
  });

  final DateTime? dateTime;
  final String hintText;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
        ),
        border: Border.all(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        color: enabled ? Colors.white : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(
                responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
              ),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
                  vertical: responsive.value<double>(kiosk: 14, tablet: 12, phone: 10),
                ),
                child: Text(
                  dateTime != null ? DateFormat('MM/dd/yyyy').format(dateTime!) : hintText,
                  style: TextStyle(
                    fontSize: responsive.scale(18),
                    color:
                        dateTime != null
                            ? (enabled ? Colors.grey.shade800 : Colors.grey.shade400)
                            : (enabled ? Colors.grey.shade400 : Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ),
          if (dateTime != null && enabled)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(responsive.value<double>(kiosk: 8, tablet: 7, phone: 6)),
                bottomRight: Radius.circular(
                  responsive.value<double>(kiosk: 8, tablet: 7, phone: 6),
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
                  vertical: responsive.value<double>(kiosk: 14, tablet: 12, phone: 10),
                ),
                child: Icon(
                  Icons.clear,
                  size: responsive.value<double>(kiosk: 18, tablet: 16, phone: 14),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
