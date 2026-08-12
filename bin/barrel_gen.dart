import 'dart:io';

import 'package:barrel_gen/barrel_gen.dart';
import 'package:barrel_gen/src/infrastructure/barrel_configuration_decoder.dart';
import 'package:barrel_gen/src/infrastructure/yaml_configuration_loader.dart';
import 'package:path/path.dart' as p;

import 'src/barrel_gen_argument_parser.dart';

final _argumentParser = createBarrelGenArgumentParser();
const _configurationDecoder = BarrelConfigurationDecoder();
const _configurationLoader = YamlConfigurationLoader();
final _container = BarrelGenContainer();

Future<void> main(List<String> arguments) async {
  try {
    await _run(arguments: arguments);
  } on Exception catch (exception) {
    _reportFailure(exception);
  }
}

Future<void> _run({required List<String> arguments}) async {
  final results = _argumentParser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln('Generate Dart barrel files.\n\n${_argumentParser.usage}');
    return;
  }

  final configPath = results.option('config') ?? 'build.yaml';
  final hasExplicitConfig = results.wasParsed('config');
  final dryRun = results.flag('dry-run');
  _runGenerationOnce(
    configPath: configPath,
    dryRun: dryRun,
    useDefaultsWhenMissing: !hasExplicitConfig,
  );

  if (results.flag('watch')) {
    await _watch(
      configPath: configPath,
      dryRun: dryRun,
      useDefaultsWhenMissing: !hasExplicitConfig,
    );
  }
}

void _runGenerationOnce({
  required String configPath,
  required bool dryRun,
  required bool useDefaultsWhenMissing,
}) {
  final configuration = _loadConfiguration(
    configPath: configPath,
    dryRun: dryRun,
    useDefaultsWhenMissing: useDefaultsWhenMissing,
  );
  final state = _generateBarrels(configuration);
  _printGenerationSummary(_generationResult(state));
}

BarrelConfiguration _loadConfiguration({
  required String configPath,
  required bool dryRun,
  required bool useDefaultsWhenMissing,
}) {
  final configFile = File(configPath);
  if (!configFile.existsSync()) {
    if (useDefaultsWhenMissing) {
      final configuration = const BarrelConfiguration.defaults();
      return dryRun ? configuration.withDryRun(dryRun: true) : configuration;
    }
    throw BarrelGenerationException('Configuration not found: $configPath');
  }

  final values = _configurationLoader.load(configFile.readAsStringSync());
  final configuration = _configurationDecoder.decode(values);
  return dryRun ? configuration.withDryRun(dryRun: true) : configuration;
}

BarrelGenerationState _generateBarrels(BarrelConfiguration configuration) {
  return _container.generator.generate(
    configuration: configuration,
    workspaceRoot: Directory.current.path,
  );
}

GenerationResult _generationResult(BarrelGenerationState state) =>
    switch (state) {
      BarrelGenerationCompleted(:final result) => result,
      BarrelGenerationFailed(:final failure) => throw BarrelGenerationException(
        failure,
      ),
    };

void _printGenerationSummary(GenerationResult result) {
  stdout.writeln(
    'Packages: ${result.discoveredPackages}, '
    'written: ${result.writtenFiles}, '
    'unchanged: ${result.unchangedFiles}, '
    'deleted: ${result.deletedFiles}',
  );
}

void _reportFailure(Exception exception) {
  stderr.writeln(exception);
  stderr.writeln('\n${_argumentParser.usage}');
  exitCode = 64;
}

Future<void> _watch({
  required String configPath,
  required bool dryRun,
  required bool useDefaultsWhenMissing,
}) async {
  const pollInterval = Duration(milliseconds: 500);
  final workspace = Directory.current;
  final configFile = File(configPath).absolute;
  var workspaceSignature = _workspaceSignature(workspace);
  var configSignature = _fileSignature(configFile);

  stdout.writeln('Watching ${Directory.current.path} for changes...');

  while (true) {
    await Future<void>.delayed(pollInterval);

    final nextWorkspaceSignature = _workspaceSignature(workspace);
    final nextConfigSignature = _fileSignature(configFile);
    final workspaceChanged = nextWorkspaceSignature != workspaceSignature;
    final configChanged = nextConfigSignature != configSignature;

    if (!workspaceChanged && !configChanged) {
      continue;
    }

    _runGenerationOnce(
      configPath: configPath,
      dryRun: dryRun,
      useDefaultsWhenMissing: useDefaultsWhenMissing,
    );
    workspaceSignature = _workspaceSignature(workspace);
    configSignature = _fileSignature(configFile);
  }
}

int _workspaceSignature(Directory root) {
  final fingerprints = <Object>[];
  _collectFingerprints(root, fingerprints);
  return Object.hashAll(fingerprints);
}

void _collectFingerprints(Directory directory, List<Object> fingerprints) {
  final entities = directory.listSync(followLinks: false)
    ..sort((left, right) => left.path.compareTo(right.path));
  for (final entity in entities) {
    if (entity is Directory) {
      if (!_ignoredDirectory(entity.path)) {
        _collectFingerprints(entity, fingerprints);
      }
      continue;
    }
    if (entity is File && _watchedFile(entity.path)) {
      final stat = entity.statSync();
      fingerprints.add(entity.path);
      fingerprints.add(stat.modified.microsecondsSinceEpoch);
      fingerprints.add(stat.size);
    }
  }
}

int? _fileSignature(File file) {
  if (!file.existsSync()) {
    return null;
  }
  return Object.hashAll(file.readAsBytesSync());
}

bool _ignoredDirectory(String path) {
  final name = p.basename(path);
  return name.startsWith('.') || name == 'build' || name == 'node_modules';
}

bool _watchedFile(String path) {
  final name = p.basename(path);
  return name.endsWith('.dart') ||
      name == 'build.yaml' ||
      name == 'pubspec.yaml';
}
