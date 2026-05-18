import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/enums/sales_order_type.dart';
import '../../../data/backend_api/schemas/apply_discount_item_discount_dto.dart';
import '../../../data/backend_api/schemas/create_sales_order_dto.dart';
import '../../../data/backend_api/schemas/create_sales_order_item_dto.dart';
import '../../../data/backend_api/schemas/create_sales_order_modifier_group_dto.dart';
import '../../../data/backend_api/schemas/create_sales_order_modifier_option_dto.dart';
import '../../../data/backend_api/sources/sales_orders_api.dart';
import '../entities/discount.dart';
import '../entities/line_item.dart';
import '../entities/sale.dart';
import '../entities/selected_modifier.dart';
import '../entities/selected_option.dart';
import '../enums/sale_type.dart';

abstract class SaleRepository {
  Future<Sale> save(Sale sale);
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final api = ref.watch(salesOrdersApiProvider);
  return SaleRepositoryImpl(api);
});

class SaleRepositoryImpl implements SaleRepository {
  const SaleRepositoryImpl(this._salesOrdersApi);

  final SalesOrdersApi _salesOrdersApi;

  @override
  Future<Sale> save(Sale sale) async {
    final request = _createSalesOrderDtoFromSale(sale);
    final response = await _salesOrdersApi.create(request);
    return sale.copyWith(id: response.id, soNumber: response.soNumber);
  }

  CreateSalesOrderDto _createSalesOrderDtoFromSale(Sale sale) {
    return CreateSalesOrderDto(
      soType: _salesOrderTypeFromSaleType(sale.type),
      products: sale.items.map(_createSalesOrderItemDtoFromLineItem).toList(),
    );
  }

  SalesOrderType _salesOrderTypeFromSaleType(SaleType type) {
    return switch (type) {
      SaleType.dineIn => SalesOrderType.dineIn,
      SaleType.takeOut => SalesOrderType.takeOut,
      SaleType.delivery => SalesOrderType.delivery,
    };
  }

  CreateSalesOrderItemDto _createSalesOrderItemDtoFromLineItem(LineItem item) {
    return CreateSalesOrderItemDto(
      productVariantId: item.variant.id,
      quantity: item.quantity,
      price: item.variant.price.toDouble(),
      modifierGroups:
          item.modifiers.map(_createSalesOrderModifierGroupDtoFromSelectedModifier).toList(),
      discount: _applyDiscountItemDiscountDtoFromDiscount(item.discount),
    );
  }

  CreateSalesOrderModifierGroupDto _createSalesOrderModifierGroupDtoFromSelectedModifier(
    SelectedModifier modifier,
  ) {
    return CreateSalesOrderModifierGroupDto(
      id: modifier.id,
      modifierOptions:
          modifier.options.map(_createSalesOrderModifierOptionDtoFromSelectedOption).toList(),
    );
  }

  CreateSalesOrderModifierOptionDto _createSalesOrderModifierOptionDtoFromSelectedOption(
    SelectedOption option,
  ) {
    return CreateSalesOrderModifierOptionDto(id: option.id, priceAddOn: option.price.toDouble());
  }

  ApplyDiscountItemDiscountDto? _applyDiscountItemDiscountDtoFromDiscount(Discount? discount) {
    return switch (discount) {
      SeniorPwdDiscount(:final code, :final rate) => ApplyDiscountItemDiscountDto(
        id: 1,
        name: code,
        value: rate.toDouble(),
      ),
      _ => null,
    };
  }
}
