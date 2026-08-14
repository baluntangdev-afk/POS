import 'package:dart_mappable/dart_mappable.dart';
import 'package:decimal/decimal.dart';

import '../../sales/entities/line_item.dart';
import '../../sales/entities/receipt.dart';
import '../../sales/entities/sale.dart';
import '../../sales/entities/store.dart';
import 'customer_display_mappers.dart';

part 'customer_display_snapshot.mapper.dart';

@MappableClass()
sealed class CustomerDisplaySnapshot with CustomerDisplaySnapshotMappable {
  const CustomerDisplaySnapshot();
}

/// dart_mappable's polymorphic decode-via-discriminator for sealed classes
/// (`CustomerDisplaySnapshotMapper.fromMap`, and the base `Mapper.fromMap`
/// this project's existing `Payment` sealed hierarchy also generates) only
/// ever resolves the *first*-registered subtype in this project's installed
/// dart_mappable version (4.6.1) — every other subtype fails to decode with
/// "no valid constructor found" even though the encoded map's discriminator
/// field is present and correct. Verified directly against `Payment` too
/// (same failure on `ZeroPayment`, its last-declared subtype), so this is a
/// pre-existing limitation of this project's dart_mappable setup, not
/// something specific to this file. Each concrete subtype's own generated
/// `toMap()`/`fromMap()` works correctly on its own (non-polymorphic)
/// though, so encode/decode here dispatch manually with an explicit `type`
/// tag instead of going through the sealed base type's discriminator.
extension CustomerDisplaySnapshotEncoding on CustomerDisplaySnapshot {
  Map<String, dynamic> toTransportMap() {
    ensureCustomerDisplayMappersRegistered();
    final self = this;
    final String type;
    final Map<String, dynamic> fields;
    if (self is CustomerDisplayIdle) {
      type = 'idle';
      fields = self.toMap();
    } else if (self is CustomerDisplayOrdering) {
      type = 'ordering';
      fields = self.toMap();
    } else if (self is CustomerDisplayThankYou) {
      type = 'thankYou';
      fields = self.toMap();
    } else {
      throw StateError('Unhandled CustomerDisplaySnapshot subtype: $runtimeType');
    }
    return {'type': type, ...fields};
  }
}

/// Decode counterpart to [CustomerDisplaySnapshotEncoding.toTransportMap].
/// Takes the raw `call.arguments` from the platform channel directly (not
/// pre-cast) — see [normalizeChannelMap] for why that matters.
CustomerDisplaySnapshot decodeCustomerDisplaySnapshot(Object? channelArguments) {
  ensureCustomerDisplayMappersRegistered();
  final map = normalizeChannelMap(channelArguments);
  final fields = Map<String, dynamic>.from(map)..remove('type');
  return switch (map['type']) {
    'idle' => CustomerDisplayIdleMapper.fromMap(fields),
    'ordering' => CustomerDisplayOrderingMapper.fromMap(fields),
    'thankYou' => CustomerDisplayThankYouMapper.fromMap(fields),
    final other => throw ArgumentError('Unknown CustomerDisplaySnapshot type: $other'),
  };
}

@MappableClass()
class CustomerDisplayIdle extends CustomerDisplaySnapshot with CustomerDisplayIdleMappable {
  const CustomerDisplayIdle({required this.storeName, this.storeLogo});

  factory CustomerDisplayIdle.fromStore(Store store) {
    return CustomerDisplayIdle(storeName: store.legalName, storeLogo: store.logo);
  }

  final String storeName;
  final String? storeLogo;
}

@MappableClass()
class CustomerDisplayOrdering extends CustomerDisplaySnapshot with CustomerDisplayOrderingMappable {
  const CustomerDisplayOrdering({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });

  factory CustomerDisplayOrdering.fromSale(Sale sale) {
    return CustomerDisplayOrdering(
      items: sale.items.map(CustomerDisplayLineItem.fromLineItem).toList(),
      subtotal: sale.grossAmount,
      discount: sale.discountAmount,
      tax: sale.vatAmount,
      total: sale.totalAmount,
    );
  }

  final List<CustomerDisplayLineItem> items;
  final Decimal subtotal;
  final Decimal discount;
  final Decimal tax;
  final Decimal total;
}

@MappableClass()
class CustomerDisplayThankYou extends CustomerDisplaySnapshot with CustomerDisplayThankYouMappable {
  const CustomerDisplayThankYou({required this.docNumber});

  factory CustomerDisplayThankYou.fromReceipt(Receipt receipt) {
    return CustomerDisplayThankYou(docNumber: receipt.docNumber);
  }

  final String docNumber;
}

@MappableClass()
class CustomerDisplayLineItem with CustomerDisplayLineItemMappable {
  const CustomerDisplayLineItem({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.discountAmount,
    this.variantLabel,
    this.discountLabel,
  });

  factory CustomerDisplayLineItem.fromLineItem(LineItem item) {
    final modifiersPrice = item.modifiers.fold(
      Decimal.zero,
      (total, modifier) => total + modifier.price,
    );
    return CustomerDisplayLineItem(
      productName: item.productName,
      quantity: item.quantity,
      variantLabel: item.variant.name,
      lineTotal: Decimal.fromInt(item.quantity) * (item.variant.price + modifiersPrice),
      discountLabel: item.discount?.code,
      discountAmount: item.discountAmount,
    );
  }

  final String productName;
  final int quantity;
  final String? variantLabel;
  final Decimal lineTotal;
  final String? discountLabel;
  final Decimal discountAmount;
}
