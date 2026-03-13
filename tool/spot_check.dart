import 'dart:io';

import 'package:args/args.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/lexer/lexer.dart';

/// Spot-check tool for verifying parser and formatter correctness.
///
/// Checks that formatting doesn't strip directives, echoes, components,
/// HTML tags, or attributes, and that the formatter is idempotent.
///
/// Usage:
///   dart run tool/spot_check.dart                          # Check all stress fixtures
///   dart run tool/spot_check.dart <file-or-dir>            # Check specific file(s)
///   dart run tool/spot_check.dart --format <file>          # Show formatted output
///   dart run tool/spot_check.dart --ast <file>             # Show AST tree
///   dart run tool/spot_check.dart --tokens <file>          # Show token stream
///   dart run tool/spot_check.dart --diff <file>            # Show idempotency diff
///   dart run tool/spot_check.dart --passes 3 <file>        # Check N-pass idempotency
void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag('format', abbr: 'f', negatable: false, help: 'Show formatted output')
    ..addFlag('ast', abbr: 'a', negatable: false, help: 'Show AST tree')
    ..addFlag('tokens', abbr: 't', negatable: false, help: 'Show token stream')
    ..addFlag('diff', abbr: 'd', negatable: false, help: 'Show idempotency diff')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Show per-file details')
    ..addOption('passes',
        abbr: 'p', defaultsTo: '2', help: 'Number of format passes for idempotency');

  ArgResults argResults;
  try {
    argResults = parser.parse(args);
  } on FormatException catch (e) {
    print('Error: ${e.message}\n');
    _printUsage(parser);
    exit(2);
  }

  if (argResults.flag('help')) {
    _printUsage(parser);
    exit(0);
  }

  final passes = int.tryParse(argResults.option('passes')!) ?? 2;
  final showFormat = argResults.flag('format');
  final showAst = argResults.flag('ast');
  final showTokens = argResults.flag('tokens');
  final showDiff = argResults.flag('diff');
  final verbose = argResults.flag('verbose');

  // Determine files to check
  final targets = argResults.rest;
  final files = <File>[];

  if (targets.isEmpty) {
    // Default: all stress fixtures
    files.addAll(_findBladeFiles('test/fixtures/stress'));
  } else {
    for (final target in targets) {
      final entity = FileSystemEntity.typeSync(target);
      if (entity == FileSystemEntityType.directory) {
        files.addAll(_findBladeFiles(target));
      } else if (entity == FileSystemEntityType.file) {
        files.add(File(target));
      } else {
        print('Warning: $target not found, skipping');
      }
    }
  }

  if (files.isEmpty) {
    print('No .blade.php files found.');
    exit(1);
  }

  // Single-file inspection modes
  if (showFormat || showAst || showTokens || showDiff) {
    if (files.length != 1) {
      print('Inspection modes (--format, --ast, --tokens, --diff) require exactly one file.');
      exit(2);
    }
    final source = files.first.readAsStringSync();

    if (showTokens) {
      _printTokens(source);
    }
    if (showAst) {
      _printAst(source);
    }
    if (showFormat) {
      _printFormatted(source);
    }
    if (showDiff) {
      _printIdempotencyDiff(source, passes);
    }
    exit(0);
  }

  // Batch spot-check mode
  final results = <_FileResult>[];
  for (final file in files) {
    results.add(_checkFile(file, passes));
  }

  // Report
  _printReport(results, verbose);

  final failed = results.where((r) => !r.passed).length;
  exit(failed > 0 ? 1 : 0);
}

// ---------------------------------------------------------------------------
// Spot-check logic
// ---------------------------------------------------------------------------

class _FileResult {
  final String path;
  final int lines;
  final int parseErrors;
  final bool idempotent;
  final bool formatterCrashed;
  final String? crashMessage;
  final List<String> defects;

  bool get passed => idempotent && !formatterCrashed && defects.isEmpty;

  _FileResult({
    required this.path,
    required this.lines,
    required this.parseErrors,
    required this.idempotent,
    this.formatterCrashed = false,
    this.crashMessage,
    this.defects = const [],
  });
}

