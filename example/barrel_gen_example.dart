import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';

void main() {
  final generator = BarrelGenContainer().generator;
  final state = generator.generate(
    configuration: const BarrelConfiguration.defaults().withDryRun(
      dryRun: true,
    ),
    workspaceRoot: Directory.current.path,
  );

  switch (state) {
    case BarrelGenerationCompleted(:final result):
      print(
        'Dry run: ${result.discoveredPackages} package(s), '
        '${result.writtenFiles} file(s) to write, '
        '${result.deletedFiles} file(s) to delete.',
      );
    case BarrelGenerationFailed(:final failure):
      stderr.writeln(failure);
      exitCode = 1;
  }
}
