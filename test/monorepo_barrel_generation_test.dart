import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/barrel_test_fixture.dart';

void main() {
  group('monorepo barrel generation', () {
    late BarrelTestFixture fixture;

    setUp(() {
      fixture = BarrelTestFixture()..setUp();
    });

    tearDown(() => fixture.tearDown());

    test(
      'Given multiple monorepo roots, When generated, Then discovers packages and apps in every root',
      () {
        // Given
        fixture.writePackage(fixture.workspace.path, 'workspace_app');
        final firstPackage = p.join(
          fixture.workspace.path,
          'packages/feature_a',
        );
        final secondPackage = p.join(
          fixture.workspace.path,
          'modules/feature_b',
        );
        final firstApp = p.join(fixture.workspace.path, 'apps/admin_app');
        final secondApp = p.join(
          fixture.workspace.path,
          'client_apps/customer_app',
        );
        fixture.writePackage(firstPackage, 'feature_a');
        fixture.writePackage(secondPackage, 'feature_b');
        fixture.writePackage(firstApp, 'admin_app');
        fixture.writePackage(secondApp, 'customer_app');
        fixture.writeAt(firstPackage, 'lib/alpha.dart', 'class Alpha {}');
        fixture.writeAt(secondPackage, 'lib/beta.dart', 'class Beta {}');
        fixture.writeAt(firstApp, 'lib/admin.dart', 'class Admin {}');
        fixture.writeAt(secondApp, 'lib/customer.dart', 'class Customer {}');
        const configuration = BarrelConfiguration(
          folderBarrels: FolderBarrelConfiguration.defaults(),
          monorepo: MonorepoConfiguration(
            enabled: true,
            includeRoot: false,
            packageRoots: ['packages', 'modules'],
            appRoots: ['apps', 'client_apps'],
          ),
          packageBarrel: PackageBarrelConfiguration.defaults(),
          targets: [],
        );

        // When
        final state = fixture.generate(configuration);

        // Then
        expect(
          (state as BarrelGenerationCompleted).result.discoveredPackages,
          4,
        );
        expect(
          File(p.join(firstPackage, 'lib/feature_a.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(secondPackage, 'lib/feature_b.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(firstApp, 'lib/admin_app.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(secondApp, 'lib/customer_app.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(
            p.join(fixture.workspace.path, 'lib/workspace_app.dart'),
          ).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'Given a discovery root outside the workspace, When generated, Then rejects the root',
      () {
        // Given
        final outside = fixture.createOutsideDirectory();
        fixture.writePackage(outside.path, 'outside_package');
        final relativeOutside = p.relative(
          outside.path,
          from: fixture.workspace.path,
        );

        // When
        final state = fixture.generate(_monorepoConfiguration(relativeOutside));

        // Then
        expect(state, isA<BarrelGenerationFailed>());
        expect(
          (state as BarrelGenerationFailed).failure,
          contains('must be inside the workspace'),
        );
      },
    );

    test(
      'Given an absolute discovery root, When generated, Then rejects the root',
      () {
        // When
        final state = fixture.generate(
          _monorepoConfiguration(fixture.workspace.path),
        );

        // Then
        expect(state, isA<BarrelGenerationFailed>());
        expect(
          (state as BarrelGenerationFailed).failure,
          contains('must be relative'),
        );
      },
    );

    test(
      'Given a symlinked root outside the workspace, When generated, Then rejects the root',
      () {
        // Given
        final outside = fixture.createOutsideDirectory();
        fixture.writePackage(outside.path, 'outside_package');
        Link(
          p.join(fixture.workspace.path, 'packages'),
        ).createSync(outside.path);

        // When
        final state = fixture.generate(_monorepoConfiguration('packages'));

        // Then
        expect(state, isA<BarrelGenerationFailed>());
        expect(
          (state as BarrelGenerationFailed).failure,
          contains('must be inside the workspace'),
        );
      },
    );
  });
}

BarrelConfiguration _monorepoConfiguration(String root) => BarrelConfiguration(
  folderBarrels: const FolderBarrelConfiguration.defaults(),
  monorepo: MonorepoConfiguration(
    enabled: true,
    includeRoot: false,
    packageRoots: [root],
  ),
  packageBarrel: const PackageBarrelConfiguration.defaults(),
  targets: const [],
);
