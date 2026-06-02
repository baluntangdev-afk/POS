import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
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
import '../../../widgets/button.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/product.dart';
import '../entities/product_variant.dart';

class ProductDetailScreen extends HookConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0);

    // Mock product data - in real implementation, this would come from state management
    final mockProduct = Product(
      id: productId,
      name: 'Burger Meal',
      description: 'Classic burger with sides and drink',
      image: Uint8List(0), // Placeholder
      variants: IList(const [
        ProductVariant(id: 1, name: 'Regular', isDefault: true),
        ProductVariant(id: 2, name: 'Large', isDefault: false),
      ]),
    );

    final isAndroid = context.breakpoint.isAndroid;
    final appBar = PreferredSize(
      preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
      child: _TopAppBar(productName: mockProduct.name),
    );
    final body = Column(
      children: [
        _TabBar(selectedTab: selectedTab),
        Expanded(
          child: IndexedStack(
            index: selectedTab.value,
            children: [
              _DetailsTab(product: mockProduct),
              _VariantsTab(product: mockProduct),
              _ModifiersTab(product: mockProduct),
              _AvailabilityTab(product: mockProduct),
            ],
          ),
        ),
      ],
    );
    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, appBar: appBar, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, appBar: appBar, body: body);
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.productName});

  final String productName;

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
          Gap(context.responsive.spacingLg),
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
              '$productName Management',
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

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedTab});

  final ValueNotifier<int> selectedTab;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Details', 'Variants', 'Modifiers', 'Availability'];
    final isPhone = context.breakpoint.isPhone;

    Widget buildTabItem(int index, String title) {
      final isSelected = selectedTab.value == index;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => selectedTab.value = index,
            child: AnimatedContainer(
              duration: POSAnimation.fast,
              padding: EdgeInsets.symmetric(
                vertical: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                horizontal: isPhone ? context.responsive.spacingMd : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? ColorSet.primary.withValues(alpha: 0.06) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? ColorSet.primary : Colors.transparent,
                    width: context.responsive.value(kiosk: 3.0, tablet: 2.5, phone: 2.0),
                  ),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 15, tablet: 14, phone: 12),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? ColorSet.primary : POSColors.textTertiary,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final tabRow = Row(
      children: tabs.asMap().entries.map((e) => buildTabItem(e.key, e.value)).toList(),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: POSShadow.headerBottom,
      ),
      child: isPhone
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: tabRow,
            )
          : tabRow,
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.breakpoint.isPhone;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacingLg),
      child: isPhone
          ? Column(
              spacing: context.responsive.spacingLg,
              children: [_ProductImage(product: product), _BasicInfo(product: product)],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.responsive.spacingLg,
              children: [
                _ProductImage(product: product),
                Expanded(child: _BasicInfo(product: product)),
              ],
            ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.responsive.value(kiosk: 200, tablet: 160, phone: 120),
      height: context.responsive.value(kiosk: 200, tablet: 160, phone: 120),
      decoration: BoxDecoration(
        color: defaultProductPlaceholder.bg,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: product.image.isNotEmpty
            ? Image.memory(
                product.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      defaultProductPlaceholder.icon,
                      size: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                      color: defaultProductPlaceholder.fg,
                    ),
                    Gap(context.responsive.spacingSm),
                    Text(
                      'Image unavailable',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                        color: POSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    defaultProductPlaceholder.icon,
                    size: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                    color: defaultProductPlaceholder.fg,
                  ),
                  Gap(context.responsive.spacingSm),
                  Text(
                    'No Image',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                      color: POSColors.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BasicInfo extends StatelessWidget {
  const _BasicInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: context.responsive.spacingMd,
      children: [
        TextBoxFormField.singleLine(
          label: 'Product Name',
          initialValue: product.name,
          style: TextStyle(fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12)),
        ),
        TextBoxFormField(
          label: 'Description',
          initialValue: product.description,
          maxLines: 3,
          style: TextStyle(fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12)),
        ),
        TextBoxFormField.singleLine(
          label: 'Category',
          initialValue: 'Meals',
          style: TextStyle(fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12)),
        ),
        SizedBox(
          width: double.infinity,
          child: Button(
            label: const Text('Save Changes'),
            onPressed: () {
              // TODO: Save product details
            },
          ),
        ),
      ],
    );
  }
}

