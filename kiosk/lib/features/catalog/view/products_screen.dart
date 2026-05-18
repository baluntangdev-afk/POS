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
import '../entities/product.dart';
import '../state/products_notifier.dart';
import 'product_dialogs.dart';

class ProductsScreen extends HookConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);
    final limit = useState(10);
    final name = useState<String?>(null);
    final description = useState<String?>(null);
    final sort = useState<String?>(null);

    final totalPages = ref.watch(productsProvider.select((it) => it.value?.data.totalPages ?? 1));

    ref.listen(productsProvider, (previous, next) {
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
            .read(productsProvider.notifier)
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
            Expanded(child: _ProductsTable(sort: sort)),
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
              'Products',
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
                      hint: 'Search product name...',
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

class _ProductsTable extends ConsumerWidget {
  const _ProductsTable({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider.select((it) => it.whenData((data) => data.data)));

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
                  flex: 3,
                  child: _SortableHeader(
                    title: 'Description',
                    sortField: 'description',
                    currentSort: sort,
                  ),
                ),
                const Expanded(flex: 2, child: _TableHeader(title: 'Variants')),
                const Expanded(flex: 2, child: _TableHeader(title: 'Actions')),
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
                      'No products found.',
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
                    final product = data.data[index];
                    return _ProductRow(product: product);
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
        fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
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
                fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
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

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> updateProduct(Product product) async {
      final saved = await showSaveProductDialog(context, product: product);
      if (saved != null) {
        await ref.read(productsProvider.notifier).refreshResults();
      }
    }

    Future<void> deleteProduct(Product product) async {
      final isDeleted = await showDeleteProductDialog(context, product);
      if (isDeleted ?? false) {
        await ref.read(productsProvider.notifier).refreshResults();
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
                product.image,
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
              product.name,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              product.description,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${product.variants.length} variant${product.variants.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                  TextButton(
                    onPressed: () {
                      context.push('/products/${product.id}/variants');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                        vertical: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      product.variants.isEmpty ? 'Add Variant' : 'Manage',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                        color: ColorSet.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    style: TextButton.styleFrom(foregroundColor: ColorSet.primary),
                    onPressed: () => updateProduct(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    style: TextButton.styleFrom(foregroundColor: ColorSet.danger),
                    onPressed: () => deleteProduct(product),
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
        final saved = await showSaveProductDialog(context);
        if (saved != null) {
          await ref.read(productsProvider.notifier).refreshResults();
        }
      },
      backgroundColor: ColorSet.secondary,
      foregroundColor: ColorSet.light,
      child: Icon(Icons.add, size: context.responsive.value(kiosk: 32, tablet: 28, phone: 24)),
    );
  }
}
