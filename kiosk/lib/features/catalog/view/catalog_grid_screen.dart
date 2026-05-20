import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/debounce.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../entities/product.dart';
import '../state/products_notifier.dart';

class CatalogGridScreen extends HookConsumerWidget {
  const CatalogGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(1);
    final limit = useState(20);
    final searchQuery = useState<String?>(null);
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
    }, [limit.value, searchQuery.value]);

    useEffect(() {
      Future.microtask(() {
        ref
            .read(productsProvider.notifier)
            .getResults(
              page: page.value,
              limit: limit.value,
              name: searchQuery.value,
              description: null,
              sort: sort.value,
            );
      });
      return null;
    }, [page.value, limit.value, searchQuery.value, sort.value]);

    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          _SearchAndFilterControls(
            page: page,
            limit: limit,
            totalPages: totalPages,
            searchQuery: searchQuery,
          ),
          Expanded(child: _ProductsGrid()),
        ],
      ),
    );
  }
}

class _SearchAndFilterControls extends StatelessWidget {
  const _SearchAndFilterControls({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.searchQuery,
  });

  final ValueNotifier<int> page;
  final ValueNotifier<int> limit;
  final int totalPages;
  final ValueNotifier<String?> searchQuery;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.breakpoint.isPhone;
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
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
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Row(
            spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
            children: [
              Expanded(
                child: HookBuilder(
                  builder: (context) {
                    final debounce = useDebounce(const Duration(milliseconds: 300));
                    return TextBoxFormField.singleLine(
                      hint: 'Search products...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
                        color: Colors.grey.shade500,
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
                    // TODO: Navigate to add product screen
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add, size: 20),
                )
              else
                Button(
                  label: const Text('Add Product'),
                  leading: const Icon(Icons.add),
                  onPressed: () {
                    // TODO: Navigate to add product screen
                  },
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              final dropdownBorderRadius = BorderRadius.circular(
                context.responsive.value(kiosk: 8, tablet: 8, phone: 6),
              );
              final dropdownChild = Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 16, tablet: 16, phone: 12),
                  vertical: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: dropdownBorderRadius,
                ),
                child: DropdownButton<int>(
                  value: limit.value,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                    color: Colors.black87,
                  ),
                  items: [20, 50, 100].map((rows) {
                    return DropdownMenuItem(value: rows, child: Text('$rows items'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) limit.value = value;
                  },
                ),
              );

              return Row(
                children: [
                  if (compact)
                    FilledButton(
                      onPressed: page.value > 1 ? () => page.value-- : null,
                      child: const Icon(Icons.keyboard_arrow_left),
                    )
                  else
                    Button(
                      label: const Text('Previous'),
                      onPressed: page.value > 1 ? () => page.value-- : null,
                      leading: const Icon(Icons.keyboard_arrow_left),
                    ),
                  const Spacer(),
                  Text(
                    'Page ${totalPages > 0 ? page.value : 0} of $totalPages',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  dropdownChild,
                  Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                  if (compact)
                    FilledButton(
                      onPressed: page.value < totalPages ? () => page.value++ : null,
                      child: const Icon(Icons.keyboard_arrow_right),
                    )
                  else
                    Button(
                      label: const Text('Next'),
                      onPressed: page.value < totalPages ? () => page.value++ : null,
                      trailing: const Icon(Icons.keyboard_arrow_right),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider.select((it) => it.whenData((data) => data.data)));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: SizedBox.shrink()),
      data: (data) {
        if (data.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: context.responsive.value(kiosk: 80, tablet: 64, phone: 48),
                  color: Colors.grey.shade400,
                ),
                Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                Text(
                  'Try adjusting your search or add new products',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ResponsiveBuilder(
          kiosk:
              (context) => _ProductGrid(
                products: data.data.toList(),
                crossAxisCount: 4,
                childAspectRatio: 0.8,
              ),
          tablet:
              (context) => _ProductGrid(
                products: data.data.toList(),
                crossAxisCount: 3,
                childAspectRatio: 0.75,
              ),
          phone:
              (context) => _ProductGrid(
                products: data.data.toList(),
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final List<Product> products;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final priceRange = _getPriceRange(product);
    final modifierGroupCount = _getModifierGroupCount(product);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          ProductDetailRoute(product.id).push<void>(context);
        },
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image fills all remaining space — no fixed flex ratio
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                    ),
                    topRight: Radius.circular(
                      context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                    ),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                    ),
                    topRight: Radius.circular(
                      context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                    ),
                  ),
                  child: Image.memory(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image,
                          size: context.responsive.value(kiosk: 40, tablet: 32, phone: 24),
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Info auto-sizes to content — no Spacer, no Expanded
            Padding(
              padding: EdgeInsets.all(context.responsive.value(kiosk: 12, tablet: 10, phone: 8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                  Text(
                    priceRange,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                      fontWeight: FontWeight.w700,
                      color: ColorSet.primary,
                    ),
                  ),
                  SizedBox(height: context.responsive.value(kiosk: 2, tablet: 2, phone: 1)),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                        color: Colors.grey.shade600,
                      ),
                      Gap(context.responsive.value(kiosk: 2, tablet: 2, phone: 1)),
                      Text(
                        '${product.variants.length} variant${product.variants.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.tune_outlined,
                        size: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                        color: Colors.grey.shade600,
                      ),
                      Gap(context.responsive.value(kiosk: 2, tablet: 2, phone: 1)),
                      Text(
                        '$modifierGroupCount modifier group${modifierGroupCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      label: Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
                        ),
                      ),
                      onPressed: () {
                        ProductDetailRoute(product.id).push<void>(context);
                      },
                      backgroundColor: ColorSet.primary,
                      foregroundColor: Colors.white,
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

  String _getPriceRange(Product product) {
    if (product.variants.isEmpty) {
      return r'$0.00';
    }

    // Since ProductVariant doesn't have price, return placeholder
    return r'$0.00';
  }

  int _getModifierGroupCount(Product product) {
    // TODO: Implement when modifier assignments are available
    return 0;
  }
}
