import 'dart:io';

import 'package:flutter_rails_audit/src/audit_project.dart';
import 'package:flutter_rails_audit/src/slop_score.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  Future<void> put(String rel, String content) async {
    final f = File(p.join(root.path, rel));
    await f.create(recursive: true);
    await f.writeAsString(content);
  }

  Future<ProjectReport> audit({bool resolve = false, bool score = false}) =>
      auditProject(
        root.path,
        [p.join(root.path, 'lib')],
        resolve: resolve,
        score: score,
      );

  setUp(() async => root = await Directory.systemTemp.createTemp('rails_'));
  tearDown(() => root.delete(recursive: true));

  group('cross-file ownership', () {
    setUp(() async {
      await put(
        'lib/ctl.dart',
        'class AppScroll extends ScrollController {}\n',
      );
      await put('lib/ctl2.dart', 'class Deep extends AppScroll {}\n');
      await put('lib/s.dart', '''
class S extends State<W> {
  final a = Deep();
  final b = Plain();
}
''');
    });

    test(
      'project subclasses of a disposable are found (project-index)',
      () async {
        final r = await audit();
        final hit = r.findings.singleWhere(
          (f) => f.rule == 'undisposed-controller',
        );
        expect(hit.basis, 'project-index');
        expect(hit.title, contains('Deep'));
        expect(r.resolution, startsWith('syntax-only'));
      },
    );

    test('resolved types are used when dependencies are prepared', () async {
      await put('pubspec.yaml', 'name: t\nenvironment:\n  sdk: ^3.0.0\n');
      await put(
        '.dart_tool/package_config.json',
        '{"configVersion":2,"packages":[{"name":"t","rootUri":"../",'
            '"packageUri":"lib/","languageVersion":"3.0"}]}',
      );
      await put('lib/base.dart', 'class ScrollController {}\n');
      await put('lib/ctl.dart', '''
import 'base.dart';
class AppScroll extends ScrollController {}
''');
      await put('lib/ctl2.dart', '''
import 'ctl.dart';
class Deep extends AppScroll {}
''');
      await put('lib/s.dart', '''
import 'ctl2.dart';
class S {
  final a = Deep();
}
''');
      final r = await audit(resolve: true);
      expect(r.resolution, 'resolved');
      expect(
        r.findings
            .where((f) => f.basis == 'resolved-types')
            .map((f) => f.title),
        contains(contains('Deep')),
      );
    });
  });

  test(
    'resolved: a static lookup returning a disposable is not a creation',
    () async {
      await put('pubspec.yaml', 'name: t\nenvironment:\n  sdk: ^3.0.0\n');
      await put(
        '.dart_tool/package_config.json',
        '{"configVersion":2,"packages":[{"name":"t","rootUri":"../",'
            '"packageUri":"lib/","languageVersion":"3.0"}]}',
      );
      await put('lib/s.dart', '''
class TabController {}
class Default {
  static TabController of(int c) => TabController();
}
class S {
  Object build(int c) { final t = Default.of(c); return t; }
}
''');
      final r = await audit(resolve: true);
      expect(r.resolution, 'resolved');
      expect(
        r.findings.where((f) => f.rule == 'controller-created-in-build'),
        isEmpty,
      );
    },
  );

  group('anti-slop score', () {
    Future<SlopDimension> dim(String name) async {
      final r = await audit(score: true);
      return r.slop!.dimensions.firstWhere((d) => d.name == name);
    }

    test('does not penalize a huge widget file', () async {
      final children = List.generate(400, (i) => "Text('t$i')").join(',\n');
      await put('lib/big.dart', '''
class Big extends StatelessWidget {
  Widget build(BuildContext context) => Column(children: [
$children
  ]);
}
''');
      final r = await audit(score: true);
      for (final d in r.slop!.dimensions) {
        expect(d.items ?? const [], isEmpty, reason: d.name);
      }
    });

    test('duplication: equal bodies after renaming identifiers', () async {
      final body = List.generate(30, (i) => 'print(a$i + 1);').join('\n');
      await put('lib/a.dart', 'void f(int a0) {\n$body\n}\n');
      await put('lib/b.dart', 'void g(int a0) {\n$body\n}\n');
      expect((await dim('duplication')).items, hasLength(2));
    });

    test('complexity above the limit is reported', () async {
      final ifs = List.generate(
        complexityLimit + 1,
        (i) => 'if (x == $i) y++;',
      );
      await put('lib/c.dart', 'void f(int x, int y) {\n${ifs.join('\n')}\n}\n');
      expect((await dim('complexity')).items!.single.title, contains('f:'));
    });

    test('copyWith is excluded from complexity', () async {
      final fields = List.generate(
        complexityLimit + 1,
        (i) => 'a$i ?? this.a$i',
      );
      await put(
        'lib/m.dart',
        'class M {\n  M copyWith() => M(${fields.join(', ')});\n}\n',
      );
      expect((await dim('complexity')).items, isEmpty);
    });

    test(
      'mixed responsibilities: widget I/O and view model BuildContext',
      () async {
        await put('lib/w.dart', '''
class W extends StatelessWidget {
  Widget build(BuildContext c) { final d = Dio(); return Text(''); }
}
class VM extends BaseViewModel {
  void go(BuildContext context) {}
}
''');
        expect((await dim('mixed-responsibilities')).items, hasLength(2));
      },
    );

    test('useless layer: pure forwarding class without contract', () async {
      await put('lib/r.dart', '''
class Wrap {
  final R _r = R();
  int a(int x) => _r.a(x);
  int b() { return _r.b(); }
}
class Real {
  final R _r = R();
  int a(int x) => _r.a(x);
  int b() => _r.b() + 1;
}
class Impl implements Contract {
  final R _r = R();
  int a(int x) => _r.a(x);
  int b() => _r.b();
}
''');
      final items = (await dim('useless-layers')).items!;
      expect(items.single.title, startsWith('Wrap'));
    });

    test(
      'dependencies and tests are measured, N/E when nothing to measure',
      () async {
        await put(
          'lib/x.dart',
          "import 'package:used/used.dart';\nclass XRepository {}\n",
        );
        await put(
          'pubspec.yaml',
          'name: t\ndependencies:\n  flutter:\n    sdk: flutter\n  used: ^1.0.0\n  unused: ^1.0.0\n',
        );
        expect(
          (await dim('dependencies')).items!.single.title,
          contains('unused'),
        );
        expect((await dim('tests')).items, hasLength(1));
        await put(
          'test/x_test.dart',
          "import 'package:t/x.dart';\nvoid main() {}\n",
        );
        expect((await dim('tests')).items, isEmpty);
      },
    );

    test('no pubspec and no logic classes: not evaluated', () async {
      await put('lib/y.dart', 'class Y {}\n');
      expect((await dim('dependencies')).grade, isNull);
      expect((await dim('tests')).grade, isNull);
    });
  });
}