_FileResult _checkFile(File file, int passes) {
  final source = file.readAsStringSync();
  final lines = source.split('\n').length;
  final bladeParser = BladeParser();
  final result = bladeParser.parse(source);
  final parseErrors = result.errors.length;

  // Format
  final formatter = BladeFormatter();
  List<String> formatted;
  try {
    formatted = List.generate(passes, (_) => '');
    formatted[0] = formatter.format(source);
    for (var i = 1; i < passes; i++) {
      formatted[i] = formatter.format(formatted[i - 1]);
    }
  } catch (e) {
    return _FileResult(
      path: file.path,
      lines: lines,
      parseErrors: parseErrors,
      idempotent: false,
      formatterCrashed: true,
      crashMessage: e.toString(),
    );
  }

  // Idempotency
  bool idempotent = true;
  for (var i = 1; i < passes; i++) {
    if (formatted[i] != formatted[i - 1]) {
      idempotent = false;
      break;
    }
  }

  // Defect checks
  final defects = _detectDefects(source, formatted[0]);

  return _FileResult(
    path: file.path,
    lines: lines,
    parseErrors: parseErrors,
    idempotent: idempotent,
    defects: defects,
  );
}

List<String> _detectDefects(String source, String formatted) {
  final defects = <String>[];

  // 1. Directive counts (with normalization grouping)
  final directives = [
    '@if', '@elseif', '@else',
    '@foreach', '@endforeach', '@forelse', '@endforelse',
    '@for', '@endfor', '@while', '@endwhile',
    '@switch', '@endswitch', '@case', '@default',
    '@auth', '@endauth', '@guest', '@endguest',
    '@can', '@endcan', '@cannot', '@endcannot',
    '@section', '@endsection', '@show', '@stop', '@append',
    '@push', '@endpush', '@prepend', '@endprepend',
    '@once', '@endonce', '@verbatim', '@endverbatim',
    '@error', '@enderror', '@slot', '@endslot',
    '@props', '@php', '@endphp',
    '@extends', '@yield', '@include', '@each',
    '@csrf', '@method', '@vite', '@json',
    '@class', '@style', '@checked', '@selected',
    '@disabled', '@readonly', '@required',
    '@inject', '@use', '@aware',
    '@env', '@endenv', '@production', '@endproduction',
    '@session', '@endsession', '@context', '@endcontext',
    '@fragment', '@endfragment',
    '@component', '@endcomponent',
    '@livewire',
  ];

  // Closing directives that the formatter may normalize between
  final closingNormalized = {'@endif', '@endisset', '@endempty', '@endunless'};

  for (final d in directives) {
    final sc = _directiveCount(d, source);
    final fc = _directiveCount(d, formatted);
    if (fc < sc && !closingNormalized.contains(d)) {
      defects.add('Directive "$d" dropped: $sc → $fc');
    }
  }

  // Check normalized closing group total
  int srcTotal = 0, fmtTotal = 0;
  for (final d in closingNormalized) {
    srcTotal += _directiveCount(d, source);
    fmtTotal += _directiveCount(d, formatted);
  }
  if (fmtTotal < srcTotal) {
    defects.add(
        'Closing directives (endif/endisset/endempty/endunless) total dropped: $srcTotal → $fmtTotal');
  }

  // 2. Echo expressions
  _checkCount(defects, source, formatted, RegExp(r'\{\{[^-]'), '{{ echo }}');
  _checkCount(defects, source, formatted, RegExp(r'\{!!'), '{!! raw echo !!}');

  // 3. Blade comments
  _checkCount(defects, source, formatted, RegExp(r'\{\{--'), '{{-- comment --}}');

  // 4. Components
  _checkCount(defects, source, formatted, RegExp(r'<x-[a-zA-Z]'), '<x-component>');
  _checkCount(defects, source, formatted, RegExp(r'</x-[a-zA-Z]'), '</x-component>');

  // 5. HTML tags (common block/form elements)
  for (final tag in [
    'div', 'span', 'button', 'input', 'select', 'option', 'form',
    'a', 'p', 'ul', 'li', 'table', 'tr', 'td', 'th',
    'label', 'textarea', 'img', 'template', 'nav', 'main',
    'header', 'footer', 'section', 'article',
  ]) {
    _checkCount(defects, source, formatted, RegExp('<$tag[\\s>]'), '<$tag>');
    _checkCount(defects, source, formatted, RegExp('</$tag>'), '</$tag>');
  }

  // 6. wire: attributes (Livewire)
  _checkCount(defects, source, formatted, RegExp(r'wire:[a-z]'), 'wire:* attrs');

  // 7. x- attributes (Alpine.js)
  _checkCount(defects, source, formatted, RegExp(r'x-[a-z]'), 'x-* attrs');

  return defects;
}

