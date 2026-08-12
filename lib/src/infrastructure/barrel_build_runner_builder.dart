import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import '../application/barrel_generation_state.dart';
import '../composition/barrel_gen_container.dart';
import '../domain/barrel_configuration.dart';
import 'barrel_configuration_decoder.dart';

/// Package-level coordinator used by build_runner build and watch commands.
final class BarrelBuildRunnerBuilder implements Builder {
  BarrelBuildRunnerBuilder({
    required BuilderOptions options,
    BarrelConfigurationDecoder configurationDecoder =
        const BarrelConfigurationDecoder(),
    BarrelGenContainer? container,
  }) : _container = container ?? BarrelGenContainer(),
       _configuration = configurationDecoder.decode(options.config);

  final BarrelConfiguration _configuration;
  final BarrelGenContainer _container;

  static final _dartAssets = Glob('**/*.dart');

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$package$': ['.barrel_gen.stamp'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final trackedAssets = await _trackDartAssets(buildStep);
    _validateMonorepoTracking(trackedAssets);

    final state = _container.generator.generate(
      configuration: _configuration,
      workspaceRoot: Directory.current.path,
    );
    final result = switch (state) {
      BarrelGenerationCompleted(:final result) => result,
      BarrelGenerationFailed(:final failure) => throw StateError(failure),
    };
    final output = AssetId(buildStep.inputId.package, '.barrel_gen.stamp');
    final contents = jsonEncode({'packages': result.discoveredPackages});
    await buildStep.writeAsString(output, contents);
  }

  Future<Set<String>> _trackDartAssets(BuildStep buildStep) async {
    // The synthetic package input has no natural source dependencies. Tracking
    // both glob membership and content makes add, delete, move, rename, and
    // library/part changes invalidate this one coordinator step.
    final trackedPaths = <String>{};
    await for (final asset in buildStep.findAssets(_dartAssets)) {
      trackedPaths.add(asset.path);
      await buildStep.digest(asset);
    }

    return trackedPaths;
  }

  void _validateMonorepoTracking(Set<String> trackedPaths) {
    if (!_configuration.monorepo.enabled) {
      return;
    }
    final missingPaths = _monorepoDartPaths().difference(trackedPaths);
    if (missingPaths.isEmpty) {
      return;
    }
    final examples = missingPaths.take(3).join(', ');
    final sourceGlobs = _configuration.monorepo.discoveryRoots
        .map((root) => '"${_toAssetPath(root)}/**"')
        .join(', ');

    throw StateError(
      'Monorepo Dart files are outside the build_runner asset graph. Add '
      '$sourceGlobs and "\$package\$" to targets.\$default.sources '
      'in build.yaml so add, remove, move, and rename events are tracked. '
      'Untracked files include: $examples',
    );
  }

  Set<String> _monorepoDartPaths() {
    final paths = <String>{};

    for (final root in _configuration.monorepo.discoveryRoots) {
      final directory = Directory(p.join(Directory.current.path, root));
      if (directory.existsSync()) {
        _collectDartPaths(directory, paths);
      }
    }
    return paths;
  }

  void _collectDartPaths(Directory directory, Set<String> paths) {
    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is Directory && !_isIgnoredDirectory(entity)) {
        _collectDartPaths(entity, paths);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        paths.add(
          _toAssetPath(p.relative(entity.path, from: Directory.current.path)),
        );
      }
    }
  }

  bool _isIgnoredDirectory(Directory directory) {
    final name = p.basename(directory.path);
    return name.startsWith('.') || name == 'build';
  }

  String _toAssetPath(String fileSystemPath) =>
      p.posix.normalize(p.posix.joinAll(p.split(fileSystemPath)));
}
