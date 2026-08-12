import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../domain/barrel_file_system.dart';
import '../domain/barrel_generation_exception.dart';
import '../domain/package_context.dart';
import '../domain/package_discovery.dart';

final class LocalPackageDiscovery implements PackageDiscovery {
  const LocalPackageDiscovery(this._fileSystem);

  final BarrelFileSystem _fileSystem;

  @override
  List<PackageContext> discoverPackages({
    required String packagesRoot,
    required String workspaceRoot,
  }) {
    if (p.isAbsolute(packagesRoot)) {
      throw BarrelGenerationException(
        'The monorepo discovery root must be relative: $packagesRoot',
      );
    }

    final normalizedWorkspaceRoot = p.normalize(p.absolute(workspaceRoot));
    final root = p.normalize(p.join(workspaceRoot, packagesRoot));
    final absoluteRoot = p.normalize(p.absolute(root));
    if (!_isWithinOrEqual(normalizedWorkspaceRoot, absoluteRoot)) {
      throw BarrelGenerationException(
        'The monorepo discovery root must be inside the workspace: $root',
      );
    }
    if (!_fileSystem.directoryExists(root)) {
      throw BarrelGenerationException(
        'The monorepo packages_root does not exist: $root',
      );
    }

    final canonicalWorkspaceRoot = p.normalize(
      _fileSystem.resolveSymbolicLinks(normalizedWorkspaceRoot),
    );
    final canonicalRoot = p.normalize(_fileSystem.resolveSymbolicLinks(root));
    if (!_isWithinOrEqual(canonicalWorkspaceRoot, canonicalRoot)) {
      throw BarrelGenerationException(
        'The monorepo discovery root must be inside the workspace: $root',
      );
    }
    final packages = <PackageContext>[];

    _visit(canonicalRoot, packages);
    packages.sort((left, right) => left.root.compareTo(right.root));
    return packages;
  }

  @override
  PackageContext readPackage(String packageRoot) {
    final pubspecPath = p.join(packageRoot, 'pubspec.yaml');
    if (!_fileSystem.fileExists(pubspecPath)) {
      throw BarrelGenerationException('Missing pubspec.yaml in $packageRoot');
    }
    final document = loadYaml(_fileSystem.readFile(pubspecPath));
    if (document is! YamlMap) {
      throw BarrelGenerationException('Invalid pubspec.yaml in $packageRoot');
    }
    final name = document['name'];
    if (name is! String || name.trim().isEmpty) {
      throw BarrelGenerationException(
        'The pubspec in $packageRoot has no valid package name.',
      );
    }

    return PackageContext(name: name, root: p.normalize(packageRoot));
  }

  void _visit(String directory, List<PackageContext> packages) {
    final pubspecPath = p.join(directory, 'pubspec.yaml');
    if (_fileSystem.fileExists(pubspecPath)) {
      packages.add(readPackage(directory));
      return;
    }

    for (final child in _fileSystem.childDirectories(directory)) {
      if (!_isIgnored(child)) {
        _visit(child, packages);
      }
    }
  }

  bool _isIgnored(String path) {
    final name = p.basename(path);
    return name.startsWith('.') || name == 'build';
  }

  bool _isWithinOrEqual(String parent, String child) =>
      p.equals(parent, child) || p.isWithin(parent, child);
}
