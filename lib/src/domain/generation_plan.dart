/// One generated file and its complete desired contents.
final class BarrelWrite {
  const BarrelWrite({required this.contents, required this.path});

  final String contents;
  final String path;
}

/// All filesystem changes required to reach the desired barrel state.
final class GenerationPlan {
  const GenerationPlan({
    required this.deletes,
    required this.discoveredPackages,
    required this.writes,
  });

  final List<String> deletes;
  final int discoveredPackages;
  final List<BarrelWrite> writes;
}
