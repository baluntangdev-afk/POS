// kiosk/lib/features/reports/services/daily_export_scheduler.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/shared_preferences/shared_preferences.dart';
import '../state/export_notifier.dart';

final dailyExportSchedulerProvider = NotifierProvider<DailyExportScheduler, void>(
  DailyExportScheduler.new,
);

class DailyExportScheduler extends Notifier<void> {
  static const _prefKey = 'daily_export_last_date';

  Timer? _timer;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastExportStr = await prefs.getString(_prefKey);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    if (lastExportStr == null || lastExportStr != todayStr) {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      await _runExport(yesterday);
    }

    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _timer = Timer(duration, _onMidnight);
  }

  Future<void> _onMidnight() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await _runExport(yesterday);
    _scheduleNextMidnight();
  }

  Future<void> _runExport(DateTime date) async {
    try {
      final success = await ref.read(exportNotifierProvider.notifier).export(date);
      if (success) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(
          _prefKey,
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('[DailyExportScheduler] Auto-export failed: $e');
    }
  }
}
