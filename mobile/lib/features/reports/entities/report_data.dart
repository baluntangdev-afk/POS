import 'dart:convert';

import '../../../core/database/app_database.dart';

class PaymentBreakdown {
  final String method;
  final double total;
  final double percentage;

  const PaymentBreakdown({
    required this.method,
    required this.total,
    required this.percentage,
  });

  String get displayName => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };
}

class NameAmount {
  final String name;
  final double amount;
  const NameAmount({required this.name, required this.amount});
}

class PaymentLedgerEntry {
  final DateTime time;
  final String? reference;
  final double amount;
  const PaymentLedgerEntry({required this.time, required this.reference, required this.amount});
}

class PaymentLedgerDateGroup {
  final DateTime date;
  final List<PaymentLedgerEntry> entries;
  const PaymentLedgerDateGroup({required this.date, required this.entries});
}

/// Itemized per-payment-method ledger: every individual payment in the
/// period, groupable by calendar date. Mirrors kiosk's `PaymentLedger`.
class PaymentLedger {
  final String method;
  final List<PaymentLedgerEntry> entries;
  final double total;
  final int count;

  const PaymentLedger({
    required this.method,
    required this.entries,
    required this.total,
    required this.count,
  });

  String get displayName => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };

  /// Entries grouped by local calendar date, oldest date first.
  List<PaymentLedgerDateGroup> get entriesByDate {
    final groups = <DateTime, List<PaymentLedgerEntry>>{};
    for (final entry in entries) {
      final local = entry.time.toLocal();
      final dateKey = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = groups.keys.toList()..sort();
    return [
      for (final date in sortedDates)
        PaymentLedgerDateGroup(date: date, entries: groups[date]!..sort((a, b) => a.time.compareTo(b.time))),
    ];
  }

  static String encodeList(List<PaymentLedger> ledgers) => jsonEncode(ledgers
      .map((l) => {
            'method': l.method,
            'entries': l.entries
                .map((e) => {
                      'time': e.time.toIso8601String(),
                      'reference': e.reference,
                      'amount': e.amount,
                    })
                .toList(),
          })
      .toList());

  static List<PaymentLedger> decodeList(String json) {
    return (jsonDecode(json) as List).map((l) {
      final entries = (l['entries'] as List)
          .map((e) => PaymentLedgerEntry(
                time: DateTime.parse(e['time'] as String),
                reference: e['reference'] as String?,
                amount: (e['amount'] as num).toDouble(),
              ))
          .toList();
      return PaymentLedger(
        method: l['method'] as String,
        entries: entries,
        total: entries.fold(0.0, (s, e) => s + e.amount),
        count: entries.length,
      );
    }).toList();
  }
}

class TopProductData {
  final String name;
  final int quantity;
  final double total;
  const TopProductData({required this.name, required this.quantity, required this.total});
}

class ReportData {
  final double totalSales;
  final int transactionCount;
  final double averageOrder;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<TopProductData> topProducts;
  final List<SalesTableData> recentSales;
  final DateTime from;
  final DateTime to;

  const ReportData({
    required this.totalSales,
    required this.transactionCount,
    required this.averageOrder,
    required this.paymentBreakdown,
    required this.topProducts,
    required this.recentSales,
    required this.from,
    required this.to,
  });
}
