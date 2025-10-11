import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:completion/completion.dart' as completion;

void main(List<String> arguments) {
  // Set up argument parser
  final argParser = ArgParser()
    ..addFlag('json', help: 'Output AST as JSON')
    ..addFlag('tree', help: 'Output AST as tree (default)', defaultsTo: true)
    ..addFlag('stdin', help: 'Read from stdin')
    ..addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);

  // Handle shell completion
  final argResults = completion.tryArgsCompletion(arguments, argParser);

  // If tryArgsCompletion handled the completion request, exit early
  if (argResults == null) {
    return;
  }

  // Handle non-completion requests
  if (argResults.command?.name == 'completion') {
    return;
  }

  // Show help if requested
  if (argResults['help'] as bool) {
    _printUsage(argParser);
    exit(0);
  }

  // Get options from parsed arguments
  final jsonOutput = argResults['json'] as bool;
  final useStdin = argResults['stdin'] as bool;
  final filePath = argResults.rest.isNotEmpty ? argResults.rest.first : null;

  try {
    String source;

    if (useStdin) {
      source = stdin.readLineSync() ?? '';
    } else if (filePath != null) {
      source = File(filePath).readAsStringSync();
    } else {
      stderr.writeln('Error: No input provided');
      _printUsage(argParser);
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

void _printUsage(ArgParser argParser) {
  print('''
Blade Parser CLI

Usage:
  blade_parser [options] <file>
  blade_parser [options] --stdin

Options:
${argParser.usage}

Shell Completion:
  To install shell completion, run:
    blade_parser completion install

Examples:
  blade_parser --json template.blade.php
  cat template.blade.php | blade_parser --stdin
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