int _directiveCount(String directive, String text) {
  return RegExp(RegExp.escape(directive) + r'(?=[^a-zA-Z0-9]|$)')
      .allMatches(text)
      .length;
}

void _checkCount(List<String> defects, String source, String formatted,
    RegExp pattern, String label) {
  final sc = pattern.allMatches(source).length;
  final fc = pattern.allMatches(formatted).length;
  if (fc < sc) {
    defects.add('$label count dropped: $sc → $fc');
  }
}

// ---------------------------------------------------------------------------
// Inspection modes
// ---------------------------------------------------------------------------

void _printTokens(String source) {
  final lexer = BladeLexer(source);
  final tokens = lexer.tokenize();
  for (final t in tokens) {
    final value = t.value.replaceAll('\n', '\\n');
    final preview = value.length > 80 ? '${value.substring(0, 77)}...' : value;
    print('${t.startPosition.line.toString().padLeft(4)}:${t.startPosition.column.toString().padRight(4)} '
        '${t.type.name.padRight(28)} |$preview|');
  }
}

void _printAst(String source) {
  final parser = BladeParser();
  final result = parser.parse(source);

  if (result.errors.isNotEmpty) {
    print('Parse errors: ${result.errors.length}');
    for (final err in result.errors) {
      print('  - ${err.message} at ${err.position}');
    }
    print('');
  }

  if (result.ast != null) {
    _printNode(result.ast!, 0);
  }
}

void _printNode(AstNode node, int depth) {
  final indent = '  ' * depth;

  switch (node) {
    case DocumentNode():
      print('${indent}Document');
    case DirectiveNode():
      final expr = node.expression != null ? '(${node.expression})' : '';
      print('${indent}Directive: @${node.name}$expr [${node.startPosition.line}:${node.startPosition.column}]');
    case HtmlElementNode():
      print(
          '${indent}HtmlElement: <${node.tagName}> tagHead=${node.tagHead.length} attrs=${node.attributes.length} [${node.startPosition.line}:${node.startPosition.column}]');
      _printTagHead(node.tagHead, depth);
    case ComponentNode():
      print(
          '${indent}Component: <x-${node.name}> tagHead=${node.tagHead.length} attrs=${node.attributes.length} [${node.startPosition.line}:${node.startPosition.column}]');
      _printTagHead(node.tagHead, depth);
    case TextNode():
      final preview = node.content.trim();
      if (preview.isNotEmpty) {
        final short = preview.length > 60 ? '${preview.substring(0, 57)}...' : preview;
        print('${indent}Text: "$short" [${node.startPosition.line}]');
      }
      return; // no children
    case EchoNode():
      final delim = node.isRaw ? '{!! !!}' : '{{ }}';
      print('${indent}Echo: $delim ${node.expression} [${node.startPosition.line}]');
      return;
    case CommentNode():
      final short = node.content.trim();
      final preview = short.length > 40 ? '${short.substring(0, 37)}...' : short;
      print('${indent}Comment: $preview [${node.startPosition.line}]');
      return;
    case PhpBlockNode():
      print('${indent}PhpBlock: ${node.syntax.name} [${node.startPosition.line}]');
      return;
    case ErrorNode():
      print('${indent}ERROR: ${node.error} [${node.startPosition.line}]');
      return;
    case RecoveryNode():
      final short = node.content.trim();
      final preview = short.isNotEmpty
          ? short.length > 40 ? '${short.substring(0, 37)}...' : short
          : node.reason;
      print('${indent}Recovery: $preview [${node.startPosition.line}]');
      return;
    case SlotNode():
      print('${indent}Slot: ${node.name} [${node.startPosition.line}]');
  }

  for (final child in node.children) {
    _printNode(child, depth + 1);
  }
}

void _printTagHead(List<TagHeadItem> items, int depth) {
  final indent = '  ' * (depth + 1);
  for (final item in items) {
    switch (item) {
      case TagHeadAttribute():
        print('${indent}TH-Attr: ${item.name}=${item.attribute.value}');
      case TagHeadDirective():
        final expr = item.expression != null ? ' ${item.expression}' : '';
        print('${indent}TH-Dir: @${item.name}$expr');
      case TagHeadComment():
        print('${indent}TH-Comment: ${item.content}');
      case TagHeadPhpBlock():
        print('${indent}TH-Php: ${item.content}');
      case TagHeadRecovery():
        print(
          '${indent}TH-Recovery: ${item.node.reason} (${item.node.content})',
        );
    }
  }
}

