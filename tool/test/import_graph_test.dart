import 'dart:io';

import 'package:flutter_rails_audit/src/import_graph.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('rails_graph_');
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: app\n');
  });
  tearDown(() => root.delete(recursive: true));

  test('cross-directory cycle is P2, sibling cycle P3, DAG is clean', () {
    final f = auditImportGraph(root.path, {
      'lib/data/a.dart': "import 'package:app/ui/b.dart';",
      'lib/ui/b.dart': "import '../data/a.dart';",
      'lib/ui/c.dart': "import 'd.dart';",
      'lib/ui/d.dart': "import 'c.dart'; import 'dart:io';",
      'lib/ui/e.dart': "import 'c.dart'; import 'package:other/x.dart';",
    });
    final byPath = {for (final x in f) x.path: x};
    expect(f.where((x) => x.rule == 'import-cycle'), hasLength(2));
    expect(byPath['lib/data/a.dart']!.priority, 'P2');
    expect(byPath['lib/data/a.dart']!.line, 1);
    expect(byPath['lib/ui/c.dart']!.priority, 'P3');
  });

  test('fan-out is reported, barrels are not', () {
    final names = [for (var i = 0; i <= fanOutLimit; i++) 'm$i.dart'];
    final sources = {
      for (final n in names) 'lib/$n': '',
      'lib/big.dart': [for (final n in names) "import '$n';"].join(),
      'lib/barrel.dart': [for (final n in names) "export '$n';"].join(),
    };
    final f = auditImportGraph(root.path, sources);
    expect(f.map((x) => x.path), ['lib/big.dart']);
    expect(f.single.rule, 'high-fan-out');
  });
}
