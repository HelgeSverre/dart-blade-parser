import 'dart:convert';
import 'dart:io';
import 'package:blade_parser/blade_parser.dart';

void main(List<String> arguments) {
  bool jsonOutput = false;
  bool treeOutput = false;
  bool useStdin = false;
  String? filePath;

  // Parse arguments
  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--json':
        jsonOutput = true;
        break;
      case '--tree':
        treeOutput = true;
        break;
      case '--stdin':
        useStdin = true;
        break;
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      default:
        if (!arguments[i].startsWith('-')) {
          filePath = arguments[i];
        }
    }
  }

  // Default to tree output if neither specified
  if (!jsonOutput && !treeOutput) {
    treeOutput = true;
  }

  try {
    String source;

    if (useStdin) {
      source = stdin.readLineSync() ?? '';
    } else if (filePath != null) {
      source = File(filePath).readAsStringSync();
    } else {
      stderr.writeln('Error: No input provided');
      _printUsage();
      exit(2);
    }

    final parser = BladeParser();
    final result = parser.parse(source);

    if (result.errors.isNotEmpty) {
      for (final error in result.errors) {
        stderr.writeln(error);
      }
    }

    if (result.ast != null) {
      if (jsonOutput) {
        stdout.writeln(jsonEncode(result.ast!.toJson()));
      } else {
        _printTree(result.ast!, 0);
      }
    }

    exit(result.isSuccess ? 0 : 1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

void _printUsage() {
  print('''
Blade Parser CLI

Usage:
  blade_parser [options] <file>
  blade_parser [options] --stdin

Options:
  --json     Output AST as JSON
  --tree     Output AST as tree (default)
  --stdin    Read from stdin
  --help     Show this help

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
    print('${prefix}@${node.name}');
    for (final child in node.children) {
      _printTree(child, indent + 1);
    }
  } else if (node is EchoNode) {
    final type = node.isRaw ? 'RawEcho' : 'Echo';
    print('${prefix}$type: ${node.expression}');
  } else if (node is TextNode) {
    final preview = node.content.length > 30
        ? '${node.content.substring(0, 30)}...'
        : node.content;
    print('${prefix}Text: "$preview"');
  }
}
