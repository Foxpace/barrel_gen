part of 'barrel_configuration_decoder.dart';

final class _ConfigurationReader {
  const _ConfigurationReader._(this._values, this._path);

  factory _ConfigurationReader.root(Map<String, Object?> values) =>
      _ConfigurationReader._(values, 'configuration');

  final Map<String, Object?> _values;
  final String _path;

  bool contains(String key) => _values.containsKey(key);

  _ConfigurationReader configurationMap(String key) {
    final value = _values[key];
    if (value == null) {
      return _ConfigurationReader._(const {}, _keyPath(key));
    }
    if (value is! Map<Object?, Object?>) {
      throw BarrelGenerationException('${_keyPath(key)} must be a YAML map.');
    }

    return _ConfigurationReader._(_stringKeyedMap(value), _keyPath(key));
  }

  List<Object?> configurationList(String key) {
    final value = _values[key];
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw BarrelGenerationException('${_keyPath(key)} must be a YAML list.');
    }

    return value;
  }

  _ConfigurationReader listItemMap(String key, int index, Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw BarrelGenerationException(
        '${_keyPath(key)}[$index] must be a YAML map.',
      );
    }

    return _ConfigurationReader._(
      _stringKeyedMap(value),
      '${_keyPath(key)}[$index]',
    );
  }

  bool boolean(String key, {required bool fallback}) {
    final value = _values[key];
    if (value == null) {
      return fallback;
    }
    if (value is! bool) {
      throw BarrelGenerationException('${_keyPath(key)} must be a boolean.');
    }

    return value;
  }

  int positiveInteger(String key, {required int fallback}) {
    final value = _values[key];
    if (value == null) {
      return fallback;
    }
    if (value is! int || value < 1) {
      throw BarrelGenerationException(
        '${_keyPath(key)} must be a positive integer.',
      );
    }

    return value;
  }

  String requiredString(String key) =>
      _validString(_values[key], _keyPath(key));

  String string(String key, {required String fallback}) {
    final value = _values[key];
    return value == null ? fallback : _validString(value, _keyPath(key));
  }

  List<String> stringList(String key, {required List<String> fallback}) {
    final value = _values[key];
    if (value == null) {
      return fallback;
    }
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw BarrelGenerationException(
        '${_keyPath(key)} must be a list of strings.',
      );
    }

    return value.cast<String>().toList(growable: false);
  }

  String _keyPath(String key) => _path == 'configuration' ? key : '$_path.$key';

  static Map<String, Object?> _stringKeyedMap(Map<Object?, Object?> values) {
    final stringKeyedValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.key is! String) {
        throw const BarrelGenerationException(
          'Configuration keys must be strings.',
        );
      }
      stringKeyedValues[entry.key as String] = entry.value;
    }

    return stringKeyedValues;
  }

  static String _validString(Object? value, String keyPath) {
    if (value is! String || value.trim().isEmpty) {
      throw BarrelGenerationException('$keyPath must be a nonempty string.');
    }

    return value;
  }
}
