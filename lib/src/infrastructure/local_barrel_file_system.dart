import 'dart:io';

import '../domain/barrel_file_system.dart';

/// Local synchronous filesystem adapter used by build_runner and the CLI.
final class LocalBarrelFileSystem implements BarrelFileSystem {
  const LocalBarrelFileSystem();

  @override
  List<String> childDirectories(String path) {
    if (!directoryExists(path)) {
      return const [];
    }

    return Directory(path)
        .listSync(followLinks: false)
        .whereType<Directory>()
        .map((directory) => directory.path)
        .toList(growable: false);
  }

  @override
  void createParentDirectory(String path) {
    File(path).parent.createSync(recursive: true);
  }

  @override
  void deleteFile(String path) {
    File(path).deleteSync();
  }

  @override
  bool directoryExists(String path) => Directory(path).existsSync();

  @override
  bool fileExists(String path) => File(path).existsSync();

  @override
  List<String> filesInDirectory(String path) {
    if (!directoryExists(path)) {
      return const [];
    }

    return Directory(path)
        .listSync(followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .toList(growable: false);
  }

  @override
  String readFile(String path) => File(path).readAsStringSync();

  @override
  String resolveSymbolicLinks(String path) =>
      Directory(path).resolveSymbolicLinksSync();

  @override
  void writeFile(String path, String contents) {
    File(path).writeAsStringSync(contents);
  }
}
