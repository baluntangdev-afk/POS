import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/customer_display_snapshot.dart';
import '../state/customer_display_receiver.dart';
import 'idle_customer_view.dart';
import 'order_customer_view.dart';
import 'thank_you_customer_view.dart';

class CustomerDisplayPage extends ConsumerWidget {
  const CustomerDisplayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(customerDisplaySnapshotProvider);
    final catalog = ref.watch(customerDisplayCatalogProvider);
    return Scaffold(
      body: switch (snapshot) {
        CustomerDisplayIdle() => IdleCustomerView(snapshot: snapshot, catalog: catalog),
        CustomerDisplayOrdering() => OrderCustomerView(snapshot: snapshot, catalog: catalog),
        CustomerDisplayThankYou() => ThankYouCustomerView(snapshot: snapshot),
      },
    );
  }
}
