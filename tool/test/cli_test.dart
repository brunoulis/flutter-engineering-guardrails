import 'dart:convert';
import 'dart:io';

import 'package:flutter_rails_audit/src/cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rails_audit_');
    await File(p.join(root.path, 'lib', 'a.dart')).create(recursive: true);
    await File(p.join(root.path, 'lib', 'a.dart')).writeAsString('''
class S extends State<W> {
  final c = TextEditingController();
  void f() { Navigator.of(context).pop(); }
}
''');
    await File(p.join(root.path, 'lib', 'b.dart')).writeAsString('''
void g(BuildContext context) => context.go('/');
''');
    await File(p.join(root.path, 'lib', 'model.g.dart')).writeAsString('''
final generated = TextEditingController();
''');
    await File(p.join(root.path, 'lib', 'build', 'x.dart'))
        .create(recursive: true);
    await File(p.join(root.path, 'lib', 'build', 'x.dart'))
        .writeAsString('final y = ScrollController();');
  });

  tearDown(() => root.delete(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(args, out: out, err: err);
    return (code, out.toString(), err.toString());
  }

  test(
    'json report: findings, mixed navigation, generated/build excluded',
    () async {
      final (code, out, _) = await run([
        '--root',
        root.path,
        '--format',
        'json',
      ]);
      expect(code, 0);
      final report = jsonDecode(out) as Map<String, Object?>;
      expect(report['scanned_files'], 2);
      final findings = (report['findings'] as List<Object?>)
          .cast<Map<String, Object?>>();
      final rules = findings.map((f) => f['rule']).toList();
      expect(rules, contains('undisposed-controller'));
      expect(rules.where((r) => r == 'mixed-navigation-styles'), hasLength(2));
      expect(findings.every((f) => f['path'] != 'lib/model.g.dart'), isTrue);
      expect(
        findings.every((f) => !(f['path'] as String).contains('build/')),
        isTrue,
      );
      expect(findings.first['confidence'], 'heuristic');
    },
  );

  test('text report ends with the caveat', () async {
    final (code, out, _) = await run(['--root', root.path]);
    expect(code, 0);
    expect(out, contains('[P2] undisposed-controller | lib/a.dart:2'));
    expect(out, contains('NOT confirmed bugs'));
  });

  test('--output writes the report to a file', () async {
    final dest = p.join(root.path, 'out', 'audit.json');
    final (code, out, _) = await run([
      '--root',
      root.path,
      '--format',
      'json',
      '--output',
      dest,
    ]);
    expect(code, 0);
    expect(out, contains('Report written to'));
    expect(
      jsonDecode(await File(dest).readAsString()),
      isA<Map<String, Object?>>(),
    );
  });

  test('rejects a --path that escapes --root', () async {
    final (code, _, err) = await run(['--root', root.path, '--path', '..']);
    expect(code, 64);
    expect(err, contains('escapes'));
  });

  test('usage errors go to stderr with exit 64', () async {
    final (code, out, err) = await run(['--format', 'xml']);
    expect(code, 64);
    expect(out, isEmpty);
    expect(err, contains('Usage'));
  });

  test('--help prints usage to stdout with exit 0', () async {
    final (code, out, _) = await run(['--help']);
    expect(code, 0);
    expect(out, contains('--root'));
  });

  test('missing root is a usage error', () async {
    final (code, _, err) = await run([
      '--root',
      p.join(root.path, 'does-not-exist'),
    ]);
    expect(code, 64);
    expect(err, contains('root'));
  });
}
