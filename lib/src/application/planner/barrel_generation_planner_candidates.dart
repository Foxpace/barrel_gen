part of 'barrel_generation_planner.dart';

extension on BarrelGenerationPlanner {
  _PlannedChanges _addBarrelCandidate({
    required int minFiles,
    required String outputPath,
    required String packageRoot,
    required _PlannedChanges plannedChanges,
    required List<String> sourcePaths,
  }) {
    _ensurePathIsWithinRoot(packageRoot, outputPath, 'barrel output');
    if (_hasTooFewSourceFiles(sourcePaths, minFiles)) {
      return _planRemovalForInsufficientSourceFiles(outputPath, plannedChanges);
    }

    _ensureBarrelCanBeWritten(outputPath);
    return _planBarrelWrite(outputPath, sourcePaths, plannedChanges);
  }

  bool _hasTooFewSourceFiles(List<String> sourcePaths, int minFiles) =>
      sourcePaths.length < minFiles;

  _PlannedChanges _planRemovalForInsufficientSourceFiles(
    String outputPath,
    _PlannedChanges plannedChanges,
  ) {
    if (!_isGeneratedBarrelFile(outputPath)) {
      return plannedChanges;
    }

    return _withPlannedDeletion(plannedChanges, outputPath);
  }

  void _ensureBarrelCanBeWritten(String outputPath) {
    if (!_fileSystem.fileExists(outputPath)) {
      return;
    }
    if (_isGeneratedBarrelFile(outputPath)) {
      return;
    }

    throw BarrelGenerationException(
      'Refusing to overwrite handwritten file: $outputPath',
    );
  }

  _PlannedChanges _planBarrelWrite(
    String outputPath,
    List<String> sourcePaths,
    _PlannedChanges plannedChanges,
  ) {
    final generatedContents = _barrelFormat.render(
      sourcePaths: sourcePaths,
      outputPath: outputPath,
    );
    _ensureWriteDoesNotConflict(outputPath, generatedContents, plannedChanges);

    return (
      deletions: Set.unmodifiable(
        plannedChanges.deletions.where((path) => path != outputPath),
      ),
      writesByPath: Map.unmodifiable({
        ...plannedChanges.writesByPath,
        outputPath: BarrelWrite(contents: generatedContents, path: outputPath),
      }),
    );
  }

  void _ensureWriteDoesNotConflict(
    String outputPath,
    String generatedContents,
    _PlannedChanges plannedChanges,
  ) {
    final existingWrite = plannedChanges.writesByPath[outputPath];
    if (existingWrite == null || existingWrite.contents == generatedContents) {
      return;
    }

    throw BarrelGenerationException('Multiple targets produce $outputPath');
  }

  _PlannedChanges _withPlannedDeletion(
    _PlannedChanges plannedChanges,
    String outputPath,
  ) => (
    deletions: Set.unmodifiable({...plannedChanges.deletions, outputPath}),
    writesByPath: plannedChanges.writesByPath,
  );
}
