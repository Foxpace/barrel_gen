import 'package:args/args.dart';

ArgParser createBarrelGenArgumentParser() {
  final parser = ArgParser();
  _registerConfigOption(parser);
  _registerDryRunFlag(parser);
  _registerWatchFlag(parser);
  _registerHelpFlag(parser);
  return parser;
}

void _registerConfigOption(ArgParser parser) => parser.addOption(
  'config',
  abbr: 'c',
  defaultsTo: 'build.yaml',
  help: 'Path to build.yaml or a standalone barrel_gen YAML file.',
);

void _registerDryRunFlag(ArgParser parser) => parser.addFlag(
  'dry-run',
  abbr: 'n',
  help: 'Plan changes without writing or deleting files.',
  negatable: false,
);

void _registerWatchFlag(ArgParser parser) => parser.addFlag(
  'watch',
  abbr: 'w',
  help: 'Watch the workspace, including discovered nested packages.',
  negatable: false,
);

void _registerHelpFlag(ArgParser parser) => parser.addFlag(
  'help',
  abbr: 'h',
  help: 'Show command usage.',
  negatable: false,
);
