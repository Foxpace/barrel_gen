import '../domain/barrel_configuration.dart';
import '../domain/barrel_file_system.dart';
import '../domain/generation_result.dart';
import 'planner/barrel_generation_planner.dart';
import 'barrel_generation_state.dart';

/// Runs barrel generation and returns either its summary or its failure.
final class BarrelGenerator {
  const BarrelGenerator(this._fileSystem, this._planner);

  final BarrelFileSystem _fileSystem;
  final BarrelGenerationPlanner _planner;

  BarrelGenerationState generate({
    required BarrelConfiguration configuration,
    required String workspaceRoot,
  }) {
    try {
      return BarrelGenerationCompleted(
        _generate(configuration: configuration, workspaceRoot: workspaceRoot),
      );
    } on Exception catch (exception) {
      return BarrelGenerationFailed(exception.toString());
    }
  }

  GenerationResult _generate({
    required BarrelConfiguration configuration,
    required String workspaceRoot,
  }) {
    final plan = _planner.plan(
      configuration: configuration,
      workspaceRoot: workspaceRoot,
    );
    if (configuration.dryRun) {
      return GenerationResult(
        deletedFiles: plan.deletes.length,
        discoveredPackages: plan.discoveredPackages,
        unchangedFiles: 0,
        writtenFiles: plan.writes.length,
      );
    }

    var writtenFiles = 0;
    var unchangedFiles = 0;
    for (final write in plan.writes) {
      if (_fileSystem.fileExists(write.path) &&
          _fileSystem.readFile(write.path) == write.contents) {
        unchangedFiles += 1;
        continue;
      }
      _fileSystem.createParentDirectory(write.path);
      _fileSystem.writeFile(write.path, write.contents);
      writtenFiles += 1;
    }

    var deletedFiles = 0;
    for (final path in plan.deletes) {
      if (_fileSystem.fileExists(path)) {
        _fileSystem.deleteFile(path);
        deletedFiles += 1;
      }
    }

    return GenerationResult(
      deletedFiles: deletedFiles,
      discoveredPackages: plan.discoveredPackages,
      unchangedFiles: unchangedFiles,
      writtenFiles: writtenFiles,
    );
  }
}
