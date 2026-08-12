import 'package:path/path.dart' as p;

import '../domain/barrel_file_system.dart';
import 'barrel_format.dart';

/// Selects exportable handwritten Dart libraries from a source tree.
final class DartSourceCollector {
  const DartSourceCollector(this._fileSystem, this._barrelFormat);

  static final _partOfPattern = RegExp(r'^\s*part\s+of\b', multiLine: true);
  static const _generatedSuffixes = <String>[
    '.chopper.dart',
    '.config.dart',
    '.freezed.dart',
    '.g.dart',
    '.gen.dart',
    '.gr.dart',
    '.mocks.dart',
  ];

  final BarrelFileSystem _fileSystem;
  final BarrelFormat _barrelFormat;

  List<String> collectExportableDartFiles({
    required Set<String> excludedPaths,
    required bool recursive,
    required String root,
  }) {
    if (!_fileSystem.directoryExists(root)) {
      return const [];
    }
    final exportableFilePaths = <String>[];

    _collectExportableFilesInDirectory(
      root,
      excludedPaths,
      recursive,
      exportableFilePaths,
    );
    exportableFilePaths.sort();
    return exportableFilePaths;
  }

  List<String> collectNonIgnoredDirectories({
    required bool recursive,
    required String root,
  }) {
    if (!_fileSystem.directoryExists(root)) {
      return const [];
    }
    final directoryPaths = <String>[root];
    if (recursive) {
      _collectDescendantDirectories(root, directoryPaths);
    }
    directoryPaths.sort();
    return directoryPaths;
  }

  void _collectDescendantDirectories(
    String directory,
    List<String> directoryPaths,
  ) {
    for (final childDirectory in _fileSystem.childDirectories(directory)) {
      if (_isIgnoredDirectory(childDirectory)) {
        continue;
      }
      directoryPaths.add(childDirectory);
      _collectDescendantDirectories(childDirectory, directoryPaths);
    }
  }

  void _collectExportableFilesInDirectory(
    String directory,
    Set<String> excludedPaths,
    bool recursive,
    List<String> exportableFilePaths,
  ) {
    for (final filePath in _fileSystem.filesInDirectory(directory)) {
      if (_isExportableDartFile(filePath, excludedPaths)) {
        exportableFilePaths.add(p.normalize(filePath));
      }
    }
    if (!recursive) {
      return;
    }

    for (final childDirectory in _fileSystem.childDirectories(directory)) {
      if (!_isIgnoredDirectory(childDirectory)) {
        _collectExportableFilesInDirectory(
          childDirectory,
          excludedPaths,
          true,
          exportableFilePaths,
        );
      }
    }
  }

  bool _isExportableDartFile(String path, Set<String> excludedPaths) {
    final normalizedPath = p.normalize(path);
    final name = p.basename(path);
    if (!name.endsWith('.dart') ||
        name.startsWith('_') ||
        excludedPaths.contains(normalizedPath) ||
        _generatedSuffixes.any(name.endsWith)) {
      return false;
    }
    final contents = _fileSystem.readFile(path);
    return !_barrelFormat.isGenerated(contents) &&
        !_partOfPattern.hasMatch(contents);
  }

  bool _isIgnoredDirectory(String path) {
    final name = p.basename(path);
    return name.startsWith('.') || name == 'build';
  }
}
