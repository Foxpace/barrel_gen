/// Summary of a completed generation pass.
final class GenerationResult {
  const GenerationResult({
    required this.deletedFiles,
    required this.discoveredPackages,
    required this.unchangedFiles,
    required this.writtenFiles,
  });

  const GenerationResult.empty()
    : deletedFiles = 0,
      discoveredPackages = 0,
      unchangedFiles = 0,
      writtenFiles = 0;

  final int deletedFiles;
  final int discoveredPackages;
  final int unchangedFiles;
  final int writtenFiles;
}
