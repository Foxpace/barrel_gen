part of 'barrel_generation_planner.dart';

extension on BarrelGenerationPlanner {
  List<PackageContext> _discoverPackages({
    required BarrelConfiguration configuration,
    required String workspaceRoot,
  }) => configuration.monorepo.enabled
      ? _discoverMonorepoPackages(configuration.monorepo, workspaceRoot)
      : _discoverWorkspacePackage(workspaceRoot);

  List<PackageContext> _discoverWorkspacePackage(String workspaceRoot) => [
    _packageDiscovery.readPackage(workspaceRoot),
  ];

  List<PackageContext> _discoverMonorepoPackages(
    MonorepoConfiguration configuration,
    String workspaceRoot,
  ) {
    final packagesByRoot = <String, PackageContext>{};
    _addPackagesFromConfiguredRoots(
      packagesByRoot,
      configuration.discoveryRoots,
      workspaceRoot,
    );
    _addWorkspacePackageWhenIncluded(
      packagesByRoot,
      configuration,
      workspaceRoot,
    );

    return _sortPackagesByRoot(packagesByRoot.values);
  }

  void _addPackagesFromConfiguredRoots(
    Map<String, PackageContext> packagesByRoot,
    List<String> discoveryRoots,
    String workspaceRoot,
  ) {
    for (final discoveryRoot in discoveryRoots) {
      final packages = _packageDiscovery.discoverPackages(
        packagesRoot: discoveryRoot,
        workspaceRoot: workspaceRoot,
      );
      _addPackagesByRoot(packagesByRoot, packages);
    }
  }

  void _addWorkspacePackageWhenIncluded(
    Map<String, PackageContext> packagesByRoot,
    MonorepoConfiguration configuration,
    String workspaceRoot,
  ) {
    if (!configuration.includeRoot) {
      return;
    }

    _addPackagesByRoot(packagesByRoot, [
      _packageDiscovery.readPackage(workspaceRoot),
    ]);
  }

  void _addPackagesByRoot(
    Map<String, PackageContext> packagesByRoot,
    Iterable<PackageContext> packages,
  ) {
    for (final package in packages) {
      packagesByRoot[p.normalize(package.root)] = package;
    }
  }

  List<PackageContext> _sortPackagesByRoot(Iterable<PackageContext> packages) {
    final sortedPackages = packages.toList(growable: false)
      ..sort((left, right) => left.root.compareTo(right.root));

    return sortedPackages;
  }
}
