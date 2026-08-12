# barrel_gen

`barrel_gen` creates Dart barrel files: files that export the public Dart
libraries in a package or folder.

For example, it can generate `lib/my_package.dart` from files under `lib/`:

```dart
export 'src/models/user.dart';
export 'src/services/user_service.dart';
```

It works with `build_runner` and a standalone CLI. In a monorepo, one command
can discover packages below configured folders and generate barrels for each.

## What it generates

- A package barrel, such as `lib/my_package.dart`.
- Optional folder barrels, such as `lib/models/models.dart`.
- Optional custom barrels, such as `lib/features.dart`.

Exports are sorted. Generated files have an ownership header: `barrel_gen`
updates or removes only files with that header and will not overwrite a
handwritten file. Private files, generated files, and `part of` files are not
exported.

## Install

Add `barrel_gen` and `build_runner` to the package that will run generation:

```yaml
dev_dependencies:
  barrel_gen: ^0.1.0
  build_runner: 2.7.1
```

Use a `build_runner` version compatible with your Dart or Flutter SDK.

## Quick start

With no custom configuration, `barrel_gen` creates one barrel for the current
app or package: `lib/{package}.dart`. Monorepo mode is optional and disabled by
default.

Run it once:

```sh
dart run build_runner build
```

Keep it running while you work:

```sh
dart run build_runner watch
```

## Configure barrels

Create a `build.yaml` file in the package root. This example creates a package
barrel, folder barrels, and one custom barrel:

```yaml
targets:
  $default:
    builders:
      barrel_gen|barrel_gen:
        enabled: true
        options:
          package_barrel:
            enabled: true
            output: lib/{package}.dart

          folder_barrels:
            enabled: true
            roots: [lib]
            recursive: true
            min_files: 2
            barrel_name: '{directory}.dart'

          targets:
            - root: lib/features
              output: lib/features.dart
              recursive: true
              min_files: 1
```

`barrel_gen|barrel_gen` means “use the `barrel_gen` builder from the
`barrel_gen` package.”

### Package barrel

Enabled by default. It exports every eligible Dart library below `lib/` into
`lib/{package}.dart`, where `{package}` is the name in `pubspec.yaml`.

```yaml
package_barrel:
  enabled: true
  output: lib/{package}.dart
```

Use `mode: nested` when you want a barrel tree. Each directory gets a barrel
that exports its direct files and child barrels.

```yaml
package_barrel:
  enabled: true
  mode: nested
  output: lib/{package}.dart
  nested_barrel_name: '{directory}.dart'
```

When nested mode is enabled, folder barrels inside `lib/` are skipped because
the nested tree already creates them.

### Folder barrels

A folder barrel is generated only when a directory has at least `min_files`
eligible Dart files directly inside it. `{directory}` and `{package}` can be
used in `barrel_name`.

```yaml
folder_barrels:
  enabled: true
  roots: [lib]
  recursive: true
  min_files: 2
  barrel_name: '{directory}.dart'
```

### Custom barrels

Use a custom target to collect a specific folder into a chosen output file.
Both paths are relative to the package root.

```yaml
targets:
  - root: lib/features
    output: lib/features.dart
    recursive: true
    min_files: 1
```

## Monorepos

Enable monorepo discovery to generate barrels for every package or app found
under `package_roots` and `app_roots`. A discovered directory is a package when
it contains `pubspec.yaml`.

```yaml
targets:
  $default:
    sources:
      - $package$
      - apps/**
      - packages/**
    builders:
      barrel_gen|barrel_gen:
        options:
          monorepo:
            enabled: true
            package_roots: [packages]
            app_roots: [apps]
            include_root: true
```

Add every discovery folder to `sources` so `build_runner` sees changes there.
`include_root: true` also generates barrels for the package that runs the
command. The legacy `packages_root: packages` option is still supported.

For a watcher that also sees nested packages outside the root build graph, use
the CLI:

```sh
dart run barrel_gen --watch
```

## CLI

The CLI reads `build.yaml` by default.

```sh
dart run barrel_gen
dart run barrel_gen --dry-run
dart run barrel_gen --watch
dart run barrel_gen --config tool/barrel_gen.yaml
```

When `build.yaml` is absent, the CLI uses the defaults and generates a barrel
for the current app or package. A path passed explicitly with `--config` must
exist.

A standalone configuration file contains the same top-level option keys:
`package_barrel`, `folder_barrels`, `monorepo`, and `targets`.

## Defaults

| Option | Default |
| --- | --- |
| Package barrel | Enabled at `lib/{package}.dart` |
| Package mode | `single` |
| Folder barrels | Disabled |
| Monorepo discovery | Disabled |
| Custom targets | None |

See [`example/monorepo_app`](example/monorepo_app) for a working Flutter
monorepo configuration.
