part of 'barrel_generation_planner.dart';

extension on BarrelGenerationPlanner {
  String _resolvePathWithinRoot(
    String root,
    String relativePath,
    String pathDescription,
  ) {
    if (p.isAbsolute(relativePath)) {
      throw BarrelGenerationException(
        '$pathDescription must be relative: $relativePath',
      );
    }

    final resolvedPath = p.normalize(p.join(root, relativePath));
    _ensurePathIsWithinRoot(root, resolvedPath, pathDescription);
    return resolvedPath;
  }

  void _ensurePathIsWithinRoot(
    String root,
    String path,
    String pathDescription,
  ) {
    final normalizedRoot = p.normalize(root);
    if (path != normalizedRoot && !p.isWithin(normalizedRoot, path)) {
      throw BarrelGenerationException(
        '$pathDescription escapes its package root: $path',
      );
    }
  }

  bool _isInsidePackageLib(String packageRoot, String path) {
    final libRoot = p.normalize(p.join(packageRoot, 'lib'));
    return path == libRoot || p.isWithin(libRoot, path);
  }

  bool _isGeneratedBarrelFile(String path) =>
      _fileSystem.fileExists(path) &&
      _barrelFormat.isGenerated(_fileSystem.readFile(path));
}
