/// Programmatic API for configuring and running barrel generation.
///
/// Most users can use the `build_runner` integration or the `barrel_gen` CLI.
/// Use this library when embedding generation in another Dart tool.
library;

export 'src/application/barrel_generation_state.dart';
export 'src/application/barrel_generator.dart';
export 'src/composition/barrel_gen_container.dart';
export 'src/domain/barrel_configuration.dart';
export 'src/domain/barrel_generation_exception.dart';
export 'src/domain/generation_result.dart';
