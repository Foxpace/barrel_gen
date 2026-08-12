/// Filesystem port used by planning and writing services.
abstract interface class BarrelFileSystem {
  List<String> childDirectories(String path);

  void createParentDirectory(String path);

  void deleteFile(String path);

  bool directoryExists(String path);

  bool fileExists(String path);

  List<String> filesInDirectory(String path);

  String readFile(String path);

  String resolveSymbolicLinks(String path);

  void writeFile(String path, String contents);
}
