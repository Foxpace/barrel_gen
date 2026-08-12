import '../domain/generation_result.dart';

/// Immutable state from barrel generation.
sealed class BarrelGenerationState {
  const BarrelGenerationState();
}

/// Generation completed and produced a summary.
final class BarrelGenerationCompleted extends BarrelGenerationState {
  const BarrelGenerationCompleted(this.result);

  final GenerationResult result;
}

/// Generation stopped because of a handled failure.
final class BarrelGenerationFailed extends BarrelGenerationState {
  const BarrelGenerationFailed(this.failure);

  final String failure;
}
