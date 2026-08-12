import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('nested_barrel_');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  test(
    'Given nested mode, When sources change, Then generates and reconciles the barrel tree',
    () {
      // Given
      _write(workspace.path, 'pubspec.yaml', 'name: nested_package\n');
      _write(workspace.path, 'lib/src/api/client.dart', 'class Client {}');
      _write(workspace.path, 'lib/src/models/user.dart', 'class User {}');
      _write(workspace.path, 'lib/src/models/session.dart', 'class Session {}');
      _write(workspace.path, 'lib/src/util.dart', 'class Util {}');
      const configuration = BarrelConfiguration(
        folderBarrels: FolderBarrelConfiguration.defaults(),
        monorepo: MonorepoConfiguration.defaults(),
        packageBarrel: PackageBarrelConfiguration(
          enabled: true,
          mode: PackageBarrelMode.nested,
          nestedBarrelName: '{directory}.dart',
          output: 'lib/{package}.dart',
        ),
        targets: [],
      );

      // When
      final generator = BarrelGenContainer().generator;
      final initialState = generator.generate(
        configuration: configuration,
        workspaceRoot: workspace.path,
      );

      // Then
      expect(
        (initialState as BarrelGenerationCompleted).result.writtenFiles,
        4,
      );
      expect(
        _read(workspace.path, 'lib/nested_package.dart'),
        contains("export 'src/src.dart';"),
      );
      expect(
        _read(workspace.path, 'lib/nested_package.dart'),
        isNot(contains('models/user.dart')),
      );
      expect(
        _read(workspace.path, 'lib/src/src.dart'),
        contains("export 'models/models.dart';"),
      );
      expect(
        _read(workspace.path, 'lib/src/models/models.dart'),
        contains("export 'session.dart';\nexport 'user.dart';"),
      );

      // When
      File(p.join(workspace.path, 'lib/src/api/client.dart')).deleteSync();
      final updatedState = generator.generate(
        configuration: configuration,
        workspaceRoot: workspace.path,
      );

      // Then
      expect(
        (updatedState as BarrelGenerationCompleted).result.deletedFiles,
        1,
      );
      expect(
        File(p.join(workspace.path, 'lib/src/api/api.dart')).existsSync(),
        isFalse,
      );
      expect(
        _read(workspace.path, 'lib/src/src.dart'),
        isNot(contains("export 'api/api.dart';")),
      );
    },
  );
}

String _read(String root, String relativePath) =>
    File(p.join(root, relativePath)).readAsStringSync();

void _write(String root, String relativePath, String contents) {
  final file = File(p.join(root, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
