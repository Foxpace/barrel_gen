import 'package:barrel_gen/barrel_gen.dart';
import 'package:barrel_gen/src/infrastructure/barrel_configuration_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('monorepo configuration decoding', () {
    test(
      'Given a legacy packages_root, When decoded, Then keeps that discovery root',
      () {
        // When
        final configuration = const BarrelConfigurationDecoder().decode({
          'monorepo': {'enabled': true, 'packages_root': 'legacy_packages'},
        });

        // Then
        expect(configuration.monorepo.discoveryRoots, ['legacy_packages']);
      },
    );

    test(
      'Given package and app roots, When decoded, Then combines every discovery root',
      () {
        // When
        final configuration = const BarrelConfigurationDecoder().decode({
          'monorepo': {
            'enabled': true,
            'package_roots': ['packages', 'modules'],
            'app_roots': ['apps', 'client_apps'],
          },
        });

        // Then
        expect(configuration.monorepo.discoveryRoots, [
          'packages',
          'modules',
          'apps',
          'client_apps',
        ]);
      },
    );
  });

  group('package barrel mode decoding', () {
    test('Given no barrel mode, When decoded, Then uses single mode', () {
      // When
      final configuration = const BarrelConfigurationDecoder().decode({});

      // Then
      expect(configuration.packageBarrel.mode, PackageBarrelMode.single);
    });

    test(
      'Given nested barrel mode, When decoded, Then enables nested mode',
      () {
        // When
        final configuration = const BarrelConfigurationDecoder().decode({
          'package_barrel': {'mode': 'nested'},
        });

        // Then
        expect(configuration.packageBarrel.mode, PackageBarrelMode.nested);
      },
    );
  });
}
