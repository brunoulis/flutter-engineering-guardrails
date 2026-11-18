import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int value = 0;

  Future<void> increment() async {
    value++;
  }

  void inline() => setState(() async {
        value++;
      });
  void named() => setState(increment);
  void forwarded() => super.setState(() => increment());

  Future<void> afterWork() async {
    await Future<void>.value();
    if (!mounted) return;
    setState(() {
      value++;
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _AsyncStore {
  int value = 0;
  Future<void> setState(Future<void> Function() update) => update();
  Future<void> increment() => setState(() async {
        value++;
      });
}

void main() {
  testWidgets('State checks the callback result in debug mode', (tester) async {
    await tester.pumpWidget(const _Probe());
    final state = tester.state<_ProbeState>(find.byType(_Probe));
    final returnsFuture = throwsA(isA<FlutterError>().having(
      (error) => error.toString(),
      'diagnostic',
      contains('callback argument returned a Future'),
    ));
    expect(state.inline, returnsFuture);
    expect(state.named, returnsFuture);
    expect(state.forwarded, returnsFuture);
    await state.afterWork();
    await tester.pump();
    expect(state.value, 4);
  });

  test('a separate API can await callbacks with the same method name',
      () async {
    final store = _AsyncStore();
    await store.increment();
    expect(store.value, 1);
  });
}
