import 'package:flutter_rails_audit/src/audit_file.dart';
import 'package:flutter_rails_audit/src/finding.dart';
import 'package:test/test.dart';

List<Finding> _audit(String source, {int largeFileLines = 700}) =>
    auditSource('lib/a.dart', source, largeFileLines: largeFileLines).findings;

List<String> _rules(String source) =>
    _audit(source).map((f) => f.rule).toList();

void main() {
  test('return leaving finally can override a pending error', () {
    final findings = _audit('''
int f(bool stop) {
  try { throw StateError('failed'); } finally {
    if (stop) return 1;
  }
}
''');
    final hit = findings.singleWhere((f) => f.rule == 'return-in-finally');
    expect(hit.line, 3);
  });

  test('return in a cleanup closure belongs to that closure', () {
    expect(
      _rules('''
int f() {
  try { return 1; } finally {
    int inner() { return 2; }
    [1].map((x) { return inner(); }).toList();
  }
}
'''),
      isNot(contains('return-in-finally')),
    );
  });

  group('setstate-async-callback', () {
    test('flags an async closure passed to setState', () {
      final findings = _audit('''
class S extends State<W> {
  Future<void> f() async {
    setState(() async {
      await load();
    });
  }
}
''');
      final hit = findings.singleWhere(
        (f) => f.rule == 'setstate-async-callback',
      );
      expect(hit.priority, 'P1');
      expect(hit.line, 3);
    });

    test('ignores a synchronous setState callback', () {
      expect(
        _rules('''
class S extends State<W> {
  Future<void> f() async {
    final v = await load();
    setState(() { value = v; });
  }
}
'''),
        isNot(contains('setstate-async-callback')),
      );
    });
  });

  group('future-created-in-build', () {
    test('flags FutureBuilder(future: call()) inside build', () {
      expect(
        _rules('''
class W extends StatelessWidget {
  Widget build(BuildContext context) {
    return FutureBuilder<int>(future: load(), builder: (c, s) => const Text(''));
  }
}
'''),
        contains('future-created-in-build'),
      );
    });

    test('flags StreamBuilder(stream: call()) with const/new forms', () {
      expect(
        _rules('''
class W extends StatelessWidget {
  Widget build(BuildContext context) =>
      new StreamBuilder<int>(stream: repo.watch(), builder: (c, s) => const Text(''));
}
'''),
        contains('future-created-in-build'),
      );
    });

    test('ignores a cached future field', () {
      expect(
        _rules('''
class S extends State<W> {
  late final Future<int> _future = load();
  Widget build(BuildContext context) {
    return FutureBuilder<int>(future: _future, builder: (c, s) => const Text(''));
  }
}
'''),
        isNot(contains('future-created-in-build')),
      );
    });

    test('ignores lazy caching with ??=', () {
      expect(
        _rules('''
class S extends State<W> {
  Future<int>? _future;
  Widget build(BuildContext context) {
    return FutureBuilder<int>(future: _future ??= load(), builder: (c, s) => const Text(''));
  }
}
'''),
        isNot(contains('future-created-in-build')),
      );
    });

    test('ignores FutureBuilder outside build', () {
      expect(
        _rules('''
Widget helper() => FutureBuilder<int>(future: load(), builder: (c, s) => const Text(''));
'''),
        isNot(contains('future-created-in-build')),
      );
    });
  });

  group('undisposed-controller', () {
    test('flags a field controller the class creates and never disposes', () {
      final findings = _audit('''
class S extends State<W> {
  final TextEditingController name = TextEditingController();
  final ScrollController scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }
}
''');
      final hits = findings
          .where((f) => f.rule == 'undisposed-controller')
          .toList();
      expect(hits, hasLength(1));
      expect(hits.single.title, contains('name'));
      expect(hits.single.line, 2);
    });

    test('accepts fields assigned in initState and disposed via cascade/null-aware', () {
      expect(
        _rules('''
class S extends State<W> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  FocusNode? _focus;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)..forward();
    this._focus = FocusNode();
  }

  @override
  void dispose() {
    _anim..stop()..dispose();
    _focus?.dispose();
    super.dispose();
  }
}
'''),
        isNot(contains('undisposed-controller')),
      );
    });

    test('accepts disposal through a collection referenced in dispose()', () {
      expect(
        _rules('''
class S extends State<W> {
  final a = TextEditingController();
  final b = TextEditingController();

  @override
  void dispose() {
    for (final c in [a, b]) {
      c.dispose();
    }
    super.dispose();
  }
}
'''),
        isNot(contains('undisposed-controller')),
      );
    });

    test('ignores controllers injected through the constructor', () {
      expect(
        _rules('''
class Field extends StatelessWidget {
  const Field({required this.controller});
  final TextEditingController controller;
  Widget build(BuildContext context) => TextField(controller: controller);
}
'''),
        isNot(contains('undisposed-controller')),
      );
    });

    test('recognises named constructors and generic notifiers', () {
      final rules = _rules('''
class S extends State<W> {
  final t = TextEditingController.fromValue(null);
  final v = ValueNotifier<int>(0);
}
''');
      expect(rules.where((r) => r == 'undisposed-controller'), hasLength(2));
    });

    test('accepts close() for blocs and onClose() for GetX controllers', () {
      expect(
        _rules('''
class C extends GetxController {
  final search = TextEditingController();
  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
'''),
        isNot(contains('undisposed-controller')),
      );
    });
  });

  group('controller-created-in-build', () {
    test('local lazy initialization does not cache across builds', () {
      expect(
        _rules('''
class W extends StatelessWidget {
  Widget build(BuildContext context) {
    TextEditingController? controller;
    controller ??= TextEditingController();
    return TextField(controller: controller);
  }
}
'''),
        contains('controller-created-in-build'),
      );
    });

    test(
      'flags replacement even when only the last field value is disposed',
      () {
        expect(
          _rules('''
class S extends State<W> {
  TextEditingController? controller;
  Widget build(BuildContext context) {
    controller = TextEditingController();
    return TextField(controller: controller);
  }
  void dispose() { controller?.dispose(); super.dispose(); }
}
'''),
          contains('controller-created-in-build'),
        );
      },
    );

    test('flags a controller constructed inside build', () {
      expect(
        _rules('''
class W extends StatelessWidget {
  Widget build(BuildContext context) {
    final c = TextEditingController(text: 'x');
    return TextField(controller: c);
  }
}
'''),
        contains('controller-created-in-build'),
      );
    });

    test('accepts direct release immediately before field replacement', () {
      expect(
        _rules('''
class S extends State<W> with TickerProviderStateMixin {
  AnimationController? controller;
  Widget build(BuildContext context) {
    if (controller?.duration != d) {
      controller?.dispose();
      controller = AnimationController(duration: d, vsync: this)
        ..addStatusListener((s) {});
    }
    return const SizedBox();
  }
  void dispose() { controller?.dispose(); super.dispose(); }
}
'''),
        isNot(contains('controller-created-in-build')),
      );
    });

    test('still flags a fallback instance created inside build', () {
      expect(
        _rules('''
class S extends State<W> {
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: notifier ?? ValueNotifier<bool>(false), builder: b);
}
'''),
        contains('controller-created-in-build'),
      );
    });

    test('ignores lazy field init with ??= inside build', () {
      expect(
        _rules('''
class S extends State<W> {
  TextEditingController? _c;
  Widget build(BuildContext context) {
    return TextField(controller: _c ??= TextEditingController());
  }
  void dispose() { _c?.dispose(); super.dispose(); }
}
'''),
        isNot(contains('controller-created-in-build')),
      );
    });
  });

  group('uncancelled-periodic-timer', () {
    test('flags a timer field that is never cancelled', () {
      expect(
        _rules('''
class S extends State<W> {
  Timer? _timer;
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }
}
'''),
        contains('uncancelled-periodic-timer'),
      );
    });

    test('flags a discarded timer that never cancels itself', () {
      expect(
        _rules('''
void start() {
  Timer.periodic(const Duration(seconds: 1), (t) => tick());
}
'''),
        contains('uncancelled-periodic-timer'),
      );
    });

    test('accepts a timer field cancelled in dispose', () {
      expect(
        _rules('''
class S extends State<W> {
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  void dispose() { _timer.cancel(); super.dispose(); }
}
'''),
        isNot(contains('uncancelled-periodic-timer')),
      );
    });

    test('accepts a discarded timer that cancels itself in its callback', () {
      expect(
        _rules('''
void start() {
  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (done) timer.cancel();
  });
}
'''),
        isNot(contains('uncancelled-periodic-timer')),
      );
    });

    test('accepts a timer returned to the caller', () {
      expect(
        _rules('''
Timer start() => Timer.periodic(const Duration(seconds: 1), (_) => tick());
'''),
        isNot(contains('uncancelled-periodic-timer')),
      );
    });
  });

  group('file-level rules', () {
    test('flags ignore_for_file comments only', () {
      final findings = _audit('''
// ignore_for_file: avoid_print
const s = 'ignore_for_file: not a comment';
''');
      final hits = findings.where((f) => f.rule == 'filewide-lint-suppression');
      expect(hits, hasLength(1));
      expect(hits.single.line, 1);
    });

    test('flags large files over the threshold', () {
      final source = List.filled(12, 'int x = 0;').join('\n');
      expect(
        auditSource(
          'lib/a.dart',
          source,
          largeFileLines: 10,
        ).findings.map((f) => f.rule),
        contains('large-dart-file'),
      );
      expect(
        auditSource(
          'lib/a.dart',
          source,
          largeFileLines: 20,
        ).findings.map((f) => f.rule),
        isNot(contains('large-dart-file')),
      );
    });

    test('records navigation styles used by the file', () {
      final audit = auditSource('lib/a.dart', '''
void a(BuildContext context) {
  Navigator.of(context).push(route);
  Get.to(const Page());
  context.go('/home');
  router.go('/x');
}
''');
      expect(
        audit.navigationStyles.keys,
        unorderedEquals(['navigator', 'getx', 'go_router']),
      );
    });

    test('reports syntax errors but still audits the file', () {
      final audit = auditSource('lib/a.dart', '''
class S extends State<W> {
  void f() { setState(() async { await x(); }); }
  void broken( {
}
''');
      expect(audit.parseErrors, isNotEmpty);
      expect(
        audit.findings.map((f) => f.rule),
        contains('setstate-async-callback'),
      );
    });
  });

  group('false positives seen in TeikaDesk', () {
    test('ignores a notifier created in a provider create callback', () {
      expect(
        _rules('''
class W extends StatelessWidget {
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ValueNotifier(true),
        child: const SizedBox(),
      );
}
'''),
        isNot(contains('controller-created-in-build')),
      );
    });

    test('Navigator.pop plus context.go is not mixed navigation', () {
      final a = auditSource('lib/a.dart', '''
void f(BuildContext context) { Navigator.pop(context); context.go('/x'); }
''');
      expect(a.navigationStyles.keys, ['go_router']);
    });
  });
}
