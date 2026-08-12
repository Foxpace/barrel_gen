import '../domain/barrel_configuration.dart';
import '../domain/barrel_generation_exception.dart';

part 'barrel_configuration_reader.dart';

final class BarrelConfigurationDecoder {
  const BarrelConfigurationDecoder();

  BarrelConfiguration decode(Map<String, Object?> values) {
    final configuration = _ConfigurationReader.root(values);
    return BarrelConfiguration(
      folderBarrels: _decodeFolderBarrels(
        configuration.configurationMap('folder_barrels'),
      ),
      monorepo: _decodeMonorepo(configuration.configurationMap('monorepo')),
      packageBarrel: _decodePackageBarrel(
        configuration.configurationMap('package_barrel'),
      ),
      targets: _decodeTargets(configuration),
      dryRun: configuration.boolean('dry_run', fallback: false),
    );
  }

  FolderBarrelConfiguration _decodeFolderBarrels(
    _ConfigurationReader configuration,
  ) => FolderBarrelConfiguration(
    barrelName: configuration.string(
      'barrel_name',
      fallback: '{directory}.dart',
    ),
    enabled: configuration.boolean('enabled', fallback: false),
    minFiles: configuration.positiveInteger('min_files', fallback: 2),
    recursive: configuration.boolean('recursive', fallback: true),
    roots: configuration.stringList('roots', fallback: const ['lib']),
  );

  MonorepoConfiguration _decodeMonorepo(_ConfigurationReader configuration) {
    final monorepo = MonorepoConfiguration(
      enabled: configuration.boolean('enabled', fallback: false),
      includeRoot: configuration.boolean('include_root', fallback: false),
      packagesRoot: configuration.string('packages_root', fallback: 'packages'),
      appRoots: configuration.stringList('app_roots', fallback: const []),
      packageRoots: configuration.contains('package_roots')
          ? configuration.stringList('package_roots', fallback: const [])
          : null,
    );
    if (monorepo.enabled && monorepo.discoveryRoots.isEmpty) {
      throw const BarrelGenerationException(
        'An enabled monorepo requires at least one package or app root.',
      );
    }

    return monorepo;
  }

  PackageBarrelConfiguration _decodePackageBarrel(
    _ConfigurationReader configuration,
  ) => PackageBarrelConfiguration(
    enabled: configuration.boolean('enabled', fallback: true),
    mode: _decodePackageBarrelMode(configuration),
    nestedBarrelName: configuration.string(
      'nested_barrel_name',
      fallback: '{directory}.dart',
    ),
    output: configuration.string('output', fallback: 'lib/{package}.dart'),
  );

  PackageBarrelMode _decodePackageBarrelMode(
    _ConfigurationReader configuration,
  ) => switch (configuration.string('mode', fallback: 'single')) {
    'single' => PackageBarrelMode.single,
    'nested' => PackageBarrelMode.nested,
    _ => throw const BarrelGenerationException(
      'package_barrel.mode must be single or nested.',
    ),
  };

  List<CustomBarrelTarget> _decodeTargets(_ConfigurationReader configuration) =>
      configuration
          .configurationList('targets')
          .indexed
          .map((entry) {
            final (index, targetValues) = entry;
            return _decodeTarget(
              configuration.listItemMap('targets', index, targetValues),
            );
          })
          .toList(growable: false);

  CustomBarrelTarget _decodeTarget(_ConfigurationReader configuration) =>
      CustomBarrelTarget(
        output: configuration.requiredString('output'),
        root: configuration.requiredString('root'),
        minFiles: configuration.positiveInteger('min_files', fallback: 1),
        recursive: configuration.boolean('recursive', fallback: true),
      );
}
