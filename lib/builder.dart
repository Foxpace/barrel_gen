/// `build_runner` entry point for the `barrel_gen` builder.
library;

import 'package:build/build.dart';

import 'src/infrastructure/barrel_build_runner_builder.dart';

/// Creates the package-level `build_runner` coordinator.
///
/// The [options] are decoded from the `barrel_gen|barrel_gen` builder entry in
/// `build.yaml`.
Builder barrelBuilder(BuilderOptions options) =>
    BarrelBuildRunnerBuilder(options: options);
