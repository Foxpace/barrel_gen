import 'package:path/path.dart' as p;

import '../domain/barrel_configuration.dart';
import '../domain/barrel_generation_exception.dart';
import '../domain/package_context.dart';
import 'dart_source_collector.dart';

/// One desired node in a nested package-barrel tree.
final class NestedBarrelCandidate {
  const NestedBarrelCandidate({required this.exports, required this.output});

  final List<String> exports;
  final String output;
}

/// Plans child-first barrels so parents can export immediate child barrels.
final class NestedPackageBarrelPlanner {
  const NestedPackageBarrelPlanner(this._collector);

  final DartSourceCollector _collector;

  List<NestedBarrelCandidate> plan({
    required PackageBarrelConfiguration configuration,
    required PackageContext package,
    required String packageOutput,
  }) {
    final libRoot = p.normalize(p.join(package.root, 'lib'));
    final directories =
        _collector.collectNonIgnoredDirectories(recursive: true, root: libRoot)
          ..sort(
            (left, right) =>
                p.split(right).length.compareTo(p.split(left).length),
          );
    final childOutputs = <String, List<String>>{};
    final candidates = <NestedBarrelCandidate>[];

    for (final directory in directories) {
      final isPackageRoot = directory == libRoot;
      final output = isPackageRoot
          ? packageOutput
          : _outputFor(configuration, package, directory);
      final exports = _collector.collectExportableDartFiles(
        excludedPaths: {output, packageOutput},
        recursive: false,
        root: directory,
      )..addAll(childOutputs[directory] ?? const []);
      candidates.add(NestedBarrelCandidate(exports: exports, output: output));
      if (exports.isNotEmpty && !isPackageRoot) {
        childOutputs.putIfAbsent(p.dirname(directory), () => []).add(output);
      }
    }

    return candidates;
  }

  String _outputFor(
    PackageBarrelConfiguration configuration,
    PackageContext package,
    String directory,
  ) {
    final name = configuration.nestedBarrelName
        .replaceAll('{directory}', p.basename(directory))
        .replaceAll('{package}', package.name);
    if (p.isAbsolute(name)) {
      throw BarrelGenerationException(
        'Nested barrel name must be relative: $name',
      );
    }
    final output = p.normalize(p.join(directory, name));
    if (!p.isWithin(directory, output)) {
      throw BarrelGenerationException(
        'Nested barrel escapes its folder: $name',
      );
    }

    return output;
  }
}