void _printFormatted(String source) {
  final formatter = BladeFormatter();
  try {
    print(formatter.format(source));
  } catch (e) {
    print('FORMATTER ERROR: $e');
    print('');
    _printAst(source);
  }
}

void _printIdempotencyDiff(String source, int passes) {
  final formatter = BladeFormatter();
  final results = <String>[];

  try {
    results.add(formatter.format(source));
    for (var i = 1; i < passes; i++) {
      results.add(formatter.format(results[i - 1]));
    }
  } catch (e) {
    print('FORMATTER ERROR on pass ${results.length + 1}: $e');
    exit(1);
  }

  bool anyDiff = false;
  for (var i = 1; i < results.length; i++) {
    if (results[i] == results[i - 1]) {
      print('✅ Pass ${i + 1} == Pass $i');
      continue;
    }
    anyDiff = true;
    print('❌ Pass ${i + 1} differs from Pass $i:');

    final l1 = results[i - 1].split('\n');
    final l2 = results[i].split('\n');
    final maxLines = l1.length > l2.length ? l1.length : l2.length;
    var shown = 0;

    for (var j = 0; j < maxLines && shown < 20; j++) {
      final a = j < l1.length ? l1[j] : '<EOF>';
      final b = j < l2.length ? l2[j] : '<EOF>';
      if (a != b) {
        print('  Line ${j + 1}:');
        print('    P$i: |$a|');
        print('    P${i + 1}: |$b|');
        shown++;
      }
    }
    if (l1.length != l2.length) {
      print('  Line count: P$i=${l1.length} P${i + 1}=${l2.length}');
    }
  }

  if (!anyDiff) {
    print('✅ All $passes passes are identical');
  }
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

void _printReport(List<_FileResult> results, bool verbose) {
  final passed = results.where((r) => r.passed).length;
  final failed = results.where((r) => !r.passed).length;
  final total = results.length;

  for (final r in results) {
    final name = r.path.split('/').last;
    final status = r.passed ? '✅' : '❌';
    final errors = r.parseErrors > 0 ? ' (${r.parseErrors} parse errors)' : '';

    if (r.passed && !verbose) continue;

    print('$status $name (${r.lines} lines$errors)');

    if (r.formatterCrashed) {
      print('   ❌ FORMATTER CRASH: ${r.crashMessage}');
    }
    if (!r.idempotent) {
      print('   ❌ NOT IDEMPOTENT');
    }
    for (final d in r.defects) {
      print('   ❌ $d');
    }
  }

  print('');
  if (failed == 0) {
    print('✅ All $total fixtures passed ($passed/$total)');
  } else {
    print('❌ $failed of $total fixtures failed ($passed passed)');
  }
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

List<File> _findBladeFiles(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.blade.php'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void _printUsage(ArgParser parser) {
  print('Blade Parser Spot Check Tool\n');
  print('Usage:');
  print('  dart run tool/spot_check.dart [options] [file-or-dir...]\n');
  print('Modes:');
  print('  (default)      Batch spot-check: parse, format, check idempotency and content');
  print('  --format, -f   Show formatted output for a single file');
  print('  --ast, -a      Show AST tree for a single file');
  print('  --tokens, -t   Show lexer token stream for a single file');
  print('  --diff, -d     Show idempotency diff between format passes\n');
  print('Options:');
  print(parser.usage);
  print('\nExamples:');
  print('  dart run tool/spot_check.dart                                  # All stress fixtures');
  print('  dart run tool/spot_check.dart test/fixtures/stress/contoso/    # Contoso fixtures');
  print('  dart run tool/spot_check.dart -v test/fixtures/stress/contoso/ # Verbose (show passing too)');
  print('  dart run tool/spot_check.dart --format some_file.blade.php     # Formatted output');
  print('  dart run tool/spot_check.dart --ast some_file.blade.php        # AST tree');
  print('  dart run tool/spot_check.dart --tokens some_file.blade.php     # Token stream');
  print('  dart run tool/spot_check.dart --diff some_file.blade.php       # Idempotency diff');
  print('  dart run tool/spot_check.dart -p 5 --diff some_file.blade.php  # 5-pass idempotency');
}
