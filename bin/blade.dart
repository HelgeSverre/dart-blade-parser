// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:completion/completion.dart' as completion;
import 'package:path/path.dart' as path;

const String version = '1.1.0';

void main(List<String> arguments) async {
  // Set up main argument parser with subcommands
  final argParser = ArgParser()
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Show version',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);

  // Add parse subcommand
  final parseCommand = argParser.addCommand('parse')
    ..addFlag('json', help: 'Output AST as JSON')
    ..addFlag('tree', help: 'Output AST as tree (default)', defaultsTo: true)
    ..addFlag('stdin', help: 'Read from stdin')
    ..addFlag('help',
        abbr: 'h', help: 'Show help for parse command', negatable: false);

  // Add format subcommand
  final formatCommand = argParser.addCommand('format')
    ..addFlag(
      'write',
      abbr: 'w',
      help: 'Write formatted output back to files (default: stdout)',
    )
    ..addFlag(
      'check',
      abbr: 'c',
      help: 'Check if files need formatting (exit code 1 if any do)',
      negatable: false,
    )
    ..addOption(
      'config',
      help: 'Path to configuration file (.blade.json)',
    )
    ..addOption(
      'indent-size',
      help: 'Number of spaces for indentation',
      defaultsTo: '4',
    )
    ..addOption(
      'indent-style',
      help: "Use 'spaces' or 'tabs'",
      allowed: ['spaces', 'tabs'],
      defaultsTo: 'spaces',
    )
    ..addOption(
      'quote-style',
      help: "Quote style: 'single', 'double', or 'preserve'",
      allowed: ['single', 'double', 'preserve'],
      defaultsTo: 'preserve',
    )
    ..addFlag(
      'stdin',
      help: 'Read from stdin, write to stdout',
      negatable: false,
    )
    ..addFlag('verbose', abbr: 'v', help: 'Verbose output')
    ..addFlag('help',
        abbr: 'h', help: 'Show help for format command', negatable: false);

  try {
    // Handle shell completion
    final argResults = completion.tryArgsCompletion(arguments, argParser);

    // Handle completion requests
    if (argResults.command?.name == 'completion') {
      return;
    }

    // Show version if requested
    if (argResults.wasParsed('version') && argResults['version'] as bool) {
      print('blade v$version');
      exit(0);
    }

    // Show help if requested or no subcommand
    if ((argResults.wasParsed('help') && argResults['help'] as bool) ||
        argResults.command == null) {
      _printMainUsage(argParser);
      exit(0);
    }

    // Route to subcommand
    final command = argResults.command!;
    switch (command.name) {
      case 'parse':
        await _handleParseCommand(command);
        break;
      case 'format':
        await _handleFormatCommand(command);
        break;
      default:
        stderr.writeln('Unknown command: ${command.name}');
        _printMainUsage(argParser);
        exit(2);
    }
  } catch (e, stackTrace) {
    stderr.writeln('Error: $e');
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      stderr.writeln(stackTrace);
    }
    exit(1);
  }
}

void _printMainUsage(ArgParser argParser) {
  print('''
Blade CLI v$version

A unified CLI for parsing and formatting Laravel Blade templates.

Usage:
  blade <command> [options] [arguments]

Commands:
  parse      Parse Blade templates to AST
  format     Format Blade templates with consistent style

Options:
${argParser.usage}

Shell Completion:
  To install shell completion, run:
    blade completion install

Examples:
  blade parse template.blade.php --json
  blade format templates/ --write --verbose
  blade format templates/ --check

Run 'blade <command> --help' for more information on a specific command.
''');
}

// ============================================================================
// PARSE COMMAND
// ============================================================================

