import 'package_context.dart';

abstract interface class PackageDiscovery {
  List<PackageContext> discoverPackages({
    required String packagesRoot,
    required String workspaceRoot,
  });

  PackageContext readPackage(String packageRoot);
}