class _VariantsTab extends StatelessWidget {
  const _VariantsTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.breakpoint.isPhone;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacingLg),
      child: Column(
        spacing: context.responsive.spacingMd,
        children: [
          if (isPhone)
            Column(
              spacing: context.responsive.spacingMd,
              children: [
                _VariantCard(variant: product.variants.first, price: r'PHP 8.99', stock: 45),
                _VariantCard(variant: product.variants.last, price: r'PHP 10.99', stock: 23),
              ],
            )
          else
            Row(
              spacing: context.responsive.spacingMd,
              children: [
                Expanded(
                  child: _VariantCard(variant: product.variants.first, price: r'PHP 8.99', stock: 45),
                ),
                Expanded(
                  child: _VariantCard(variant: product.variants.last, price: r'PHP 10.99', stock: 23),
                ),
              ],
            ),
          SizedBox(
            width: double.infinity,
            child: Button(
              label: const Text('Add Variant'),
              leading: const Icon(Icons.add),
              onPressed: () {
                // TODO: Show add variant dialog
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.variant, required this.price, required this.stock});

  final ProductVariant variant;
  final String price;
  final int stock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        border: Border.all(color: POSColors.borderSubtle),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        spacing: context.responsive.spacingMd,
        children: [
          Text(
            variant.name,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
              fontWeight: FontWeight.w800,
              color: ColorSet.primary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Stock: $stock',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              color: POSColors.textSecondary,
            ),
          ),
          Row(
            spacing: context.responsive.spacingSm,
            children: [
              Expanded(
                child: Button(
                  label: const Text('Edit'),
                  onPressed: () {
                    // TODO: Edit variant
                  },
                ),
              ),
              Expanded(
                child: Button(
                  label: const Text('Stock'),
                  backgroundColor: POSColors.surfaceSubtle,
                  foregroundColor: POSColors.textPrimary,
                  onPressed: () {
                    // TODO: Manage stock
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModifiersTab extends StatelessWidget {
  const _ModifiersTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacingLg),
      child: Column(
        spacing: context.responsive.spacingLg,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Groups:',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
            ),
          ),
          _ModifierGroupCheckbox(name: 'Sides', count: 3, isSelected: true, onToggle: () {}),
          _ModifierGroupCheckbox(
            name: 'Drink Upgrades',
            count: 2,
            isSelected: true,
            onToggle: () {},
          ),
          _ModifierGroupCheckbox(
            name: 'Extra Toppings',
            count: 2,
            isSelected: false,
            onToggle: () {},
          ),
          Gap(context.responsive.spacingMd),
          Text(
            'Applied Groups:',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
            ),
          ),
          _AppliedModifierGroup(
            name: 'Sides',
            variants: const ['Regular', 'Large'],
            modifiers: const [r'Fries (+PHP 1.50)', r'Onion Rings (+PHP 2.00)', r'Salad (+PHP 1.00)'],
          ),
        ],
      ),
    );
  }
}

class _ModifierGroupCheckbox extends StatelessWidget {
  const _ModifierGroupCheckbox({
    required this.name,
    required this.count,
    required this.isSelected,
    required this.onToggle,
  });

  final String name;
  final int count;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => onToggle(),
            activeColor: ColorSet.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.xs)),
          ),
          Gap(context.responsive.spacingSm),
          Expanded(
            child: Text(
              '$name ($count modifiers)',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                color: POSColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedModifierGroup extends StatelessWidget {
  const _AppliedModifierGroup({
    required this.name,
    required this.variants,
    required this.modifiers,
  });

  final String name;
  final List<String> variants;
  final List<String> modifiers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        border: Border.all(color: POSColors.borderSubtle),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        spacing: context.responsive.spacingMd,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applied to: ${variants.join(', ')}',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              color: POSColors.textSecondary,
            ),
          ),
          Wrap(
            spacing: context.responsive.spacingSm,
            runSpacing: context.responsive.spacingSm,
            children: modifiers
                .map(
                  (modifier) => Chip(
                    label: Text(
                      modifier,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
                      ),
                    ),
                    backgroundColor: POSColors.surfaceSubtle,
                    side: const BorderSide(color: POSColors.borderDefault),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(POSRadius.sm),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(
            width: double.infinity,
            child: Button(
              label: const Text('Configure'),
              onPressed: () {
                // TODO: Configure modifier group
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityTab extends StatelessWidget {
  const _AvailabilityTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.responsive.spacingLg),
      child: Column(
        spacing: context.responsive.spacingLg,
        children: [
          _AvailabilitySetting(title: 'Product Status', value: 'Active', onToggle: () {}),
          _AvailabilitySetting(title: 'Low Stock Alert', value: '10 units', onToggle: () {}),
          _AvailabilitySetting(title: 'Out of Stock Behavior', value: 'Hide', onToggle: () {}),
        ],
      ),
    );
  }
}

class _AvailabilitySetting extends StatelessWidget {
  const _AvailabilitySetting({required this.title, required this.value, required this.onToggle});

  final String title;
  final String value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        border: Border.all(color: POSColors.borderSubtle),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.responsive.spacingSm,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                    color: POSColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Button(label: const Text('Change'), onPressed: onToggle),
        ],
      ),
    );
  }
}
