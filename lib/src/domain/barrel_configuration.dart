/// Selects whether a package barrel is flat or delegates through folder barrels.
enum PackageBarrelMode { single, nested }

/// Defines a generated barrel that represents an entire package.
final class PackageBarrelConfiguration {
  const PackageBarrelConfiguration({
    required this.enabled,
    required this.output,
    this.mode = PackageBarrelMode.single,
    this.nestedBarrelName = '{directory}.dart',
  });

  const PackageBarrelConfiguration.defaults()
    : enabled = true,
      mode = PackageBarrelMode.single,
      nestedBarrelName = '{directory}.dart',
      output = 'lib/{package}.dart';

  final bool enabled;
  final PackageBarrelMode mode;
  final String nestedBarrelName;
  final String output;
}

/// Defines barrels generated beside the Dart files in qualifying folders.
final class FolderBarrelConfiguration {
  const FolderBarrelConfiguration({
    required this.barrelName,
    required this.enabled,
    required this.minFiles,
    required this.recursive,
    required this.roots,
  });

  const FolderBarrelConfiguration.defaults()
    : barrelName = '{directory}.dart',
      enabled = false,
      minFiles = 2,
      recursive = true,
      roots = const ['lib'];

  final String barrelName;
  final bool enabled;
  final int minFiles;
  final bool recursive;
  final List<String> roots;
}

/// Defines a barrel whose sources and output are independently configurable.
final class CustomBarrelTarget {
  const CustomBarrelTarget({
    required this.output,
    required this.root,
    this.minFiles = 1,
    this.recursive = true,
  });

  final int minFiles;
  final String output;
  final bool recursive;
  final String root;
}

/// Defines automatic package discovery for a monorepo.
final class MonorepoConfiguration {
  const MonorepoConfiguration({
    required this.enabled,
    required this.includeRoot,
    this.appRoots = const [],
    this.packageRoots,
    this.packagesRoot = 'packages',
  });

  const MonorepoConfiguration.defaults()
    : appRoots = const [],
      enabled = false,
      includeRoot = false,
      packageRoots = null,
      packagesRoot = 'packages';

  final List<String> appRoots;
  final bool enabled;
  final bool includeRoot;
  final List<String>? packageRoots;

  /// Legacy single package root retained for configuration compatibility.
  final String packagesRoot;

  List<String> get discoveryRoots {
    final configuredPackageRoots = packageRoots ?? [packagesRoot];
    return <String>{
      ...configuredPackageRoots,
      ...appRoots,
    }.toList(growable: false);
  }
}

/// Complete immutable configuration consumed by the generator.
final class BarrelConfiguration {
  const BarrelConfiguration({
    required this.folderBarrels,
    required this.monorepo,
    required this.packageBarrel,
    required this.targets,
    this.dryRun = false,
  });

  const BarrelConfiguration.defaults()
    : dryRun = false,
      folderBarrels = const FolderBarrelConfiguration.defaults(),
      monorepo = const MonorepoConfiguration.defaults(),
      packageBarrel = const PackageBarrelConfiguration.defaults(),
      targets = const [];

  final bool dryRun;
  final FolderBarrelConfiguration folderBarrels;
  final MonorepoConfiguration monorepo;
  final PackageBarrelConfiguration packageBarrel;
  final List<CustomBarrelTarget> targets;

  BarrelConfiguration withDryRun({required bool dryRun}) => BarrelConfiguration(
    folderBarrels: folderBarrels,
    monorepo: monorepo,
    packageBarrel: packageBarrel,
    targets: targets,
    dryRun: dryRun,
  );
}
