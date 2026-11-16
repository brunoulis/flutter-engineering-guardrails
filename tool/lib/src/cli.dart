import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'audit_project.dart';
import 'project_rules.dart';
import 'report.dart';

const _exitOk = 0;
const _exitUsage = 64;
const _exitIo = 74;

final _parser = ArgParser()
  ..addOption(
    'root',
    abbr: 'r',
    defaultsTo: '.',
    help: 'Flutter/Dart package root.',
  )
  ..addMultiOption(
    'path',
    abbr: 'p',
    defaultsTo: ['lib'],
    help: 'Directory or file to audit, relative to --root (repeatable).',
  )
  ..addOption(
    'format',
    abbr: 'f',
    allowed: ['text', 'json'],
    defaultsTo: 'text',
  )
  ..addOption(
    'output',
    abbr: 'o',
    help: 'Write the report to this file instead of stdout.',
  )
  ..addOption(
    'large-file-lines',
    defaultsTo: '700',
    help: 'Line count above which a file is reported.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

String get usage =>
    'Usage: dart run flutter_rails_audit [options]\n\n'
    'Read-only structural audit for Flutter/Dart code. Reports leads for '
    'guardrail rules that analyzer lints do not cover.\n\n${_parser.usage}';

/// Runs the audit. Returns the process exit code; never calls `exit`.
Future<int> runCli(
  List<String> arguments, {
  required StringSink out,
  required StringSink err,
}) async {
  final ArgResults args;
  try {
    args = _parser.parse(arguments);
  } on FormatException catch (e) {
    err
      ..writeln(e.message)
      ..writeln(usage);
    return _exitUsage;
  }
  if (args.flag('help')) {
    out.writeln(usage);
    return _exitOk;
  }

  int usageError(String message) {
    err
      ..writeln('Error: $message')
      ..writeln(usage);
    return _exitUsage;
  }

  final largeFileLines = int.tryParse(args.option('large-file-lines')!);
  if (largeFileLines == null || largeFileLines < 1) {
    return usageError('--large-file-lines must be a positive integer.');
  }

  final rootArg = args.option('root')!;
  if (!Directory(rootArg).existsSync()) {
    return usageError('--root is not an existing directory: $rootArg');
  }
  final root = p.normalize(Directory(rootArg).resolveSymbolicLinksSync());

  final scopes = <String>[];
  for (final scope in args.multiOption('path')) {
    final joined = p.join(root, scope);
    if (FileSystemEntity.typeSync(joined) == FileSystemEntityType.notFound) {
      return usageError('--path does not exist: $joined');
    }
    final resolved = p.normalize(
      FileSystemEntity.isDirectorySync(joined)
          ? Directory(joined).resolveSymbolicLinksSync()
          : File(joined).resolveSymbolicLinksSync(),
    );
    if (!p.equals(resolved, root) && !p.isWithin(root, resolved)) {
      return usageError('--path escapes --root: $scope');
    }
    scopes.add(resolved);
  }

  ProjectRules? rules;
  final config = File(p.join(root, '.flutter-rails.yaml'));
  if (config.existsSync()) {
    try {
      rules = ProjectRules.parse(config.readAsStringSync());
    } on FormatException catch (e) {
      return usageError(e.message);
    }
  }

  final report = auditProject(
    root,
    scopes,
    largeFileLines: largeFileLines,
    rules: rules,
  );
  final text = args.option('format') == 'json'
      ? renderJson(report)
      : renderText(report);

  final output = args.option('output');
  if (output == null) {
    out.write(text.endsWith('\n') ? text : '$text\n');
    return _exitOk;
  }
  try {
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsString(text.endsWith('\n') ? text : '$text\n');
  } on FileSystemException catch (e) {
    err.writeln('Error: cannot write $output: ${e.message}');
    return _exitIo;
  }
  out.writeln('Report written to $output');
  return _exitOk;
}
