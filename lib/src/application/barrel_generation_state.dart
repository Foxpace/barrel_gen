import '../domain/generation_result.dart';

/// Immutable state from barrel generation.
sealed class BarrelGenerationState {
  /// Creates a generation state for use by the sealed subclasses.
  const BarrelGenerationState();
}

/// Generation completed and produced a summary.
final class BarrelGenerationCompleted extends BarrelGenerationState {
  /// Creates a successful state containing [result].
  const BarrelGenerationCompleted(this.result);

  /// Counts describing the completed generation pass.
  final GenerationResult result;
}

/// Generation stopped because of a handled failure.
final class BarrelGenerationFailed extends BarrelGenerationState {
  /// Creates a failed state containing a displayable [failure].
  const BarrelGenerationFailed(this.failure);

  /// Description of the handled failure.
  final String failure;
}
