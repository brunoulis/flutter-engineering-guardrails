// Executable Dart API examples, not additional audit-tool detection coverage.
// See references/dart-evidence.md for sources, scope and reproduction commands.
import 'dart:async';
import 'dart:collection';

import 'package:test/test.dart';

void main() {
  group('collection ownership', () {
    test('final prevents rebinding, not mutation', () {
      final values = <int>[1];
      values.add(2);
      expect(values, [1, 2]);
    });

    test('unmodifiable snapshot and live view have different contracts', () {
      final source = <int>[1];
      final snapshot = List<int>.unmodifiable(source);
      final view = UnmodifiableListView(source);
      source.add(2);
      expect(snapshot, [1]);
      expect(view, [1, 2]);
      expect(() => snapshot.add(3), throwsUnsupportedError);
      expect(() => view.add(3), throwsUnsupportedError);
    });

    test('an unmodifiable outer list does not freeze its elements', () {
      final nested = <int>[1];
      final snapshot = List<List<int>>.unmodifiable([nested]);
      nested.add(2);
      expect(snapshot.single, [1, 2]);
    });
  });

  group('future completion is not operation cancellation', () {
    test(
      'timeout leaves the original operation able to commit effects',
      () async {
        final release = Completer<void>();
        var committed = false;
        final operation = release.future.then((_) => committed = true);

        // Zero is an event-loop deadline, not a sleep or speed assertion.
        await expectLater(
          operation.timeout(Duration.zero),
          throwsA(isA<TimeoutException>()),
        );
        expect(committed, isFalse);
        release.complete();
        await operation;
        expect(committed, isTrue);
      },
    );

    test('eagerError reports early but does not cancel sibling work', () async {
      final failure = Completer<int>();
      final release = Completer<void>();
      var committed = false;
      final sibling = release.future.then((_) {
        committed = true;
        return 2;
      });
      final observed = expectLater(
        Future.wait([failure.future, sibling], eagerError: true),
        throwsStateError,
      );
      failure.completeError(StateError('failed'));
      await observed;
      expect(committed, isFalse);
      release.complete();
      await sibling;
      expect(committed, isTrue);
    });

    test(
      'wait cleanup also receives successful values arriving after error',
      () async {
        final failure = Completer<String>();
        final success = Completer<String>();
        final cleaned = Completer<String>();
        final observed = expectLater(
          Future.wait(
            [failure.future, success.future],
            eagerError: true,
            cleanUp: cleaned.complete,
          ),
          throwsStateError,
        );
        failure.completeError(StateError('failed'));
        await observed;
        success.complete('owned-resource');
        expect(await cleaned.future, 'owned-resource');
      },
    );

    test('unawaited does not install an error handler', () async {
      final observed = Completer<Object>();
      runZonedGuarded(
        () {
          unawaited(Future<void>.error(StateError('background failure')));
        },
        (error, stack) {
          observed.complete(error);
        },
      );
      expect(await observed.future, isA<StateError>());
    });
  });

  group('stream work and shutdown', () {
    test('listen does not wait for async event callbacks', () async {
      final release = Completer<void>();
      final delivered = Completer<void>();
      final finished = Completer<void>();
      final started = <int>[];
      final completed = <int>[];
      final subscription = Stream.fromIterable([1, 2]).listen((value) async {
        started.add(value);
        await release.future;
        completed.add(value);
        if (completed.length == 2) finished.complete();
      }, onDone: delivered.complete);
      await delivered.future;
      expect(started, [1, 2]);
      expect(completed, isEmpty);
      release.complete();
      await finished.future;
      await subscription.cancel();
    });

    test(
      'asyncMap serializes conversions without adding a worker pool',
      () async {
        final firstStarted = Completer<void>();
        final release = Completer<void>();
        var active = 0;
        var maxActive = 0;
        final result = Stream.fromIterable([1, 2]).asyncMap((value) async {
          active++;
          if (active > maxActive) maxActive = active;
          if (value == 1) {
            firstStarted.complete();
            await release.future;
          }
          active--;
          return value * 2;
        }).toList();
        await firstStarted.future;
        release.complete();
        expect(await result, [2, 4]);
        expect(maxActive, 1);
      },
    );

    test('cancel completes only after asynchronous source cleanup', () async {
      final release = Completer<void>();
      var cleanupStarted = false;
      var cleanupFinished = false;
      final controller = StreamController<int>(
        onCancel: () async {
          cleanupStarted = true;
          await release.future;
          cleanupFinished = true;
        },
      );
      final subscription = controller.stream.listen((_) {});
      final cancelled = subscription.cancel();
      expect(cleanupStarted, isTrue);
      expect(cleanupFinished, isFalse);
      release.complete();
      await cancelled;
      expect(cleanupFinished, isTrue);
      await controller.close();
    });
  });
}
