import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory packageDirectory;
  Process? watchProcess;

  setUp(() {
    watchProcess = null;
    packageDirectory = Directory.systemTemp.createTempSync(
      'barrel_gen_single_package_test_',
    );
    _write(packageDirectory.path, 'pubspec.yaml', 'name: single_app\n');
    _write(
      packageDirectory.path,
      'lib/src/application.dart',
      'class Application {}\n',
    );
  });

  tearDown(() async {
    final process = watchProcess;
    if (process != null) {
      process.kill();
      await process.exitCode;
    }
    if (packageDirectory.existsSync()) {
      packageDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'Given a package without build.yaml, When the CLI runs, Then generates its barrel',
    () async {
      // When
      final result = await Process.run(Platform.resolvedExecutable, [
        p.join(Directory.current.path, 'bin/barrel_gen.dart'),
      ], workingDirectory: packageDirectory.path);

      // Then
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('Packages: 1, written: 1'));
      expect(
        File(
          p.join(packageDirectory.path, 'lib/single_app.dart'),
        ).readAsStringSync(),
        contains("export 'src/application.dart';"),
      );
    },
  );

  test(
    'Given a missing explicit config, When the CLI runs, Then rejects the config',
    () async {
      // When
      final result = await Process.run(Platform.resolvedExecutable, [
        p.join(Directory.current.path, 'bin/barrel_gen.dart'),
        '--config',
        'missing.yaml',
      ], workingDirectory: packageDirectory.path);

      // Then
      expect(result.exitCode, 64);
      expect(result.stderr, contains('Configuration not found: missing.yaml'));
    },
  );

  test(
    'Given an explicit config, When watch mode sees an invalid change, Then exits with a usage error',
    () async {
      // Given
      _write(
        packageDirectory.path,
        'tool/barrel_gen.yaml',
        'package_barrel:\n  output: lib/first.dart\n',
      );

      // When
    final process = await Process.start(Platform.resolvedExecutable, [
      p.join(Directory.current.path, 'bin/barrel_gen.dart'),
        '--config',
        'tool/barrel_gen.yaml',
      '--watch',
    ], workingDirectory: packageDirectory.path);
    watchProcess = process;
      final output = process.stdout
          .transform(const SystemEncoding().decoder)
          .asBroadcastStream();
      await output.firstWhere((text) => text.contains('Watching '));
      _write(packageDirectory.path, 'tool/barrel_gen.yaml', 'not: [valid\n');

      // Then
      expect(await process.exitCode.timeout(const Duration(seconds: 10)), 64);
    },
  );
}

void _write(String root, String relativePath, String contents) {
  final file = File(p.join(root, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
