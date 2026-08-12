/// A discovered Dart or Flutter package.
final class PackageContext {
  const PackageContext({required this.name, required this.root});

  final String name;
  final String root;
}
