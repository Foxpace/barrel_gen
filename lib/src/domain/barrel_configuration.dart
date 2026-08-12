/// Selects whether a package barrel is flat or delegates through folder barrels.
enum PackageBarrelMode {
  /// Export every eligible Dart library directly from the package barrel.
  single,

  /// Export directory barrels that form a tree below the package barrel.
  nested,
}

/// Defines a generated barrel that represents an entire package.
final class PackageBarrelConfiguration {
  /// Creates package-barrel configuration with explicit required values.
  const PackageBarrelConfiguration({
    required this.enabled,
    required this.output,
    this.mode = PackageBarrelMode.single,
    this.nestedBarrelName = '{directory}.dart',
  });

  /// Creates the default enabled, single-file package barrel configuration.
  const PackageBarrelConfiguration.defaults()
    : enabled = true,
      mode = PackageBarrelMode.single,
      nestedBarrelName = '{directory}.dart',
      output = 'lib/{package}.dart';

  /// Whether to generate a package barrel.
  final bool enabled;

  /// How exports are arranged below the package barrel.
  final PackageBarrelMode mode;

  /// Filename template used for directory barrels in [PackageBarrelMode.nested].
  final String nestedBarrelName;

  /// Package-relative output path, supporting the `{package}` placeholder.
  final String output;
}

/// Defines barrels generated beside the Dart files in qualifying folders.
final class FolderBarrelConfiguration {
  /// Creates folder-barrel configuration with explicit values.
  const FolderBarrelConfiguration({
    required this.barrelName,
    required this.enabled,
    required this.minFiles,
    required this.recursive,
    required this.roots,
  });

  /// Creates the default disabled folder-barrel configuration.
  const FolderBarrelConfiguration.defaults()
    : barrelName = '{directory}.dart',
      enabled = false,
      minFiles = 2,
      recursive = true,
      roots = const ['lib'];

  /// Filename template, supporting `{directory}` and `{package}` placeholders.
  final String barrelName;

  /// Whether to generate barrels for qualifying folders.
  final bool enabled;

  /// Minimum direct eligible-file count required in a folder.
  final int minFiles;

  /// Whether to inspect descendant folders below each entry in [roots].
  final bool recursive;

  /// Package-relative directories to inspect.
  final List<String> roots;
}

/// Defines a barrel whose sources and output are independently configurable.
final class CustomBarrelTarget {
  /// Creates a custom barrel target.
  const CustomBarrelTarget({
    required this.output,
    required this.root,
    this.minFiles = 1,
    this.recursive = true,
  });

  /// Minimum eligible-file count required to produce the barrel.
  final int minFiles;

  /// Package-relative output path, supporting the `{package}` placeholder.
  final String output;

  /// Whether to include eligible files below descendant directories.
  final bool recursive;

  /// Package-relative source directory.
  final String root;
}

/// Defines automatic package discovery for a monorepo.
final class MonorepoConfiguration {
  /// Creates monorepo discovery configuration.
  const MonorepoConfiguration({
    required this.enabled,
    required this.includeRoot,
    this.appRoots = const [],
    this.packageRoots,
    this.packagesRoot = 'packages',
  });

  /// Creates the default disabled monorepo configuration.
  const MonorepoConfiguration.defaults()
    : appRoots = const [],
      enabled = false,
      includeRoot = false,
      packageRoots = null,
      packagesRoot = 'packages';

  /// Workspace-relative roots searched for application packages.
  final List<String> appRoots;

  /// Whether to discover packages below [discoveryRoots].
  final bool enabled;

  /// Whether to generate barrels for the workspace root package too.
  final bool includeRoot;

  /// Workspace-relative roots searched for packages.
  final List<String>? packageRoots;

  /// Legacy single package root retained for configuration compatibility.
  final String packagesRoot;

  /// Unique package and application roots used during discovery.
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
  /// Creates a complete generator configuration.
  const BarrelConfiguration({
    required this.folderBarrels,
    required this.monorepo,
    required this.packageBarrel,
    required this.targets,
    this.dryRun = false,
  });

  /// Creates configuration for one package-level barrel with no monorepo scan.
  const BarrelConfiguration.defaults()
    : dryRun = false,
      folderBarrels = const FolderBarrelConfiguration.defaults(),
      monorepo = const MonorepoConfiguration.defaults(),
      packageBarrel = const PackageBarrelConfiguration.defaults(),
      targets = const [];

  /// Whether to plan changes without writing or deleting files.
  final bool dryRun;

  /// Folder-barrel settings.
  final FolderBarrelConfiguration folderBarrels;

  /// Monorepo package-discovery settings.
  final MonorepoConfiguration monorepo;

  /// Package-barrel settings.
  final PackageBarrelConfiguration packageBarrel;

  /// Additional independently configured barrels.
  final List<CustomBarrelTarget> targets;

  /// Returns a copy with [dryRun] replaced by the supplied value.
  BarrelConfiguration withDryRun({required bool dryRun}) => BarrelConfiguration(
    folderBarrels: folderBarrels,
    monorepo: monorepo,
    packageBarrel: packageBarrel,
    targets: targets,
    dryRun: dryRun,
  );
}
