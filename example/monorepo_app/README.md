# Monorepo example

This Flutter app is the only package that depends on `barrel_gen`. Its
`build.yaml` discovers packages from both `packages/` and `modules/`, plus apps
from `apps/`. No individual nested app or package is listed.

From this directory run:

```sh
flutter pub get
dart run build_runner build
flutter analyze
```

The build creates:

- `lib/barrel_gen_example.dart` for the app;
- `lib/screens/screens.dart` for the qualifying folder;
- `lib/screens.dart` from the explicit custom target;
- `packages/feature_account/lib/feature_account.dart`;
- `packages/shared_utils/lib/shared_utils.dart`;
- `modules/analytics/lib/analytics.dart`;
- `apps/admin_app/lib/admin_app.dart`;
- qualifying folder barrels inside every discovered app and package.

Use `dart run barrel_gen --watch` when edits inside nested packages must trigger
generation without touching a root-package source file.
