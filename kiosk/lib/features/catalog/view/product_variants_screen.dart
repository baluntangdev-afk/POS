import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/product.dart';
import '../entities/product_variant.dart';
import '../state/products_notifier.dart';

class ProductVariantsScreen extends HookConsumerWidget {
  const ProductVariantsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(
      productsProvider.select(
        (it) => it.whenData(
          (data) => data.data.data.firstWhere(
            (product) => product.id.toString() == productId,
            orElse: () => Product.draft(),
          ),
        ),
      ),
    );

    ref.listen(productsProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(context, error: error).then((_) {
          if (context.mounted && context.canPop()) {
            context.pop();
          }
        });
      }
    });

    if (productState.isLoading || productState.hasError) {
      return const WindowsScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = productState.value ?? Product.draft();
    final variants = useState(product.variants.toList());

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: _TopAppBar(product: product),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        child: Column(
          spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          children: [
            _VariantsSummary(variants: variants.value),
            Expanded(child: _VariantsTable(variants: variants)),
          ],
        ),
      ),
      floatingActionButton: _FloatingAddButton(onAdd: () {}),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.product});

  final Product product;

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
              'Variants - ${product.name}',
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

class _VariantsSummary extends StatelessWidget {
  const _VariantsSummary({required this.variants});

  final List<ProductVariant> variants;

  @override
  Widget build(BuildContext context) {
    final defaultVariant = variants.where((v) => v.isDefault).firstOrNull;

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
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total Variants',
              value: '${variants.length}',
              icon: Icons.category,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Default',
              value: defaultVariant?.name ?? 'None',
              icon: Icons.star,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
          color: ColorSet.primary,
        ),
        Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VariantsTable extends StatelessWidget {
  const _VariantsTable({required this.variants});

  final ValueNotifier<List<ProductVariant>> variants;

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TableHeader(title: 'Default')),
                Expanded(flex: 8, child: _TableHeader(title: 'Name')),
                Expanded(flex: 2, child: _TableHeader(title: 'Actions')),
              ],
            ),
          ),
          Expanded(
            child:
                variants.value.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: context.responsive.value(kiosk: 64, tablet: 48, phone: 32),
                            color: Colors.grey.shade400,
                          ),
                          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                          Text(
                            'No variants yet',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                          Text(
                            'Click the + button to add your first variant',
                            style: TextStyle(
                              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: variants.value.length,
                      itemBuilder: (context, index) {
                        final variant = variants.value[index];
                        return _VariantRow(
                          variant: variant,
                          onEdit: () {},
                          onDelete: () {},
                          onToggleDefault: () {},
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

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDefault,
  });

  final ProductVariant variant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: GestureDetector(
                onTap: onToggleDefault,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  height: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: variant.isDefault ? ColorSet.success : Colors.grey.shade300,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child:
                      variant.isDefault
                          ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                          )
                          : null,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              variant.name.isEmpty ? 'New Variant' : variant.name,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
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
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Variant',
                    onPressed: onEdit,
                    style: IconButton.styleFrom(foregroundColor: ColorSet.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Variant',
                    onPressed: onDelete,
                    style: IconButton.styleFrom(foregroundColor: ColorSet.danger),
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

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onAdd,
      backgroundColor: ColorSet.secondary,
      foregroundColor: ColorSet.light,
      child: Icon(Icons.add, size: context.responsive.value(kiosk: 32, tablet: 28, phone: 24)),
    );
  }
}
