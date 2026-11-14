import 'dart:io';

import 'package:flutter_rails_audit/src/cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCli(arguments, out: stdout, err: stderr);
}