Future<void> _handleParseCommand(ArgResults command) async {
  // Show help if requested
  if (command['help'] as bool) {
    _printParseUsage();
    exit(0);
  }

  final jsonOutput = command['json'] as bool;
  final useStdin = command['stdin'] as bool;
  final filePath = command.rest.isNotEmpty ? command.rest.first : null;

  try {
    String source;

    if (useStdin) {
      source = stdin.readLineSync() ?? '';
    } else if (filePath != null) {
      source = File(filePath).readAsStringSync();
    } else {
      stderr.writeln('Error: No input provided');
      _printParseUsage();
      exit(2);
    }

    final parser = BladeParser();
    final result = parser.parse(source);

    if (result.errors.isNotEmpty) {
      for (final error in result.errors) {
        stderr.writeln(error);
      }
    }

    final ast = result.ast;
    if (ast != null) {
      if (jsonOutput) {
        stdout.writeln(jsonEncode(ast.toJson()));
      } else {
        _printTree(ast, 0);
      }
    }

    exit(result.isSuccess ? 0 : 1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

void _printParseUsage() {
  print('''
Parse Blade templates to AST

Usage:
  blade parse [options] <file>
  blade parse [options] --stdin

Options:
  --json         Output AST as JSON
  --tree         Output AST as tree (default)
  --stdin        Read from stdin
  -h, --help     Show this help

Examples:
  blade parse template.blade.php
  blade parse template.blade.php --json
  cat template.blade.php | blade parse --stdin
''');
}

void _printTree(AstNode node, int indent) {
  final prefix = '  ' * indent;

  if (node is DocumentNode) {
    print('${prefix}Document');
    for (final child in node.children) {
      _printTree(child, indent + 1);
    }
  } else if (node is DirectiveNode) {
    print('$prefix@${node.name}');
    for (final child in node.children) {
      _printTree(child, indent + 1);
    }
  } else if (node is EchoNode) {
    final type = node.isRaw ? 'RawEcho' : 'Echo';
    print('$prefix$type: ${node.expression}');
  } else if (node is TextNode) {
    final preview = node.content.length > 30
        ? '${node.content.substring(0, 30)}...'
        : node.content;
    print('${prefix}Text: "$preview"');
  }
}

// ============================================================================
// FORMAT COMMAND
// ============================================================================

enum FormatFileResult {
  needsFormatting,
  formatted,
  unchanged,
  error,
}

Future<void> _handleFormatCommand(ArgResults command) async {
  // Show help if requested
  if (command['help'] as bool) {
    _printFormatUsage();
    exit(0);
  }

  try {
    final config = await _loadConfig(command);
    final verbose = command['verbose'] as bool;
    final checkMode = command['check'] as bool;
    final writeMode = command['write'] as bool;
    final useStdin = command['stdin'] as bool;

    // Validate mode combinations
    if (checkMode && writeMode) {
      stderr.writeln('Error: Cannot use --check and --write together');
      exit(2);
    }

    if (useStdin && (checkMode || writeMode)) {
      stderr.writeln(
        'Error: Cannot use --stdin with --check or --write flags',
      );
      exit(2);
    }

    final formatter = BladeFormatter(config: config);

    // Handle stdin mode
    if (useStdin) {
      await _formatStdin(formatter);
      return;
    }

    // Get file patterns
    final patterns = command.rest;
    if (patterns.isEmpty) {
      stderr.writeln('Error: No files or patterns specified');
      _printFormatUsage();
      exit(2);
    }

    // Find all matching files
    final files = await _findFiles(patterns, verbose);

    if (files.isEmpty) {
      stderr.writeln('Error: No .blade.php files found matching patterns');
      exit(2);
    }

    if (verbose) {
      print('Found ${files.length} file(s) to format');
    }

    // Format files
    int needsFormatting = 0;
    int formatted = 0;
    int errors = 0;

    for (final file in files) {
      final result = await _formatFile(
        file,
        formatter,
        checkMode: checkMode,
        writeMode: writeMode,
        verbose: verbose,
      );

      switch (result) {
        case FormatFileResult.needsFormatting:
          needsFormatting++;
          break;
        case FormatFileResult.formatted:
          formatted++;
          break;
        case FormatFileResult.unchanged:
          // No change needed
          break;
        case FormatFileResult.error:
          errors++;
          break;
      }
    }

    // Print summary
    if (verbose || checkMode) {
      print('\nSummary:');
      print('  Total files: ${files.length}');
      if (checkMode) {
        print('  Needs formatting: $needsFormatting');
        print(
            '  Already formatted: ${files.length - needsFormatting - errors}');
      } else {
        print('  Formatted: $formatted');
        print('  Unchanged: ${files.length - formatted - errors}');
      }
      if (errors > 0) {
        print('  Errors: $errors');
      }
    }

    // Exit code
    if (errors > 0) {
      exit(1);
    } else if (checkMode && needsFormatting > 0) {
      exit(1);
    } else {
      exit(0);
    }
  } catch (e, stackTrace) {
    stderr.writeln('Error: $e');
    if (command['verbose'] as bool? ?? false) {
      stderr.writeln(stackTrace);
    }
    exit(1);
  }
}

void _printFormatUsage() {
  print('''
Format Blade templates with consistent style

Usage:
  blade format [options] <files/patterns>
  blade format [options] --stdin

Options:
  -w, --write              Write formatted output back to files (default: stdout)
  -c, --check              Check if files need formatting (exit code 1 if any do)
      --config             Path to configuration file (.blade.json)
      --indent-size        Number of spaces for indentation (default: 4)
      --indent-style       Use 'spaces' or 'tabs' (default: spaces)
      --quote-style        Quote style: 'single', 'double', or 'preserve' (default: preserve)
      --stdin              Read from stdin, write to stdout
  -v, --verbose            Verbose output
  -h, --help               Show this help

Configuration File:
  The --config flag accepts a JSON file with these options:
  {
    "indent_size": 4,
    "indent_style": "spaces",
    "quote_style": "preserve",
    "format_php_expressions": false,
    "max_line_length": 120
  }

Examples:
  blade format template.blade.php
  blade format templates/ --write --verbose
  blade format "templates/**/*.blade.php" --write
  blade format templates/ --check
  cat template.blade.php | blade format --stdin
  blade format template.blade.php --indent-size 2 --indent-style tabs
  blade format templates/ --config .blade.json --write
''');
}

Future<FormatFileResult> _formatFile(
  File file,
  BladeFormatter formatter, {
  required bool checkMode,
  required bool writeMode,
  required bool verbose,
}) async {
  try {
    final source = await file.readAsString();
    final result = formatter.formatWithResult(source);

    if (result.hasErrors) {
      stderr.writeln('${file.path}: Parse errors:');
      for (final error in result.errors) {
        stderr.writeln(
            '  ${error.position.line}:${error.position.column} - ${error.message}');
      }
      return FormatFileResult.error;
    }

    if (!result.wasChanged) {
      if (verbose && !checkMode) {
        print('${file.path}: Already formatted');
      }
      return FormatFileResult.unchanged;
    }

    // File needs formatting
    if (checkMode) {
      print('${file.path}: Needs formatting');
      return FormatFileResult.needsFormatting;
    }

    if (writeMode) {
      await file.writeAsString(result.formatted);
      if (verbose) {
        print('${file.path}: Formatted');
      }
      return FormatFileResult.formatted;
    }

    // Default: print to stdout
    print('--- ${file.path} ---');
    print(result.formatted);
    return FormatFileResult.formatted;
  } catch (e) {
    stderr.writeln('${file.path}: Error - $e');
    return FormatFileResult.error;
  }
}

Future<void> _formatStdin(BladeFormatter formatter) async {
  try {
    final buffer = StringBuffer();
    String? line;

    while ((line = stdin.readLineSync()) != null) {
      buffer.writeln(line);
    }

    final source = buffer.toString();
    final formatted = formatter.format(source);
    stdout.write(formatted);
    exit(0);
  } on FormatterException catch (e) {
    stderr.writeln('Parse errors:');
    for (final error in e.parseErrors) {
      stderr.writeln(
          '  ${error.position.line}:${error.position.column} - ${error.message}');
    }
    exit(1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<List<File>> _findFiles(List<String> patterns, bool verbose) async {
  final files = <File>[];
  final processedPaths = <String>{};

  for (final pattern in patterns) {
    // Check if it's a file or directory
    final entity = FileSystemEntity.typeSync(pattern);

    if (entity == FileSystemEntityType.file) {
      // Direct file path
      if (pattern.endsWith('.blade.php')) {
        final file = File(pattern);
        final canonical = file.absolute.path;
        if (!processedPaths.contains(canonical)) {
          files.add(file);
          processedPaths.add(canonical);
        }
      }
    } else if (entity == FileSystemEntityType.directory) {
      // Directory: find all .blade.php files
      if (verbose) {
        print('Scanning directory: $pattern');
      }
      final dir = Directory(pattern);
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.blade.php')) {
          final canonical = entity.absolute.path;
          if (!processedPaths.contains(canonical)) {
            files.add(entity);
            processedPaths.add(canonical);
          }
        }
      }
    } else if (pattern.contains('*') || pattern.contains('?')) {
      // Glob pattern
      final matchedFiles = await _globFiles(pattern, verbose);
      for (final file in matchedFiles) {
        final canonical = file.absolute.path;
        if (!processedPaths.contains(canonical)) {
          files.add(file);
          processedPaths.add(canonical);
        }
      }
    } else {
      stderr.writeln('Warning: Not found or not a file/directory: $pattern');
    }
  }

  return files;
}

Future<List<File>> _globFiles(String pattern, bool verbose) async {
  final files = <File>[];

  // Simple glob implementation
  // Supports: *.blade.php, **/*.blade.php, dir/**/*.blade.php
  final parts = pattern.split('/');
  String? basePath;
  final patternParts = <String>[];

  // Find the first part with a glob character
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].contains('*') || parts[i].contains('?')) {
      // Everything before is the base path
      if (i > 0) {
        basePath = parts.sublist(0, i).join('/');
      }
      patternParts.addAll(parts.sublist(i));
      break;
    }
  }

  basePath ??= '.';
  final baseDir = Directory(basePath);

  if (!baseDir.existsSync()) {
    return files;
  }

  // Check if pattern contains **
  final recursive = patternParts.any((p) => p == '**');

  await for (final entity
      in baseDir.list(recursive: recursive, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.blade.php')) {
      // Check if path matches pattern
      if (_matchesGlobPattern(entity.path, pattern)) {
        files.add(entity);
      }
    }
  }

  return files;
}

bool _matchesGlobPattern(String filePath, String pattern) {
  // Simple pattern matching
  // This is a basic implementation - could be enhanced with a glob library

  // Normalize paths
  final normalizedPath = path.normalize(filePath);
  final normalizedPattern = path.normalize(pattern);

  // Convert glob pattern to regex
  var regexPattern = normalizedPattern
      .replaceAll('\\', '/')
      .replaceAll('.', '\\.')
      .replaceAll('**/', '.*')
      .replaceAll('**', '.*')
      .replaceAll('*', '[^/]*')
      .replaceAll('?', '[^/]');

  regexPattern = '^$regexPattern\$';

  final regex = RegExp(regexPattern);
  final testPath = normalizedPath.replaceAll('\\', '/');

  return regex.hasMatch(testPath);
}

Future<FormatterConfig> _loadConfig(ArgResults argResults) async {
  final configPath = argResults['config'] as String?;

  // Start with defaults
  var configMap = <String, dynamic>{};

  // Load from config file if specified
  if (configPath != null) {
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      stderr.writeln('Error: Config file not found: $configPath');
      exit(2);
    }

    try {
      // For now, we'll support JSON format
      // YAML support can be added with the yaml package
      final contents = await configFile.readAsString();

      if (configPath.endsWith('.json')) {
        configMap = jsonDecode(contents) as Map<String, dynamic>;
      } else if (configPath.endsWith('.yaml') || configPath.endsWith('.yml')) {
        stderr.writeln(
          'Error: YAML configuration not yet supported. Use JSON or CLI flags.',
        );
        exit(2);
      } else {
        // Try JSON by default
        configMap = jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      stderr.writeln('Error: Failed to parse config file: $e');
      exit(2);
    }
  }

  // Override with command-line arguments
  final indentSize = argResults['indent-size'] as String;
  configMap['indent_size'] = int.parse(indentSize);

  final indentStyle = argResults['indent-style'] as String;
  configMap['indent_style'] = indentStyle;

  final quoteStyle = argResults['quote-style'] as String;
  configMap['quote_style'] = quoteStyle;

  return FormatterConfig.fromMap(configMap);
}
