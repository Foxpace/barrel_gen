/// A configuration or filesystem problem that prevents safe generation.
final class BarrelGenerationException implements Exception {
  const BarrelGenerationException(this.message);

  final String message;

  @override
  String toString() => 'BarrelGenerationException: $message';
}
