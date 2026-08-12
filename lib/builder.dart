import 'package:build/build.dart';

import 'src/infrastructure/barrel_build_runner_builder.dart';

/// Creates the package-level build_runner coordinator.
Builder barrelBuilder(BuilderOptions options) =>
    BarrelBuildRunnerBuilder(options: options);
