import 'package:yaml/yaml.dart';

import '../domain/barrel_generation_exception.dart';

/// Extracts barrel_gen options from build.yaml or a standalone YAML file.
final class YamlConfigurationLoader {
  const YamlConfigurationLoader();

  Map<String, Object?> load(String contents) {
    final document = loadYaml(contents);
    final normalized = _normalize(document);
    if (normalized is! Map<String, Object?>) {
      throw const BarrelGenerationException(
        'The configuration document must be a YAML map.',
      );
    }

    return _extractBuilderOptions(normalized);
  }

  Map<String, Object?> _extractBuilderOptions(Map<String, Object?> document) {
    final targets = document['targets'];
    if (targets is! Map<String, Object?>) {
      return document;
    }
    final defaultTarget = targets[r'$default'];
    if (defaultTarget is! Map<String, Object?>) {
      return document;
    }
    final builders = defaultTarget['builders'];
    if (builders is! Map<String, Object?>) {
      return document;
    }
    final builder = builders['barrel_gen|barrel_gen'] ?? builders['barrel_gen'];
    if (builder is! Map<String, Object?>) {
      return document;
    }
    final options = builder['options'];
    if (options is! Map<String, Object?>) {
      return const {};
    }

    return options;
  }

  Object? _normalize(Object? value) {
    if (value is YamlMap) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw const BarrelGenerationException(
            'Configuration keys must be strings.',
          );
        }
        result[key] = _normalize(entry.value);
      }
      return result;
    }
    if (value is YamlList) {
      return value.map(_normalize).toList(growable: false);
    }

    return value;
  }
}
