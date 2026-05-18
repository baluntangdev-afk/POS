import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/debounce.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/product_group.dart';
import '../state/product_groups_notifier.dart';
import 'product_group_dialogs.dart';

class ProductGroupsScreen extends HookConsumerWidget {
  const ProductGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);
    final limit = useState(10);
    final name = useState<String?>(null);
    final description = useState<String?>(null);
    final sort = useState<String?>(null);

    final totalPages = ref.watch(
      productGroupsProvider.select((it) => it.value?.data.totalPages ?? 1),
    );

    ref.listen(productGroupsProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
    });

    useEffect(() {
      page.value = 1;
      return null;
    }, [limit.value, name.value, description.value]);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(productGroupsProvider.notifier)
            .getResults(
              page: page.value,
              limit: limit.value,
              name: name.value,
              description: description.value,
              sort: sort.value,
            );
      });
      return null;
    }, [page.value, limit.value, name.value, description.value, sort.value]);

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        child: Column(
          spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          children: [
            _PaginationControls(
              page: page,
              limit: limit,
              totalPages: totalPages,
              name: name,
              description: description,
            ),
            Expanded(child: _ProductGroupsTable(sort: sort)),
          ],
        ),
      ),
      floatingActionButton: const _FloatingAddButton(),
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
          Gap(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
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
              'Product Groups',
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

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.name,
    required this.description,
  });

  final ValueNotifier<int> page;
  final ValueNotifier<int> limit;
  final int totalPages;
  final ValueNotifier<String?> name;
  final ValueNotifier<String?> description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          Row(
            spacing: context.responsive.value(kiosk: 10, tablet: 8, phone: 6),
            children: [
              Expanded(
                child: HookBuilder(
                  builder: (context) {
                    final debounce = useDebounce(const Duration(milliseconds: 300));
                    return TextBoxFormField.singleLine(
                      hint: 'Search product group name...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        color: Colors.grey.shade500,
                      ),
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                      ),
                      onChanged: (value) {
                        debounce(() {
                          name.value = value;
                        });
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: HookBuilder(
                  builder: (context) {
                    final debounce = useDebounce(const Duration(milliseconds: 300));
                    return TextBoxFormField.singleLine(
                      hint: 'Search description...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        color: Colors.grey.shade500,
                      ),
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                      ),
                      onChanged: (value) {
                        debounce(() {
                          description.value = value;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Button(
                label: const Text('Previous'),
                onPressed: page.value > 1 ? () => page.value-- : null,
                leading: const Icon(Icons.keyboard_arrow_left),
              ),
              const Spacer(),
              Text(
                'Page ${totalPages > 0 ? page.value : 0} of $totalPages',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                  vertical: context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(
                    context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
                  ),
                ),
                child: DropdownButton<int>(
                  value: limit.value,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                    color: Colors.black87,
                  ),
                  items:
                      [10, 25, 50, 100].map((rows) {
                        return DropdownMenuItem(value: rows, child: Text('$rows rows'));
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      limit.value = value;
                    }
                  },
                ),
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Button(
                label: const Text('Next'),
                onPressed: page.value < totalPages ? () => page.value++ : null,
                trailing: const Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductGroupsTable extends ConsumerWidget {
  const _ProductGroupsTable({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productGroupsProvider.select((it) => it.whenData((data) => data.data)));

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
          Container(
            decoration: BoxDecoration(
              color: ColorSet.secondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
                topRight: Radius.circular(context.responsive.value(kiosk: 8, tablet: 8, phone: 6)),
              ),
            ),
            padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            child: Row(
              children: [
                const Expanded(flex: 2, child: _TableHeader(title: 'Image')),
                Expanded(
                  flex: 3,
                  child: _SortableHeader(title: 'Name', sortField: 'name', currentSort: sort),
                ),
                Expanded(
                  flex: 4,
                  child: _SortableHeader(
                    title: 'Description',
                    sortField: 'description',
                    currentSort: sort,
                  ),
                ),
                const Expanded(flex: 3, child: _TableHeader(title: 'Actions')),
              ],
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Center(child: SizedBox.shrink()),
              data: (data) {
                if (data.data.isEmpty) {
                  return Center(
                    child: Text(
                      'No product groups found.',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: data.data.length,
                  itemBuilder: (context, index) {
                    final productGroup = data.data[index];
                    return _ProductGroupRow(productGroup: productGroup);
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
  const _TableHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({required this.title, required this.sortField, required this.currentSort});

  final String title;
  final String sortField;
  final ValueNotifier<String?> currentSort;

  @override
  Widget build(BuildContext context) {
    final isAsc = currentSort.value == '$sortField:asc';
    final isDesc = currentSort.value == '$sortField:desc';

    return GestureDetector(
      onTap: () {
        if (isAsc) {
          currentSort.value = '$sortField:desc';
        } else if (isDesc) {
          currentSort.value = null;
        } else {
          currentSort.value = '$sortField:asc';
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(4),
          Icon(
            isAsc
                ? Icons.arrow_upward
                : isDesc
                ? Icons.arrow_downward
                : Icons.swap_vert,
            color: (isAsc || isDesc) ? Colors.white : Colors.white.withValues(alpha: 0.5),
            size: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
          ),
        ],
      ),
    );
  }
}

class _ProductGroupRow extends ConsumerWidget {
  const _ProductGroupRow({required this.productGroup});

  final ProductGroup productGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> updateProductGroup(ProductGroup productGroup) async {
      final saved = await showSaveProductGroupDialog(context, productGroup: productGroup);
      if (saved != null) {
        await ref.read(productGroupsProvider.notifier).refreshResults();
      }
    }

    Future<void> deleteProductGroup(ProductGroup productGroup) async {
      final isDeleted = await showDeleteProductGroupDialog(context, productGroup);
      if (isDeleted ?? false) {
        await ref.read(productGroupsProvider.notifier).refreshResults();
      }
    }

    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Image.memory(
                productGroup.image,
                width: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                height: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                    height: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image,
                      size: context.responsive.value(kiosk: 20, tablet: 16, phone: 14),
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              productGroup.name,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              productGroup.description,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: 'View Products',
                    onPressed: () {
                      // TODO(cody-kalvin): Navigate to product group details
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    style: TextButton.styleFrom(foregroundColor: ColorSet.primary),
                    onPressed: () => updateProductGroup(productGroup),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    style: TextButton.styleFrom(foregroundColor: ColorSet.danger),
                    onPressed: () => deleteProductGroup(productGroup),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends ConsumerWidget {
  const _FloatingAddButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () async {
        final saved = await showSaveProductGroupDialog(context);
        if (saved != null) {
          await ref.read(productGroupsProvider.notifier).refreshResults();
        }
      },
      backgroundColor: ColorSet.secondary,
      foregroundColor: ColorSet.light,
      child: Icon(Icons.add, size: context.responsive.value(kiosk: 32, tablet: 28, phone: 24)),
    );
  }
}
