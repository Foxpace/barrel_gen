part of 'barrel_generation_planner.dart';

extension on BarrelGenerationPlanner {
  _PlannedChanges _planFolderBarrels(
    FolderBarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges, {
    required bool skipPackageLibTree,
  }) => configuration.roots.fold<_PlannedChanges>(
    plannedChanges,
    (currentChanges, configuredRoot) => _planBarrelsInRoot(
      configuration: configuration,
      package: package,
      plannedChanges: currentChanges,
      configuredRoot: configuredRoot,
      skipPackageLibTree: skipPackageLibTree,
    ),
  );

  _PlannedChanges _planBarrelsInRoot({
    required FolderBarrelConfiguration configuration,
    required PackageContext package,
    required _PlannedChanges plannedChanges,
    required String configuredRoot,
    required bool skipPackageLibTree,
  }) {
    final sourceRoot = _resolvePathWithinRoot(
      package.root,
      configuredRoot,
      'folder root',
    );
    if (skipPackageLibTree && _isInsidePackageLib(package.root, sourceRoot)) {
      return plannedChanges;
    }

    return _sourceCollector
        .collectNonIgnoredDirectories(
          recursive: configuration.recursive,
          root: sourceRoot,
        )
        .fold<_PlannedChanges>(
          plannedChanges,
          (currentChanges, sourceDirectory) => _planFolderBarrel(
            configuration: configuration,
            package: package,
            plannedChanges: currentChanges,
            sourceDirectory: sourceDirectory,
          ),
        );
  }

  _PlannedChanges _planFolderBarrel({
    required FolderBarrelConfiguration configuration,
    required PackageContext package,
    required _PlannedChanges plannedChanges,
    required String sourceDirectory,
  }) {
    final barrelFileName = configuration.barrelName
        .replaceAll('{directory}', p.basename(sourceDirectory))
        .replaceAll('{package}', package.name);
    final outputPath = _resolvePathWithinRoot(
      sourceDirectory,
      barrelFileName,
      'folder barrel',
    );
    return _addBarrelCandidate(
      minFiles: configuration.minFiles,
      outputPath: outputPath,
      packageRoot: package.root,
      plannedChanges: plannedChanges,
      sourcePaths: _sourceCollector.collectExportableDartFiles(
        excludedPaths: {outputPath},
        recursive: false,
        root: sourceDirectory,
      ),
    );
  }
}
