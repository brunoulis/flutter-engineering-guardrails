import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget resultView(Future<String> future) => FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) => Text(
        snapshot.hasError ? 'error' : snapshot.data ?? 'loading',
        textDirection: TextDirection.ltr,
      ),
    );

void main() {
  for (final staleFails in [false, true]) {
    testWidgets('FutureBuilder ignores stale completion (error: $staleFails)', (
      tester,
    ) async {
      final first = Completer<String>();
      final second = Completer<String>();
      await tester.pumpWidget(resultView(first.future));
      await tester.pumpWidget(resultView(second.future));
      expect(find.text('loading'), findsOneWidget);
      second.complete('B');
      await tester.pump(Duration.zero);
      expect(find.text('B'), findsOneWidget);
      if (staleFails) {
        first.completeError(Exception('old request'));
      } else {
        first.complete('A');
      }
      await tester.pump(Duration.zero);
      expect(find.text('B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('FutureBuilder can unmount while its future is pending', (
    tester,
  ) async {
    final pending = Completer<String>();
    await tester.pumpWidget(resultView(pending.future));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete('late');
    await tester.pump(Duration.zero);
    expect(tester.takeException(), isNull);
    expect(find.text('late'), findsNothing);
  });
}
