import 'package:path/path.dart' as p;

import '../../domain/barrel_configuration.dart';
import '../../domain/barrel_file_system.dart';
import '../../domain/barrel_generation_exception.dart';
import '../../domain/generation_plan.dart';
import '../../domain/package_context.dart';
import '../../domain/package_discovery.dart';
import '../barrel_format.dart';
import '../dart_source_collector.dart';
import '../nested_package_barrel_planner.dart';

part 'barrel_generation_planner_paths.dart';
part 'barrel_generation_planner_folder_barrels.dart';
part 'barrel_generation_planner_package_discovery.dart';
part 'barrel_generation_planner_candidates.dart';

typedef _PlannedChanges = ({
  Set<String> deletions,
  Map<String, BarrelWrite> writesByPath,
});

const _emptyPlannedChanges = (
  deletions: <String>{},
  writesByPath: <String, BarrelWrite>{},
);

/// Builds a deterministic change plan without mutating the filesystem.
final class BarrelGenerationPlanner {
  const BarrelGenerationPlanner(
    this._sourceCollector,
    this._fileSystem,
    this._barrelFormat,
    this._nestedPackagePlanner,
    this._packageDiscovery,
  );

  final DartSourceCollector _sourceCollector;
  final BarrelFileSystem _fileSystem;
  final BarrelFormat _barrelFormat;
  final NestedPackageBarrelPlanner _nestedPackagePlanner;
  final PackageDiscovery _packageDiscovery;

  GenerationPlan plan({
    required BarrelConfiguration configuration,
    required String workspaceRoot,
  }) {
    final discoveredPackages = _discoverPackages(
      configuration: configuration,
      workspaceRoot: workspaceRoot,
    );
    final plannedChanges = discoveredPackages.fold<_PlannedChanges>(
      _emptyPlannedChanges,
      (currentChanges, package) =>
          _planBarrelsForPackage(configuration, package, currentChanges),
    );

    return GenerationPlan(
      deletes: plannedChanges.deletions.toList(growable: false)..sort(),
      discoveredPackages: discoveredPackages.length,
      writes: plannedChanges.writesByPath.values.toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path)),
    );
  }

  _PlannedChanges _planBarrelsForPackage(
    BarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) {
    final folderBarrelChanges = _planEnabledFolderBarrels(
      configuration,
      package,
      plannedChanges,
    );
    final packageBarrelChanges = _planEnabledPackageBarrel(
      configuration.packageBarrel,
      package,
      folderBarrelChanges,
    );

    return _planCustomBarrels(
      configuration.targets,
      package,
      packageBarrelChanges,
    );
  }

  _PlannedChanges _planEnabledFolderBarrels(
    BarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) {
    if (!configuration.folderBarrels.enabled) {
      return plannedChanges;
    }

    return _planFolderBarrels(
      configuration.folderBarrels,
      package,
      plannedChanges,
      skipPackageLibTree: _usesNestedPackageBarrels(configuration),
    );
  }

  bool _usesNestedPackageBarrels(BarrelConfiguration configuration) =>
      configuration.packageBarrel.enabled &&
      configuration.packageBarrel.mode == PackageBarrelMode.nested;

  _PlannedChanges _planEnabledPackageBarrel(
    PackageBarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) {
    if (!configuration.enabled) {
      return plannedChanges;
    }

    return _planPackageBarrel(configuration, package, plannedChanges);
  }

  _PlannedChanges _planCustomBarrels(
    List<CustomBarrelTarget> targets,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) => targets.fold<_PlannedChanges>(
    plannedChanges,
    (currentChanges, target) =>
        _planCustomBarrel(target, package, currentChanges),
  );

  _PlannedChanges _planPackageBarrel(
    PackageBarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) {
    final outputPath = _packageBarrelOutputPath(configuration, package);

    return switch (configuration.mode) {
      PackageBarrelMode.single => _planSinglePackageBarrel(
        package,
        plannedChanges,
        outputPath,
      ),
      PackageBarrelMode.nested => _planNestedPackageBarrels(
        configuration,
        package,
        plannedChanges,
        packageOutputPath: outputPath,
      ),
    };
  }

  String _packageBarrelOutputPath(
    PackageBarrelConfiguration configuration,
    PackageContext package,
  ) => _resolvePathWithinRoot(
    package.root,
    configuration.output.replaceAll('{package}', package.name),
    'package barrel',
  );

  _PlannedChanges _planSinglePackageBarrel(
    PackageContext package,
    _PlannedChanges plannedChanges,
    String outputPath,
  ) {
    return _addBarrelCandidate(
      minFiles: 1,
      outputPath: outputPath,
      packageRoot: package.root,
      plannedChanges: plannedChanges,
      sourcePaths: _sourceCollector.collectExportableDartFiles(
        excludedPaths: {outputPath},
        recursive: true,
        root: p.join(package.root, 'lib'),
      ),
    );
  }

  _PlannedChanges _planNestedPackageBarrels(
    PackageBarrelConfiguration configuration,
    PackageContext package,
    _PlannedChanges plannedChanges, {
    required String packageOutputPath,
  }) {
    return _nestedPackagePlanner
        .plan(
          configuration: configuration,
          package: package,
          packageOutput: packageOutputPath,
        )
        .fold<_PlannedChanges>(
          plannedChanges,
          (currentChanges, candidate) => _addBarrelCandidate(
            minFiles: 1,
            outputPath: candidate.output,
            packageRoot: package.root,
            plannedChanges: currentChanges,
            sourcePaths: candidate.exports,
          ),
        );
  }

  _PlannedChanges _planCustomBarrel(
    CustomBarrelTarget target,
    PackageContext package,
    _PlannedChanges plannedChanges,
  ) {
    final outputPath = _resolvePathWithinRoot(
      package.root,
      target.output.replaceAll('{package}', package.name),
      'custom output',
    );
    final sourceRoot = _resolvePathWithinRoot(
      package.root,
      target.root,
      'custom root',
    );
    return _addBarrelCandidate(
      minFiles: target.minFiles,
      outputPath: outputPath,
      packageRoot: package.root,
      plannedChanges: plannedChanges,
      sourcePaths: _sourceCollector.collectExportableDartFiles(
        excludedPaths: {outputPath},
        recursive: target.recursive,
        root: sourceRoot,
      ),
    );
  }
}
