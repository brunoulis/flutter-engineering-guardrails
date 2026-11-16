import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'audit_project.dart';
import 'baseline.dart';
import 'project_rules.dart';
import 'report.dart';

const _exitOk = 0;
const _exitFindings = 1;
const _exitIncomplete = 2;
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
    allowed: ['text', 'json', 'sarif'],
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
  ..addOption(
    'baseline',
    help: 'Baseline file; only findings absent from it count as new.',
  )
  ..addOption(
    'write-baseline',
    help: 'Write the current findings as a baseline file.',
  )
  ..addOption(
    'fail-on',
    allowed: ['P0', 'P1', 'P2', 'P3'],
    help:
        'Exit 1 when a finding of this priority or higher exists (only new '
        'ones when --baseline is given).',
  )
  ..addFlag(
    'strict',
    negatable: false,
    help:
        'Exit 2 when files had syntax errors (incomplete audit), even if '
        'no finding reaches --fail-on.',
  )
  ..addFlag(
    'resolve',
    defaultsTo: true,
    help:
        'Resolve types with the analyzer when the package has resolved '
        'dependencies (.dart_tool/package_config.json); otherwise fall back '
        'to syntax plus a cross-file class index.',
  )
  ..addFlag(
    'score',
    negatable: false,
    help: 'Add the evidence-based Anti-Slop Score (per-dimension, not summed).',
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

  final report = await auditProject(
    root,
    scopes,
    largeFileLines: largeFileLines,
    rules: rules,
    resolve: args.flag('resolve'),
    score: args.flag('score'),
  );

  BaselineDiff? diff;
  final baselinePath = args.option('baseline');
  if (baselinePath != null) {
    try {
      diff = BaselineDiff(
        report.findings,
        parseBaseline(File(baselinePath).readAsStringSync()),
      );
    } on FileSystemException catch (e) {
      return usageError('cannot read baseline $baselinePath: ${e.message}');
    } on FormatException catch (e) {
      return usageError('$baselinePath: ${e.message}');
    }
  }
  final writeBaseline = args.option('write-baseline');
  if (writeBaseline != null) {
    try {
      final file = File(writeBaseline);
      await file.parent.create(recursive: true);
      await file.writeAsString('${renderBaseline(report.findings)}\n');
    } on FileSystemException catch (e) {
      err.writeln('Error: cannot write $writeBaseline: ${e.message}');
      return _exitIo;
    }
  }

  final failOn = args.option('fail-on');
  final gated = diff?.added ?? report.findings;
  final failed =
      failOn != null && gated.any((f) => f.priority.compareTo(failOn) <= 0)
      ? _exitFindings
      : _exitOk;
  final exitCode = args.flag('strict') && report.parseErrors.isNotEmpty
      ? _exitIncomplete
      : failed;

  final text = switch (args.option('format')) {
    'json' => renderJson(report, diff: diff),
    'sarif' => renderSarif(report, diff: diff),
    _ => renderText(report, diff: diff),
  };

  final output = args.option('output');
  if (output == null) {
    out.write(text.endsWith('\n') ? text : '$text\n');
    return exitCode;
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
  return exitCode;
}
