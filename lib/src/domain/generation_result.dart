/// Summary of a completed generation pass.
final class GenerationResult {
  /// Creates a summary with explicit operation counts.
  const GenerationResult({
    required this.deletedFiles,
    required this.discoveredPackages,
    required this.unchangedFiles,
    required this.writtenFiles,
  });

  /// Creates a summary in which every count is zero.
  const GenerationResult.empty()
    : deletedFiles = 0,
      discoveredPackages = 0,
      unchangedFiles = 0,
      writtenFiles = 0;

  /// Number of owned generated files removed.
  final int deletedFiles;

  /// Number of packages included in the generation pass.
  final int discoveredPackages;

  /// Number of planned files whose existing content already matched.
  final int unchangedFiles;

  /// Number of generated files written.
  final int writtenFiles;
}
