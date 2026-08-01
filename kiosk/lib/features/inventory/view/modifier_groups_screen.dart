import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/debounce.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_box_form_field.dart';
import '../data/models/modifier.dart';
import '../data/models/modifier_group.dart';
import '../state/inventory_modifier_groups_notifier.dart';

class ModifierGroupsScreen extends HookConsumerWidget {
  const ModifierGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState<String?>(null);
    final expandedGroups = useState<Set<String>>(<String>{});
    final isPhone = context.breakpoint.isPhone;

    final state = ref.watch(inventoryModifierGroupsProvider);

    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          _SearchAndAddControls(searchQuery: searchQuery),
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: ColorSet.primary,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
                      color: POSColors.textDisabled,
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 14, tablet: 13, phone: 12),
                        color: POSColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    Button(
                      label: const Text('Retry'),
                      leading: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.read(inventoryModifierGroupsProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
              data: (groups) => isPhone
                  ? _ModifierGroupsMobileList(
                      groups: groups,
                      searchQuery: searchQuery,
                      expandedGroups: expandedGroups,
                    )
                  : _ModifierGroupsTable(
                      groups: groups,
                      searchQuery: searchQuery,
                      expandedGroups: expandedGroups,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndAddControls extends StatelessWidget {
  const _SearchAndAddControls({required this.searchQuery});

  final ValueNotifier<String?> searchQuery;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.breakpoint.isPhone;
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Expanded(
            child: HookBuilder(
              builder: (context) {
                final debounce = useDebounce(const Duration(milliseconds: 300));
                return TextBoxFormField.singleLine(
                  hint: 'Search modifier groups...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                    color: POSColors.iconSubtle,
                  ),
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                  onChanged: (value) {
                    debounce(() {
                      searchQuery.value = (value?.isEmpty ?? true) ? null : value;
                    });
                  },
                );
              },
            ),
          ),
          if (isPhone)
            FilledButton(
              onPressed: () {
                // TODO: Show create modifier group dialog
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add, size: 20),
            )
          else
            Button(
              label: const Text('Create New Group'),
              leading: const Icon(Icons.add),
              onPressed: () {
                // TODO: Show create modifier group dialog
              },
            ),
        ],
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyGroupsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tune_outlined,
            size: context.responsive.value(kiosk: 80, tablet: 64, phone: 48),
            color: POSColors.textDisabled,
          ),
          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
          Text(
            'No modifier groups found',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 14),
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
          Text(
            'Try adjusting your search or create a new group',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              color: POSColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone: card list ──────────────────────────────────────────────────────────

class _ModifierGroupsMobileList extends StatelessWidget {
  const _ModifierGroupsMobileList({
    required this.groups,
    required this.searchQuery,
    required this.expandedGroups,
  });

  final List<InventoryModifierGroup> groups;
  final ValueNotifier<String?> searchQuery;
  final ValueNotifier<Set<String>> expandedGroups;

  @override
  Widget build(BuildContext context) {
    final filteredGroups = searchQuery.value == null
        ? groups
        : groups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(searchQuery.value!.toLowerCase()),
            )
            .toList();

    if (filteredGroups.isEmpty) {
      return _EmptyGroupsState();
    }

    return ListView.builder(
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return _ModifierGroupCard(
          group: group,
          isExpanded: expandedGroups.value.contains(group.id),
          onToggle: () {
            final newExpanded = Set<String>.from(expandedGroups.value);
            if (newExpanded.contains(group.id)) {
              newExpanded.remove(group.id);
            } else {
              newExpanded.add(group.id);
            }
            expandedGroups.value = newExpanded;
          },
        );
      },
    );
  }
}

class _ModifierGroupCard extends StatelessWidget {
  const _ModifierGroupCard({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  final InventoryModifierGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: isExpanded ? Radius.zero : const Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_right,
                          color: ColorSet.primary,
                          size: 20,
                        ),
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: POSColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${group.modifiers.length} items',
                        style: TextStyle(fontSize: 12, color: POSColors.textSecondary),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Show edit group dialog
                        },
                        icon: const Icon(Icons.edit, size: 15),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(foregroundColor: ColorSet.primary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Show delete confirmation
                        },
                        icon: const Icon(Icons.delete, size: 15),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: ColorSet.danger),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded ? _ModifiersList(group: group) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Tablet / Kiosk: table ─────────────────────────────────────────────────────

