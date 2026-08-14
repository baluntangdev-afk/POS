import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer_display/state/snapshot_debouncer.dart';

void main() {
  group('SnapshotDebouncer', () {
    test('collapses rapid successive schedule calls into a single callback', () {
      fakeAsync((async) {
        final debouncer = SnapshotDebouncer(delay: const Duration(milliseconds: 16));
        var callCount = 0;

        debouncer.schedule(() => callCount++);
        async.elapse(const Duration(milliseconds: 5));
        debouncer.schedule(() => callCount++);
        async.elapse(const Duration(milliseconds: 5));
        debouncer.schedule(() => callCount++);
        async.elapse(const Duration(milliseconds: 20));

        expect(callCount, 1);
      });
    });

    test('fires again for a schedule call after the previous delay elapsed', () {
      fakeAsync((async) {
        final debouncer = SnapshotDebouncer(delay: const Duration(milliseconds: 16));
        var callCount = 0;

        debouncer.schedule(() => callCount++);
        async.elapse(const Duration(milliseconds: 20));
        debouncer.schedule(() => callCount++);
        async.elapse(const Duration(milliseconds: 20));

        expect(callCount, 2);
      });
    });

    test('dispose cancels a pending call', () {
      fakeAsync((async) {
        final debouncer = SnapshotDebouncer(delay: const Duration(milliseconds: 16));
        var callCount = 0;

        debouncer.schedule(() => callCount++);
        debouncer.dispose();
        async.elapse(const Duration(milliseconds: 20));

        expect(callCount, 0);
      });
    });
  });
}
