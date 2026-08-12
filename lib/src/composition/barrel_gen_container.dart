import '../application/barrel_format.dart';
import '../application/planner/barrel_generation_planner.dart';
import '../application/barrel_generator.dart';
import '../application/dart_source_collector.dart';
import '../application/nested_package_barrel_planner.dart';
import '../domain/barrel_file_system.dart';
import '../domain/package_discovery.dart';
import '../infrastructure/local_barrel_file_system.dart';
import '../infrastructure/local_package_discovery.dart';

/// Creates the production dependencies used to generate barrels.
final class BarrelGenContainer {
  factory BarrelGenContainer({
    BarrelFileSystem? fileSystem,
    PackageDiscovery? packageDiscovery,
  }) {
    final resolvedFileSystem = fileSystem ?? const LocalBarrelFileSystem();
    final barrelFormat = const BarrelFormat();
    final resolvedPackageDiscovery =
        packageDiscovery ?? LocalPackageDiscovery(resolvedFileSystem);
    final sourceCollector = DartSourceCollector(
      resolvedFileSystem,
      barrelFormat,
    );
    final nestedPackagePlanner = NestedPackageBarrelPlanner(sourceCollector);
    final planner = BarrelGenerationPlanner(
      sourceCollector,
      resolvedFileSystem,
      barrelFormat,
      nestedPackagePlanner,
      resolvedPackageDiscovery,
    );

    return BarrelGenContainer._(BarrelGenerator(resolvedFileSystem, planner));
  }

  const BarrelGenContainer._(this.generator);

  final BarrelGenerator generator;
}