class _ModifierGroupsTable extends StatelessWidget {
  const _ModifierGroupsTable({
    required this.groups,
    required this.searchQuery,
    required this.expandedGroups,
  });

  final List<InventoryModifierGroup> groups;
  final ValueNotifier<String?> searchQuery;
  final ValueNotifier<Set<String>> expandedGroups;

  @override
  Widget build(BuildContext context) {
    final filteredGroups = searchQuery.value == null
        ? groups
        : groups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(searchQuery.value!.toLowerCase()),
            )
            .toList();

    if (filteredGroups.isEmpty) {
      return _EmptyGroupsState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _TableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final group = filteredGroups[index];
                return _ModifierGroupRow(
                  group: group,
                  isExpanded: expandedGroups.value.contains(group.id),
                  onToggle: () {
                    final newExpanded = Set<String>.from(expandedGroups.value);
                    if (newExpanded.contains(group.id)) {
                      newExpanded.remove(group.id);
                    } else {
                      newExpanded.add(group.id);
                    }
                    expandedGroups.value = newExpanded;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorSet.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
          topRight: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
        ),
      ),
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell(title: 'Group Name')),
          Expanded(flex: 2, child: _HeaderCell(title: 'Modifiers')),
          Expanded(flex: 2, child: _HeaderCell(title: 'Used By')),
          Expanded(flex: 2, child: _HeaderCell(title: 'Actions')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ModifierGroupRow extends StatelessWidget {
  const _ModifierGroupRow({required this.group, required this.isExpanded, required this.onToggle});

  final InventoryModifierGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          color: ColorSet.primary,
                          size: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                        ),
                      ),
                      Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                            fontWeight: FontWeight.w600,
                            color: POSColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${group.modifiers.length} items',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                      color: POSColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${group.selectionType} • ${group.isRequired ? 'required' : 'optional'}',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                      color: POSColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Group',
                        style: IconButton.styleFrom(
                          foregroundColor: ColorSet.primary,
                          iconSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        ),
                        onPressed: () {
                          // TODO: Show edit group dialog
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete Group',
                        style: IconButton.styleFrom(
                          foregroundColor: ColorSet.danger,
                          iconSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        ),
                        onPressed: () {
                          // TODO: Show delete confirmation
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded ? _ModifiersList(group: group) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ModifiersList extends StatelessWidget {
  const _ModifiersList({required this.group});

  final InventoryModifierGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Text(
            'Modifiers',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              fontWeight: FontWeight.w600,
              color: POSColors.textPrimary,
            ),
          ),
          ...group.modifiers.map((modifier) => _ModifierItem(modifier: modifier)),
          SizedBox(
            width: double.infinity,
            child: Button(
              label: const Text('Add Modifier'),
              leading: const Icon(Icons.add),
              onPressed: () {
                // TODO: Show add modifier dialog
              },
              backgroundColor: POSColors.borderSubtle,
              foregroundColor: POSColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierItem extends StatelessWidget {
  const _ModifierItem({required this.modifier});

  final InventoryModifier modifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
        horizontal: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 6, tablet: 5, phone: 4),
        ),
        border: Border.all(color: POSColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${modifier.name} (+PHP ${modifier.priceAdjustment.toStringAsFixed(2)})',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                color: POSColors.textPrimary,
              ),
            ),
          ),
          Row(
            spacing: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Modifier',
                style: IconButton.styleFrom(
                  foregroundColor: ColorSet.primary,
                  iconSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                  minimumSize: Size(
                    context.responsive.value(kiosk: 32, tablet: 28, phone: 24),
                    context.responsive.value(kiosk: 32, tablet: 28, phone: 24),
                  ),
                ),
                onPressed: () {
                  // TODO: Show edit modifier dialog
                },
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'Remove Modifier',
                style: IconButton.styleFrom(
                  foregroundColor: ColorSet.danger,
                  iconSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                  minimumSize: Size(
                    context.responsive.value(kiosk: 32, tablet: 28, phone: 24),
                    context.responsive.value(kiosk: 32, tablet: 28, phone: 24),
                  ),
                ),
                onPressed: () {
                  // TODO: Show remove confirmation
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
