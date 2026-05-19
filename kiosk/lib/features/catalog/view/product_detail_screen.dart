import 'dart:typed_data';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/button.dart';
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
      variants: IList([
        const ProductVariant(id: 1, name: 'Regular', isDefault: true),
        const ProductVariant(id: 2, name: 'Large', isDefault: false),
      ]),
    );

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: _TopAppBar(productName: mockProduct.name),
      ),
      body: Column(
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
      ),
    );
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
          Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
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
              '$productName Management',
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

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedTab});

  final ValueNotifier<int> selectedTab;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Details', 'Variants', 'Modifiers', 'Availability'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children:
            tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              final isSelected = selectedTab.value == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => selectedTab.value = index,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? ColorSet.primary.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? ColorSet.primary : Colors.transparent,
                          width: context.responsive.value(kiosk: 3, tablet: 2, phone: 2),
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? ColorSet.primary : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
        children: [_ProductImage(product: product), _BasicInfo(product: product)],
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        child:
            product.image.isNotEmpty
                ? Image.memory(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                          color: Colors.grey.shade400,
                        ),
                        Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                        Text(
                          'Image unavailable',
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: context.responsive.value(kiosk: 48, tablet: 40, phone: 32),
                      color: Colors.grey.shade400,
                    ),
                    Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                    Text(
                      'No Image',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                        color: Colors.grey.shade500,
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
      spacing: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
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
    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          Row(
            spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
            children: [
              Expanded(
                child: _VariantCard(variant: product.variants.first, price: '\$8.99', stock: 45),
              ),
              Expanded(
                child: _VariantCard(variant: product.variants.last, price: '\$10.99', stock: 23),
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
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Text(
            variant.name,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 20, tablet: 18, phone: 16),
              fontWeight: FontWeight.w700,
              color: ColorSet.primary,
            ),
          ),
          Text(
            'Stock: $stock',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              color: Colors.grey.shade600,
            ),
          ),
          Row(
            spacing: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
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
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
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
    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Groups:',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
          const Gap(16),
          Text(
            'Applied Groups:',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18, tablet: 16, phone: 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          _AppliedModifierGroup(
            name: 'Sides',
            variants: ['Regular', 'Large'],
            modifiers: ['Fries (+\$1.50)', 'Onion Rings (+\$2.00)', 'Salad (+\$1.00)'],
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
          Checkbox(value: isSelected, onChanged: (_) => onToggle(), activeColor: ColorSet.primary),
          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
          Expanded(
            child: Text(
              '$name ($count modifiers)',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                color: Colors.black87,
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
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applied to: ${variants.join(', ')}',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
              color: Colors.grey.shade600,
            ),
          ),
          Wrap(
            spacing: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
            runSpacing: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
            children:
                modifiers
                    .map(
                      (modifier) => Chip(
                        label: Text(
                          modifier,
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
                          ),
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
    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
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
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 10),
                    color: Colors.grey.shade600,
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
