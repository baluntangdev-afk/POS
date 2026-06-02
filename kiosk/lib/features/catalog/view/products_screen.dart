import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/debounce.dart';
import '../../../widgets/android_scaffold.dart';
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

    final isAndroid = context.breakpoint.isAndroid;
    final isPhone = context.breakpoint.isPhone;
    final appBar = PreferredSize(
      preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
      child: const _TopAppBar(),
    );
    final body = Padding(
      padding: EdgeInsets.all(context.responsive.spacingLg),
      child: Column(
        spacing: context.responsive.spacingMd,
        children: [
          _PaginationControls(
            page: page,
            limit: limit,
            totalPages: totalPages,
            name: name,
            description: description,
          ),
          Expanded(
            child: isPhone ? const _ProductsMobileList() : _ProductsTable(sort: sort),
          ),
        ],
      ),
    );
    if (isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        appBar: appBar,
        body: body,
        floatingActionButton: const _FloatingAddButton(),
      );
    }
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      appBar: appBar,
      body: body,
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
          colors: ColorSet.gradientBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Gap(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (context.canPop()) context.pop();
              },
              borderRadius: BorderRadius.circular(POSRadius.full),
              child: Padding(
                padding: EdgeInsets.all(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: ColorSet.light,
                  size: context.responsive.value(kiosk: 28, tablet: 24, phone: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Products',
              style: TextStyle(
                fontSize: context.responsive.fontTitle,
                fontWeight: FontWeight.w700,
                color: ColorSet.light,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Gap(context.responsive.value(kiosk: 64, tablet: 48, phone: 36)),
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
    final isPhone = context.breakpoint.isPhone;
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        spacing: context.responsive.spacingMd,
        children: [
          if (isPhone)
            Column(
              spacing: context.responsive.spacingSm,
              children: [
                _NameSearch(name: name),
                _DescriptionSearch(description: description),
              ],
            )
          else
            Row(
              spacing: context.responsive.value(kiosk: 10, tablet: 8, phone: 6),
              children: [
                Expanded(child: _NameSearch(name: name)),
                Expanded(child: _DescriptionSearch(description: description)),
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
                  color: POSColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.spacingMd,
                  vertical: context.responsive.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: POSColors.surfaceSubtle,
                  border: Border.all(color: POSColors.borderDefault),
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
                child: DropdownButton<int>(
                  value: limit.value,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                    color: POSColors.textPrimary,
                  ),
                  items: [10, 25, 50, 100].map((rows) {
                    return DropdownMenuItem(value: rows, child: Text('$rows rows'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) limit.value = value;
                  },
                ),
              ),
              Gap(context.responsive.spacingMd),
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

class _NameSearch extends HookWidget {
  const _NameSearch({required this.name});

  final ValueNotifier<String?> name;

  @override
  Widget build(BuildContext context) {
    final debounce = useDebounce(const Duration(milliseconds: 300));
    return TextBoxFormField.singleLine(
      hint: 'Search product name...',
      prefixIcon: Icon(
        Icons.search_rounded,
        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
        color: POSColors.iconSubtle,
      ),
      style: TextStyle(fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12)),
      onChanged: (value) {
        debounce(() {
          name.value = value;
        });
      },
    );
  }
}

class _DescriptionSearch extends HookWidget {
  const _DescriptionSearch({required this.description});

  final ValueNotifier<String?> description;

  @override
  Widget build(BuildContext context) {
    final debounce = useDebounce(const Duration(milliseconds: 300));
    return TextBoxFormField.singleLine(
      hint: 'Search description...',
      prefixIcon: Icon(
        Icons.search_rounded,
        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
        color: POSColors.iconSubtle,
      ),
      style: TextStyle(fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12)),
      onChanged: (value) {
        debounce(() {
          description.value = value;
        });
      },
    );
  }
}

// ── Phone: card list ──────────────────────────────────────────────────────────

class _ProductsMobileList extends ConsumerWidget {
  const _ProductsMobileList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider.select((it) => it.whenData((data) => data.data)));

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: ColorSet.primary,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      ),
      error: (error, _) => const Center(child: SizedBox.shrink()),
      data: (data) {
        if (data.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: context.responsive.value(kiosk: 64, tablet: 52, phone: 40),
                  color: POSColors.textDisabled,
                ),
                Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 18, tablet: 15, phone: 13),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textSecondary,
                  ),
                ),
                Gap(context.responsive.value(kiosk: 6, tablet: 4, phone: 3)),
                Text(
                  'Try adjusting your search or add new products',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 13, tablet: 12, phone: 11),
                    color: POSColors.textDisabled,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: data.data.length,
          itemBuilder: (context, index) => _ProductCard(product: data.data[index]),
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

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
      margin: EdgeInsets.only(bottom: context.responsive.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(context.responsive.spacingMd),
            child: Row(
              spacing: context.responsive.spacingMd,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                  child: Image.memory(
                    product.image,
                    width: context.responsive.value(kiosk: 60, tablet: 50, phone: 48),
                    height: context.responsive.value(kiosk: 60, tablet: 50, phone: 48),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: context.responsive.value(kiosk: 60, tablet: 50, phone: 48),
                      height: context.responsive.value(kiosk: 60, tablet: 50, phone: 48),
                      color: const Color(0xFFFFF3E0),
                      child: Center(
                        child: Icon(
                          Icons.lunch_dining,
                          size: context.responsive.value(kiosk: 24, tablet: 20, phone: 18),
                          color: const Color(0xFFD4854A),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: context.responsive.spacingSm,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 14),
                          fontWeight: FontWeight.w700,
                          color: POSColors.textPrimary,
                        ),
                      ),
                      if (product.description.isNotEmpty)
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 12),
                            color: POSColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          Text(
                            '${product.variants.length} variant${product.variants.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 12, tablet: 11, phone: 11),
                              color: POSColors.textTertiary,
                            ),
                          ),
                          const Gap(4),
                          TextButton(
                            onPressed: () => context.push('/products/${product.id}/variants'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: ColorSet.primary,
                            ),
                            child: Text(
                              product.variants.isEmpty ? 'Add Variant' : 'Manage',
                              style: TextStyle(
                                fontSize: context.responsive.value(kiosk: 12, tablet: 11, phone: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: context.responsive.spacingSm,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => updateProduct(product),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorSet.primary,
                        side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(POSRadius.sm),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: const Text('Delete'),
                      onPressed: () => deleteProduct(product),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorSet.danger,
                        side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(POSRadius.sm),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tablet / Kiosk: table ─────────────────────────────────────────────────────

class _ProductsTable extends ConsumerWidget {
  const _ProductsTable({required this.sort});

  final ValueNotifier<String?> sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider.select((it) => it.whenData((data) => data.data)));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ColorSet.gradientBg,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: EdgeInsets.all(context.responsive.spacingMd),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: ColorSet.primary,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                error: (error, _) => const Center(child: SizedBox.shrink()),
                data: (data) {
                  if (data.data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: context.responsive.value(kiosk: 64, tablet: 52, phone: 40),
                            color: POSColors.textDisabled,
                          ),
                          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 18, tablet: 15, phone: 13),
                              fontWeight: FontWeight.w700,
                              color: POSColors.textSecondary,
                            ),
                          ),
                          Gap(context.responsive.value(kiosk: 6, tablet: 4, phone: 3)),
                          Text(
                            'Try adjusting your search or add new products',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 13, tablet: 12, phone: 11),
                              color: POSColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: data.data.length,
                    itemBuilder: (context, index) => _ProductRow(product: data.data[index]),
                  );
                },
              ),
            ),
          ],
        ),
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
        letterSpacing: 0.2,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAsc) {
            currentSort.value = '$sortField:desc';
          } else if (isDesc) {
            currentSort.value = null;
          } else {
            currentSort.value = '$sortField:asc';
          }
        },
        borderRadius: BorderRadius.circular(POSRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(4),
              Icon(
                isAsc
                    ? Icons.arrow_upward_rounded
                    : isDesc
                    ? Icons.arrow_downward_rounded
                    : Icons.unfold_more_rounded,
                color: (isAsc || isDesc) ? Colors.white : Colors.white.withValues(alpha: 0.5),
                size: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
              ),
            ],
          ),
        ),
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
      padding: EdgeInsets.all(context.responsive.spacingMd),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(POSRadius.md),
                child: Image.memory(
                  product.image,
                  width: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                  height: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                      height: context.responsive.value(kiosk: 60, tablet: 50, phone: 40),
                      color: const Color(0xFFFFF3E0),
                      child: Center(
                        child: Icon(
                          Icons.lunch_dining,
                          size: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                          color: const Color(0xFFD4854A),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              product.name,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                fontWeight: FontWeight.w600,
                color: POSColors.textPrimary,
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
                color: POSColors.textSecondary,
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
                      color: POSColors.textPrimary,
                    ),
                  ),
                  Gap(context.responsive.spacingSm),
                  TextButton(
                    onPressed: () {
                      context.push('/products/${product.id}/variants');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingSm,
                        vertical: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: ColorSet.primary,
                    ),
                    child: Text(
                      product.variants.isEmpty ? 'Add Variant' : 'Manage',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
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
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Edit'),
                    onPressed: () => updateProduct(product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.primary,
                      side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                      textStyle: TextStyle(
                        fontSize: context.responsive.value(kiosk: 12, tablet: 11, phone: 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_rounded, size: 14),
                    label: const Text('Delete'),
                    onPressed: () => deleteProduct(product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.danger,
                      side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                      textStyle: TextStyle(
                        fontSize: context.responsive.value(kiosk: 12, tablet: 11, phone: 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
      backgroundColor: ColorSet.primary,
      foregroundColor: ColorSet.light,
      child: Icon(Icons.add, size: context.responsive.value(kiosk: 32, tablet: 28, phone: 24)),
    );
  }
}
