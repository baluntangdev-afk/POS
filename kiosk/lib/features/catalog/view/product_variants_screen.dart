import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
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

    final isAndroid = context.breakpoint.isAndroid;

    if (productState.isLoading || productState.hasError) {
      const spinner = Center(
        child: CircularProgressIndicator(
          color: ColorSet.primary,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      );
      if (isAndroid) return const AndroidScaffold(body: spinner);
      return const WindowsScaffold(body: spinner);
    }

    final product = productState.value ?? Product.draft();
    final variants = useState(product.variants.toList());

    final appBar = PreferredSize(
      preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
      child: _TopAppBar(product: product),
    );
    final body = Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          _VariantsSummary(variants: variants.value),
          Expanded(child: _VariantsTable(variants: variants)),
        ],
      ),
    );
    final fab = _FloatingAddButton(onAdd: () {});
    if (isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        appBar: appBar,
        body: body,
        floatingActionButton: fab,
      );
    }
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      appBar: appBar,
      body: body,
      floatingActionButton: fab,
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
              'Variants — ${product.name}',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 32, tablet: 26, phone: 18),
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
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total Variants',
              value: '${variants.length}',
              icon: Icons.category_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: POSColors.borderSubtle),
          Expanded(
            child: _SummaryItem(
              label: 'Default',
              value: defaultVariant?.name ?? 'None',
              icon: Icons.star_rounded,
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
            color: POSColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
            fontWeight: FontWeight.w700,
            color: POSColors.textPrimary,
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
              child: variants.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: context.responsive.value(kiosk: 64, tablet: 48, phone: 32),
                            color: POSColors.textDisabled,
                          ),
                          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                          Text(
                            'No variants yet',
                            style: TextStyle(
                              fontSize:
                                  context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
                              fontWeight: FontWeight.w700,
                              color: POSColors.textSecondary,
                            ),
                          ),
                          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                          Text(
                            'Tap the + button to add your first variant',
                            style: TextStyle(
                              fontSize:
                                  context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                              color: POSColors.textDisabled,
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleDefault,
                  borderRadius: BorderRadius.circular(POSRadius.full),
                  child: Container(
                    width: context.responsive.value(kiosk: 28, tablet: 24, phone: 20),
                    height: context.responsive.value(kiosk: 28, tablet: 24, phone: 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: variant.isDefault
                          ? ColorSet.success
                          : POSColors.surfaceSubtle,
                      border: Border.all(
                        color: variant.isDefault
                            ? ColorSet.success
                            : POSColors.borderDefault,
                        width: 2,
                      ),
                    ),
                    child: variant.isDefault
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                          )
                        : null,
                  ),
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
                fontWeight: FontWeight.w600,
                color: POSColors.textPrimary,
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
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.primary,
                      side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_rounded, size: 14),
                    label: const Text('Delete'),
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSet.danger,
                      side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
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

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onAdd,
      backgroundColor: ColorSet.primary,
      foregroundColor: ColorSet.light,
      child: Icon(Icons.add, size: context.responsive.value(kiosk: 32, tablet: 28, phone: 24)),
    );
  }
}
