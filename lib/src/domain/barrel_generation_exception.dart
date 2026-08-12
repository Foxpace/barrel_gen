/// A configuration or filesystem problem that prevents safe generation.
final class BarrelGenerationException implements Exception {
  /// Creates an exception with a user-facing [message].
  const BarrelGenerationException(this.message);

  /// Description of the invalid or unsafe operation.
  final String message;

  @override
  String toString() => 'BarrelGenerationException: $message';
}
