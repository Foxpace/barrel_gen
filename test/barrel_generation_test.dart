import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/barrel_test_fixture.dart';

void main() {
  group('barrel generation', () {
    late BarrelTestFixture fixture;
    late Directory workspace;

    setUp(() {
      fixture = BarrelTestFixture()..setUp();
      workspace = fixture.workspace;
    });

    tearDown(() => fixture.tearDown());

    test(
      'Given handwritten libraries, When generated, Then writes one sorted package barrel',
      () {
        // Given
        _writePackage(workspace.path, 'sample_package');
        _write(workspace.path, 'lib/zebra.dart', 'class Zebra {}');
        _write(workspace.path, 'lib/src/apple.dart', 'class Apple {}');
        _write(workspace.path, 'lib/src/apple.g.dart', 'class Generated {}');
        _write(workspace.path, 'lib/src/apple_part.dart', 'part of apple;');

        // When
        final state = _generate(
          configuration: const BarrelConfiguration.defaults(),
          workspaceRoot: workspace.path,
        );

        // Then
        expect(state, isA<BarrelGenerationCompleted>());
        expect((state as BarrelGenerationCompleted).result.writtenFiles, 1);
        expect(
          _read(workspace.path, 'lib/sample_package.dart'),
          contains("export 'src/apple.dart';\nexport 'zebra.dart';"),
        );
        expect(
          _read(workspace.path, 'lib/sample_package.dart'),
          isNot(contains('apple.g.dart')),
        );
      },
    );

    test(
      'Given folder sources, When reconciled, Then creates qualifying barrels and removes stale barrels',
      () {
        // Given
        _writePackage(workspace.path, 'folders');
        _write(workspace.path, 'lib/models/apple.dart', 'class Apple {}');
        _write(workspace.path, 'lib/models/banana.dart', 'class Banana {}');
        _write(workspace.path, 'lib/single/only.dart', 'class Only {}');
        const configuration = BarrelConfiguration(
          folderBarrels: FolderBarrelConfiguration(
            barrelName: '{directory}.dart',
            enabled: true,
            minFiles: 2,
            recursive: true,
            roots: ['lib'],
          ),
          monorepo: MonorepoConfiguration.defaults(),
          packageBarrel: PackageBarrelConfiguration(
            enabled: false,
            output: 'lib/{package}.dart',
          ),
          targets: [],
        );

        // When
        final firstState = _generate(
          configuration: configuration,
          workspaceRoot: workspace.path,
        );

        // Then
        expect(
          (firstState as BarrelGenerationCompleted).result.writtenFiles,
          1,
        );
        expect(
          File(p.join(workspace.path, 'lib/models/models.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(workspace.path, 'lib/single/single.dart')).existsSync(),
          isFalse,
        );

        // When
        File(p.join(workspace.path, 'lib/models/banana.dart')).deleteSync();
        final secondState = _generate(
          configuration: configuration,
          workspaceRoot: workspace.path,
        );

        // Then
        expect(
          (secondState as BarrelGenerationCompleted).result.deletedFiles,
          1,
        );
        expect(
          File(p.join(workspace.path, 'lib/models/models.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'Given a custom barrel target, When generated, Then writes the aggregate barrel',
      () {
        // Given
        _writePackage(workspace.path, 'custom_target');
        _write(workspace.path, 'lib/features/a.dart', 'class A {}');
        _write(workspace.path, 'lib/features/nested/b.dart', 'class B {}');
        const configuration = BarrelConfiguration(
          folderBarrels: FolderBarrelConfiguration.defaults(),
          monorepo: MonorepoConfiguration.defaults(),
          packageBarrel: PackageBarrelConfiguration(
            enabled: false,
            output: 'lib/{package}.dart',
          ),
          targets: [
            CustomBarrelTarget(
              output: 'lib/all_features.dart',
              root: 'lib/features',
            ),
          ],
        );

        // When
        _generate(configuration: configuration, workspaceRoot: workspace.path);

        // Then
        expect(
          _read(workspace.path, 'lib/all_features.dart'),
          contains("export 'features/nested/b.dart';"),
        );
      },
    );

    test(
      'Given a handwritten barrel candidate, When generated, Then refuses to overwrite it',
      () {
        // Given
        _writePackage(workspace.path, 'protected_package');
        _write(workspace.path, 'lib/value.dart', 'class Value {}');
        _write(workspace.path, 'lib/protected_package.dart', '// handwritten');

        // When
        final state = _generate(
          configuration: const BarrelConfiguration.defaults(),
          workspaceRoot: workspace.path,
        );

        // Then
        expect(state, isA<BarrelGenerationFailed>());
        expect(
          (state as BarrelGenerationFailed).failure,
          contains('Refusing to overwrite handwritten file'),
        );
        expect(
          _read(workspace.path, 'lib/protected_package.dart'),
          '// handwritten',
        );
      },
    );

    test(
      'Given dry-run mode, When generated, Then reports changes without writing files',
      () {
        // Given
        _writePackage(workspace.path, 'dry_package');
        _write(workspace.path, 'lib/value.dart', 'class Value {}');
        final configuration = const BarrelConfiguration.defaults().withDryRun(
          dryRun: true,
        );

        // When
        final state = _generate(
          configuration: configuration,
          workspaceRoot: workspace.path,
        );

        // Then
        expect((state as BarrelGenerationCompleted).result.writtenFiles, 1);
        expect(
          File(p.join(workspace.path, 'lib/dry_package.dart')).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'Given changing source files, When repeatedly generated, Then reconciles the package barrel',
      () {
        // Given
        _writePackage(workspace.path, 'lifecycle_package');
        _write(workspace.path, 'lib/old.dart', 'class Old {}');

        // When
        _generate(
          configuration: const BarrelConfiguration.defaults(),
          workspaceRoot: workspace.path,
        );

        // Then
        expect(
          _read(workspace.path, 'lib/lifecycle_package.dart'),
          contains("export 'old.dart';"),
        );

        // When
        final movedDirectory = Directory(p.join(workspace.path, 'lib/moved'))
          ..createSync();
        File(
          p.join(workspace.path, 'lib/old.dart'),
        ).renameSync(p.join(movedDirectory.path, 'renamed.dart'));
        _generate(
          configuration: const BarrelConfiguration.defaults(),
          workspaceRoot: workspace.path,
        );
        final movedBarrel = _read(workspace.path, 'lib/lifecycle_package.dart');

        // Then
        expect(movedBarrel, contains("export 'moved/renamed.dart';"));
        expect(movedBarrel, isNot(contains('old.dart')));

        // When
        File(p.join(movedDirectory.path, 'renamed.dart')).deleteSync();
        final removedState = _generate(
          configuration: const BarrelConfiguration.defaults(),
          workspaceRoot: workspace.path,
        );

        // Then
        expect(
          (removedState as BarrelGenerationCompleted).result.deletedFiles,
          1,
        );
        expect(
          File(
            p.join(workspace.path, 'lib/lifecycle_package.dart'),
          ).existsSync(),
          isFalse,
        );
      },
    );
  });
}

BarrelGenerationState _generate({
  required BarrelConfiguration configuration,
  required String workspaceRoot,
}) {
  final container = BarrelGenContainer();
  return container.generator.generate(
    configuration: configuration,
    workspaceRoot: workspaceRoot,
  );
}

String _read(String root, String relativePath) =>
    File(p.join(root, relativePath)).readAsStringSync();

void _write(String root, String relativePath, String contents) {
  final file = File(p.join(root, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void _writePackage(String root, String name) {
  _write(root, 'pubspec.yaml', 'name: $name\nenvironment:\n  sdk: ^3.12.2\n');
  Directory(p.join(root, 'lib')).createSync(recursive: true);
}
