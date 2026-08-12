import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';
import 'package:path/path.dart' as p;

final class BarrelTestFixture {
  late final Directory workspace;
  final List<Directory> _extraDirectories = [];

  void setUp() {
    workspace = Directory.systemTemp.createTempSync('barrel_gen_test_');
  }

  void tearDown() {
    for (final directory in _extraDirectories) {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    }
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  }

  Directory createOutsideDirectory() {
    final directory = Directory.systemTemp.createTempSync(
      'barrel_gen_outside_',
    );
    _extraDirectories.add(directory);
    return directory;
  }

  BarrelGenerationState generate(BarrelConfiguration configuration) {
    return BarrelGenContainer().generator.generate(
      configuration: configuration,
      workspaceRoot: workspace.path,
    );
  }

  String read(String relativePath) =>
      File(p.join(workspace.path, relativePath)).readAsStringSync();

  void write(String relativePath, String contents) {
    writeAt(workspace.path, relativePath, contents);
  }

  void writeAt(String root, String relativePath, String contents) {
    final file = File(p.join(root, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  void writePackage(String root, String name) {
    writeAt(
      root,
      'pubspec.yaml',
      'name: $name\nenvironment:\n  sdk: ^3.12.2\n',
    );
    Directory(p.join(root, 'lib')).createSync(recursive: true);
  }
}
