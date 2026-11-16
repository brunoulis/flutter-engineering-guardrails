import 'package:flutter_rails_audit/src/project_rules.dart';
import 'package:test/test.dart';

const _yaml = '''
version: 1
rules:
  viewmodel-base-class:
    paths: [lib]
    class-suffix: ViewModel
    must-extend: BaseViewModel
    exclude: [BaseViewModel]
  forbidden-imports:
    - paths: [lib/**/presentation]
      imports: [package:http, package:dio]
  forbidden-types:
    - class-suffix: ViewModel
      types: [BuildContext]
''';

void main() {
  final rules = ProjectRules.parse(_yaml)!;
  List<String> ids(String path, String src) =>
      rules.audit(path, src).map((f) => f.rule).toList();

  test('flags a viewmodel that does not extend the base', () {
    expect(
      ids('lib/a.dart', 'class LoginViewModel extends ChangeNotifier {}'),
      ['project-viewmodel-base-class'],
    );
  });

  test('accepts the base, excluded names and non-viewmodels', () {
    expect(
      ids('lib/a.dart', 'class XViewModel extends BaseViewModel {}'),
      isEmpty,
    );
    expect(
      ids(
        'lib/a.dart',
        'abstract class BaseViewModel extends ChangeNotifier {}',
      ),
      isEmpty,
    );
    expect(ids('lib/a.dart', 'class Repo extends Object {}'), isEmpty);
  });

  test('flags forbidden imports only inside the configured path', () {
    const src = "import 'package:http/http.dart';";
    expect(ids('lib/sace/presentation/v.dart', src), [
      'project-forbidden-import',
    ]);
    expect(ids('lib/sace/data/ds.dart', src), isEmpty);
  });

  test('flags BuildContext inside a viewmodel', () {
    expect(
      ids(
        'lib/a.dart',
        'class XViewModel extends BaseViewModel { void f(BuildContext c) {} }',
      ),
      ['project-forbidden-type'],
    );
  });

  test('no rules section is null; malformed is a FormatException', () {
    expect(ProjectRules.parse('version: 1'), isNull);
    expect(
      () => ProjectRules.parse('rules:\n  forbidden-types: 3'),
      throwsFormatException,
    );
  });
}
