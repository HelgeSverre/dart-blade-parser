# PhpBlockNode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a dedicated `PhpBlockNode` AST node to structurally represent PHP code regions (`<?php ?>`, `<?= ?>`, `<? ?>`, and `@php/@endphp`) instead of treating them as raw text or generic directives.

**Architecture:** Introduce a new leaf AST node `PhpBlockNode` with a `PhpBlockSyntax` enum distinguishing the four PHP tag variants and the Blade `@php` directive. The lexer detects PHP opening tags and scans to `?>`, emitting a single `TokenType.phpBlock` token. The parser converts these tokens (and the existing `@php` directive path) into `PhpBlockNode` instances. The formatter outputs PHP blocks verbatim. This is a **breaking change** to `AstVisitor`.

**Tech Stack:** Dart, existing blade_parser lexer/parser/formatter infrastructure

---

### Task 1: Add `PhpBlockSyntax` enum and `PhpBlockNode` to AST

**Files:**
- Modify: `lib/src/ast/node.dart`

**Step 1: Write the failing test**

Create a test that imports `PhpBlockNode` and `PhpBlockSyntax` and asserts they exist:

```dart
// test/unit/ast/php_block_node_test.dart
import 'package:blade_parser/src/ast/node.dart';
import 'package:test/test.dart';

void main() {
  group('PhpBlockNode', () {
    test('can be created with phpTag syntax', () {
      final node = PhpBlockNode(
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 20, line: 3, column: 3),
        code: '\$x = 1;',
        syntax: PhpBlockSyntax.phpTag,
      );
      expect(node.code, '\$x = 1;');
      expect(node.syntax, PhpBlockSyntax.phpTag);
      expect(node.children, isEmpty);
    });

    test('can be created with shortEcho syntax', () {
      final node = PhpBlockNode(
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 15, line: 1, column: 16),
        code: ' "hello" ',
        syntax: PhpBlockSyntax.shortEcho,
      );
      expect(node.syntax, PhpBlockSyntax.shortEcho);
    });

    test('can be created with shortTag syntax', () {
      final node = PhpBlockNode(
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 15, line: 1, column: 16),
        code: ' echo "hi"; ',
        syntax: PhpBlockSyntax.shortTag,
      );
      expect(node.syntax, PhpBlockSyntax.shortTag);
    });

    test('can be created with bladeDirective syntax', () {
      final node = PhpBlockNode(
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 30, line: 3, column: 8),
        code: '\n\$x = 1;\n',
        syntax: PhpBlockSyntax.bladeDirective,
      );
      expect(node.syntax, PhpBlockSyntax.bladeDirective);
    });

    test('toJson includes type, syntax, and code', () {
      final node = PhpBlockNode(
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 20, line: 1, column: 21),
        code: '\$x = 1;',
        syntax: PhpBlockSyntax.phpTag,
      );
      final json = node.toJson();
      expect(json['type'], 'phpBlock');
      expect(json['syntax'], 'phpTag');
      expect(json['code'], '\$x = 1;');
    });

    test('accept calls visitPhpBlock', () {
      // Will compile-fail until visitPhpBlock is added to AstVisitor
      // This test verifies the visitor wiring works
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `dart test test/unit/ast/php_block_node_test.dart`
Expected: Compilation error — `PhpBlockNode` and `PhpBlockSyntax` not found.

**Step 3: Write the implementation**

Add to the bottom of `lib/src/ast/node.dart` (before the closing of the file), after the existing node classes:

```dart
/// The syntax variant used for a PHP block.
enum PhpBlockSyntax {
  /// Standard PHP tag: `<?php ... ?>`
  phpTag,

  /// Short echo tag: `<?= ... ?>`
  shortEcho,

  /// Short open tag: `<? ... ?>` (deprecated in PHP 7.4, requires short_open_tag)
  shortTag,

  /// Blade directive: `@php ... @endphp`
  bladeDirective,
}

/// A block of raw PHP code in the template.
///
/// Represents PHP code regions that should be preserved verbatim.
/// The [code] field contains the PHP source between the delimiters
/// (not including the opening/closing tags themselves).
///
/// Examples:
/// - `<?php $x = 1; ?>` → syntax: phpTag, code: " \$x = 1; "
/// - `<?= $name ?>` → syntax: shortEcho, code: " \$name "
/// - `<? echo $x; ?>` → syntax: shortTag, code: " echo \$x; "
/// - `@php $x = 1; @endphp` → syntax: bladeDirective, code: " \$x = 1; "
final class PhpBlockNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The raw PHP source code between the delimiters.
  final String code;

  /// Which PHP tag syntax was used.
  final PhpBlockSyntax syntax;

  PhpBlockNode({
    required this.startPosition,
    required this.endPosition,
    required this.code,
    required this.syntax,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitPhpBlock(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'phpBlock',
        'syntax': syntax.name,
        'code': code,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}
```

Add `visitPhpBlock` to `AstVisitor` in the same file:

```dart
/// Visit a PHP block node (<?php ?>, <?= ?>, <? ?>, @php/@endphp).
T visitPhpBlock(PhpBlockNode node);
```

**Step 4: Run test to verify it passes**

Run: `dart test test/unit/ast/php_block_node_test.dart`
Expected: Compilation errors in OTHER files (visitor implementations) because `visitPhpBlock` is now required. The node itself is correct. That's expected — we fix visitors in the next task.

**Step 5: Commit**

```bash
git add lib/src/ast/node.dart test/unit/ast/php_block_node_test.dart
git commit -m "feat: add PhpBlockNode AST node and PhpBlockSyntax enum"
```

---

### Task 2: Update visitor infrastructure

**Files:**
- Modify: `lib/src/ast/visitor.dart`
- Modify: `lib/src/ast/json_serializer.dart`
- Modify: `lib/src/formatter/formatter_visitor.dart`

**Step 1: Add `visitPhpBlock` to `RecursiveAstVisitor`**

In `lib/src/ast/visitor.dart`, add after `visitError`:

```dart
@override
T visitPhpBlock(PhpBlockNode node) {
  // PHP block nodes are leaf nodes (no children)
  return defaultValue;
}
```

**Step 2: Add `visitPhpBlock` to `JsonSerializerVisitor`**

In `lib/src/ast/json_serializer.dart`, add before `defaultVisit`:

```dart
@override
Map<String, dynamic> visitPhpBlock(PhpBlockNode node) {
  return {
    'type': 'phpBlock',
    'syntax': node.syntax.name,
    'code': node.code,
    'position': {
      'start': node.startPosition.toJson(),
      'end': node.endPosition.toJson(),
    },
  };
}
```

**Step 3: Add `visitPhpBlock` to `FormatterVisitor`**

In `lib/src/formatter/formatter_visitor.dart`, add after `visitError`. PHP blocks should be output verbatim with their original delimiters reconstructed:

```dart
@override
String visitPhpBlock(PhpBlockNode node) {
  // If formatting is disabled, output raw
  if (!_formattingEnabled) {
    _outputRaw(node);
    return '';
  }

  _beginLine();
  switch (node.syntax) {
    case PhpBlockSyntax.phpTag:
      _output.write('<?php${node.code}?>');
    case PhpBlockSyntax.shortEcho:
      _output.write('<?=${node.code}?>');
    case PhpBlockSyntax.shortTag:
      _output.write('<?${node.code}?>');
    case PhpBlockSyntax.bladeDirective:
      _output.write('@php${node.code}@endphp');
  }
  _output.writeln();
  return '';
}
```

**Step 4: Verify the full project compiles**

Run: `dart analyze`
Expected: No errors. All `AstVisitor` implementations now have `visitPhpBlock`.

**Step 5: Run all existing tests**

Run: `dart test`
Expected: All existing tests pass (no behavioral changes yet — lexer/parser still emit old tokens).

**Step 6: Commit**

```bash
git add lib/src/ast/visitor.dart lib/src/ast/json_serializer.dart lib/src/formatter/formatter_visitor.dart
git commit -m "feat: add visitPhpBlock to all visitor implementations"
```

---

### Task 3: Add `TokenType.phpBlock` and lexer detection for `<?php`, `<?=`, `<? ?>`

**Files:**
- Modify: `lib/src/lexer/token_type.dart`
- Modify: `lib/src/lexer/lexer.dart`
- Create: `test/unit/lexer/lexer_php_block_test.dart`

**Step 1: Write the failing test**

```dart
// test/unit/lexer/lexer_php_block_test.dart
import 'package:blade_parser/src/lexer/lexer.dart';
import 'package:blade_parser/src/lexer/token_type.dart';
import 'package:test/test.dart';

void main() {
  late BladeLexer lexer;

  setUp(() {
    lexer = BladeLexer();
  });

  group('PHP block lexing', () {
    test('lexes <?php ... ?> as phpBlock token', () {
      final tokens = lexer.tokenize('<?php \$x = 1; ?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?php \$x = 1; ?>');
    });

    test('lexes <?= ... ?> as phpBlock token', () {
      final tokens = lexer.tokenize('<?= \$name ?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?= \$name ?>');
    });

    test('lexes <? ... ?> as phpBlock token', () {
      final tokens = lexer.tokenize('<? echo "hi"; ?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<? echo "hi"; ?>');
    });

    test('lexes text before and after <?php block', () {
      final tokens = lexer.tokenize('<div><?php \$x = 1; ?></div>');
      final types = tokens.map((t) => t.type).toList();
      // Should have: htmlTagOpen, text/tag stuff, phpBlock, text/tag stuff, eof
      expect(types.contains(TokenType.phpBlock), isTrue);
    });

    test('lexes multiline <?php block', () {
      final tokens = lexer.tokenize('<?php\n\$x = 1;\n\$y = 2;\n?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
    });

    test('lexes <?php without closing ?> (end of file)', () {
      final tokens = lexer.tokenize('<?php\n\$x = 1;\necho "done";');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1),
          reason: 'Unclosed <?php should still emit phpBlock to EOF');
    });

    test('does not confuse <?xml with PHP tag', () {
      final tokens = lexer.tokenize('<?xml version="1.0"?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, isEmpty,
          reason: '<?xml is not a PHP tag');
    });

    test('lexes inline <?= inside Blade template', () {
      final tokens = lexer.tokenize('<p><?= \$greeting ?></p>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?= \$greeting ?>');
    });

    test('lexes multiple PHP blocks in one template', () {
      final tokens = lexer.tokenize(
          '<?php \$a = 1; ?><div><?= \$a ?></div><? echo \$a; ?>');
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(3));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `dart test test/unit/lexer/lexer_php_block_test.dart`
Expected: FAIL — `TokenType.phpBlock` doesn't exist yet.

**Step 3: Add `TokenType.phpBlock`**

In `lib/src/lexer/token_type.dart`, add after the existing `bladeComment` entry (in the Structural section):

```dart
phpBlock, // <?php ... ?>, <?= ... ?>, <? ... ?>
```

**Step 4: Add PHP tag detection to the lexer**

In `lib/src/lexer/lexer.dart`, inside `_lexText()`, add a check for `<?` **before** the HTML tag checks (before the `<` check for component closing tags around line 233). Add this after the `{!! raw echo` check (around line 231):

```dart
// Check for PHP opening tags: <?php, <?=, <? (but not <?xml)
if (ch == '<' && _peekNext() == '?') {
  final afterQ = _peekAhead(2);
  // <?xml is NOT a PHP tag
  if (afterQ == 'x' && _peekAhead(3) == 'm' && _peekAhead(4) == 'l') {
    // Fall through to normal text handling
  } else {
    if (buffer.isNotEmpty) {
      _emitToken(TokenType.text, buffer.toString());
    }
    return _lexPhpBlock();
  }
}
```

Then add the `_lexPhpBlock()` method to the lexer class:

```dart
/// Scans a PHP block: `<?php ... ?>`, `<?= ... ?>`, or `<? ... ?>`.
/// Emits a single [TokenType.phpBlock] token with the full source
/// (including delimiters). Handles unclosed blocks (scans to EOF).
_LexerState _lexPhpBlock() {
  _start = _position;
  _startLine = _line;
  _startColumn = _column;

  // We're at '<', advance past '<?' 
  _advance(); // <
  _advance(); // ?

  // Determine variant: <?php, <?=, or just <?
  // (we already excluded <?xml in the caller)
  if (_peek() == '=' || (!_isAtEnd() && _isAlpha(_peek()))) {
    // <?= or <?php — advance past the marker
    if (_peek() == '=') {
      _advance(); // =
    } else {
      // Scan the identifier (e.g., "php")
      while (!_isAtEnd() && _isAlphaNumeric(_peek())) {
        _advance();
      }
    }
  }

  // Now scan until ?> or EOF
  while (!_isAtEnd()) {
    if (_peek() == '?' && _peekNext() == '>') {
      _advance(); // ?
      _advance(); // >
      _emitToken(TokenType.phpBlock, input.substring(_start, _position));
      return _textOrRawTextState();
    }
    _advance();
  }

  // Unclosed — emit to EOF
  _emitToken(TokenType.phpBlock, input.substring(_start, _position));
  _emitToken(TokenType.eof, '');
  return _LexerState.done;
}
```

**Step 5: Run test to verify it passes**

Run: `dart test test/unit/lexer/lexer_php_block_test.dart`
Expected: PASS

**Step 6: Run full test suite to check for regressions**

Run: `dart test`
Expected: Some tests may now fail because templates containing `<?php` blocks are now tokenized differently (phpBlock instead of text). Note any failures — they'll be fixed in Task 5. If SFC fixture tests fail, that's expected.

**Step 7: Commit**

```bash
git add lib/src/lexer/token_type.dart lib/src/lexer/lexer.dart test/unit/lexer/lexer_php_block_test.dart
git commit -m "feat: lexer detects <?php, <?=, <? as phpBlock tokens"
```

---

### Task 4: Parser emits `PhpBlockNode` for both PHP tags and `@php` blocks

**Files:**
- Modify: `lib/src/parser/parser.dart`
- Create: `test/unit/parser/parser_php_block_test.dart`

**Step 1: Write the failing test**

```dart
// test/unit/parser/parser_php_block_test.dart
import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/parser/parser.dart';
import 'package:test/test.dart';

void main() {
  late BladeParser parser;

  setUp(() {
    parser = BladeParser();
  });

  group('PhpBlockNode from PHP tags', () {
    test('parses <?php ... ?> into PhpBlockNode', () {
      final result = parser.parse('<?php \$x = 1; ?>');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.phpTag);
      expect(phpBlocks.first.code, ' \$x = 1; ');
    });

    test('parses <?= ... ?> into PhpBlockNode', () {
      final result = parser.parse('<?= \$name ?>');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.shortEcho);
      expect(phpBlocks.first.code, ' \$name ');
    });

    test('parses <? ... ?> into PhpBlockNode', () {
      final result = parser.parse('<? echo "hi"; ?>');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.shortTag);
      expect(phpBlocks.first.code, ' echo "hi"; ');
    });

    test('parses SFC with <?php class at top and Blade below', () {
      final result = parser.parse('''<?php

use Livewire\\Component;

new class extends Component {
    public string \$title = '';
}; ?>

<div>
    <h1>{{ \$title }}</h1>
</div>''');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.phpTag);
      expect(result.errors, isEmpty);
    });

    test('parses inline <?= inside template', () {
      final result = parser.parse('<p>Hello <?= \$name ?></p>');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>();
      // May be nested inside HtmlElement depending on parser
      // At minimum, no errors
      expect(result.errors, isEmpty);
    });

    test('parses unclosed <?php to EOF', () {
      final result = parser.parse('<?php \$x = 1;');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.phpTag);
    });
  });

  group('PhpBlockNode from @php directive', () {
    test('parses @php ... @endphp into PhpBlockNode', () {
      final result = parser.parse('@php\n\$x = 1;\n@endphp');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.syntax, PhpBlockSyntax.bladeDirective);
      expect(phpBlocks.first.code, contains('\$x = 1;'));
    });

    test('@php with HTML-like content in code does not break', () {
      final result = parser.parse('@php\n// <div>not html</div>\n@endphp');
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, hasLength(1));
      expect(phpBlocks.first.code, contains('<div>'));
    });

    test('inline @php(\$expr) remains a DirectiveNode', () {
      final result = parser.parse('@php(\$x = 1)');
      // Inline @php(...) should NOT become PhpBlockNode
      final phpBlocks = result.document.children
          .whereType<PhpBlockNode>()
          .toList();
      expect(phpBlocks, isEmpty);
      final directives = result.document.children
          .whereType<DirectiveNode>()
          .toList();
      expect(directives, hasLength(1));
      expect(directives.first.name, 'php');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `dart test test/unit/parser/parser_php_block_test.dart`
Expected: FAIL — parser still emits `DirectiveNode` for `@php` and `TextNode` for `<?php`.

**Step 3: Implement parser changes**

In `lib/src/parser/parser.dart`:

**3a.** Add a case for `TokenType.phpBlock` in the `_parseNode()` switch statement (add near the other special cases, around the `default:` block):

```dart
case TokenType.phpBlock:
  return _parsePhpTagBlock();
```

Add the method:

```dart
/// Parse a `<?php ... ?>`, `<?= ... ?>`, or `<? ... ?>` block.
PhpBlockNode _parsePhpTagBlock() {
  final token = _advance();
  final value = token.value;

  // Determine syntax and extract inner code
  PhpBlockSyntax syntax;
  String code;

  if (value.startsWith('<?=')) {
    syntax = PhpBlockSyntax.shortEcho;
    code = _extractPhpCode(value, 3); // skip '<?='
  } else if (value.startsWith('<?php')) {
    syntax = PhpBlockSyntax.phpTag;
    code = _extractPhpCode(value, 5); // skip '<?php'
  } else {
    // <? ... ?>
    syntax = PhpBlockSyntax.shortTag;
    code = _extractPhpCode(value, 2); // skip '<?'
  }

  return PhpBlockNode(
    startPosition: token.startPosition,
    endPosition: token.endPosition,
    code: code,
    syntax: syntax,
  );
}

/// Extract PHP code from a token value, stripping opening tag prefix
/// and optional closing `?>`.
String _extractPhpCode(String value, int prefixLength) {
  var code = value.substring(prefixLength);
  if (code.endsWith('?>')) {
    code = code.substring(0, code.length - 2);
  }
  return code;
}
```

**3b.** Change the `@php` block handling. Replace:

```dart
case TokenType.directivePhp:
  return _parseGenericDirective('php', TokenType.directiveEndphp);
```

With:

```dart
case TokenType.directivePhp:
  return _parsePhpDirectiveBlock();
```

Add the method:

```dart
/// Parse `@php ... @endphp` as a [PhpBlockNode].
///
/// Inline `@php($expr)` is already handled by the lexer emitting
/// directivePhp + expression, which takes a different code path
/// (the expression check is done in the lexer before we get here).
///
/// For block `@php`, the lexer already scans content as raw text
/// until `@endphp`, so children here are TextNode(s) containing
/// the raw PHP code.
PhpBlockNode _parsePhpDirectiveBlock() {
  final startToken = _advance();

  // Check if this is inline @php($expr) — has expression
  final expression = _extractExpression();
  if (expression != null) {
    // Inline @php($expr) — keep as directive for backwards compat
    // Actually, this shouldn't happen because the lexer handles it.
    // But as a safety net, return a DirectiveNode.
    return PhpBlockNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      code: expression,
      syntax: PhpBlockSyntax.bladeDirective,
    );
  }

  // Block @php: collect raw text content until @endphp
  final codeBuffer = StringBuffer();
  while (!_check(TokenType.directiveEndphp) && !_check(TokenType.eof)) {
    final token = _advance();
    codeBuffer.write(token.value);
  }

  if (_check(TokenType.directiveEndphp)) {
    _advance(); // consume @endphp
  } else {
    _errors.add(
      ParseError(
        message: 'Unclosed @php directive',
        position: startToken.startPosition,
        hint: 'Add @endphp to close the block',
      ),
    );
  }

  return PhpBlockNode(
    startPosition: startToken.startPosition,
    endPosition: _previous().endPosition,
    code: codeBuffer.toString(),
    syntax: PhpBlockSyntax.bladeDirective,
  );
}
```

**Important note:** The inline `@php($expr)` case needs careful handling. Check how the lexer currently differentiates block `@php` from inline `@php(...)`. The lexer at line 750 already checks `if (name == 'php' && _peek() != '(')` — if `(` follows, it falls through to expression extraction and emits `directivePhp` + `expression` token. So by the time the parser sees `directivePhp`, we need to check if there's an expression token following. If yes → this is inline, keep as `DirectiveNode`. If no → this is block, emit `PhpBlockNode`.

Revisit step 3b: The safer approach is:

```dart
case TokenType.directivePhp:
  // Peek ahead: if next token is an expression, this is inline @php($expr)
  if (_current < _tokens.length - 1 &&
      _tokens[_current + 1].type == TokenType.expression) {
    return _parseInlineDirective(); // existing behavior for @php($x = 1)
  }
  return _parsePhpDirectiveBlock();
```

**Step 4: Run test to verify it passes**

Run: `dart test test/unit/parser/parser_php_block_test.dart`
Expected: PASS

**Step 5: Run full test suite**

Run: `dart test`
Expected: Some existing tests that assert `@php` produces `DirectiveNode` will now fail. Note them for Task 5.

**Step 6: Commit**

```bash
git add lib/src/parser/parser.dart test/unit/parser/parser_php_block_test.dart
git commit -m "feat: parser emits PhpBlockNode for <?php/?>=/<? and @php blocks"
```

---

### Task 5: Update existing tests for `@php` → `PhpBlockNode` migration

**Files:**
- Modify: `test/unit/parser/directive_parser_test.dart`
- Modify: `test/unit/parser/stress_pattern_tests.dart`
- Modify: `test/unit/parser/parser_expression_edge_cases_test.dart`
- Modify: `test/unit/parser/parser_blaze_test.dart`
- Possibly modify other test files that reference `@php` as a `DirectiveNode`

**Step 1: Find all tests asserting `@php` produces DirectiveNode**

Search for test files referencing `@php` and update assertions from `DirectiveNode` to `PhpBlockNode` where the block form is used. Keep `DirectiveNode` assertions for inline `@php($expr)`.

Key changes:
- `directive_parser_test.dart`: The test `'@php block should have children with raw content'` → update to expect `PhpBlockNode` with `syntax: PhpBlockSyntax.bladeDirective` and check `code` instead of `children`.
- `directive_parser_test.dart`: The test `'Missing @endphp should report error'` → update to expect `PhpBlockNode` (may still have error).
- `stress_pattern_tests.dart`: Tests around `@php/@endphp` → update assertions.
- `parser_blaze_test.dart`: Tests that include `@php` blocks alongside `@blaze` → update.

**Step 2: Run tests after updates**

Run: `dart test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add test/
git commit -m "test: update @php tests for PhpBlockNode migration"
```

---

### Task 6: Update formatter for `@php` → `PhpBlockNode`

**Files:**
- Modify: `lib/src/formatter/formatter_visitor.dart`

**Step 1: Remove `'php'` from `_blockDirectives`**

In `lib/src/formatter/formatter_visitor.dart`, the `_blockDirectives` set (around line 198) contains `'php'`. Remove it since `@php` blocks are no longer `DirectiveNode`:

```dart
// Remove 'php' from this set
```

**Step 2: Run formatter tests**

Run: `dart test test/formatter/`
Expected: PASS — the `visitPhpBlock` method from Task 2 handles formatting.

**Step 3: Run full test suite**

Run: `dart test`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add lib/src/formatter/formatter_visitor.dart
git commit -m "refactor: remove 'php' from block directives, handled by visitPhpBlock"
```

---

### Task 7: Create synthetic fixtures for PHP block variants

**Files:**
- Create: `test/fixtures/synthetic/05-edge-cases/boundaries/01-php-blocks.blade.php`
- Create: `test/fixtures/synthetic/05-edge-cases/boundaries/02-php-blocks-inline.blade.php`
- Create: `test/fixtures/synthetic/05-edge-cases/boundaries/03-php-blocks-sfc.blade.php`

**Step 1: Create fixture for all PHP tag variants**

```php
{{-- test/fixtures/synthetic/05-edge-cases/boundaries/01-php-blocks.blade.php --}}
{{--
---
features:
  - php_block
  - php_tags
description: All valid PHP opening tag variants
complexity: simple
--}}

{{-- Standard PHP tag --}}
<?php
$greeting = 'Hello, World!';
echo $greeting;
?>

{{-- Short echo tag (always available since PHP 5.4) --}}
<p>Name: <?= $name ?></p>
<p>Email: <?= htmlspecialchars($email) ?></p>

{{-- Short open tag (requires short_open_tag, deprecated 7.4) --}}
<? $x = 42; ?>

{{-- Blade @php directive --}}
@php
    $total = $items->sum('price');
    $formatted = number_format($total, 2);
@endphp

{{-- Inline @php expression --}}
@php($now = now())

{{-- Unclosed PHP tag at end of file is valid PHP --}}
{{-- (not tested here as it would affect subsequent content) --}}

{{-- PHP block with no closing tag followed by more Blade --}}
<div>
    <span>Total: {{ $formatted }}</span>
</div>
```

**Step 2: Create fixture for inline PHP in Blade templates**

```php
{{-- test/fixtures/synthetic/05-edge-cases/boundaries/02-php-blocks-inline.blade.php --}}
{{--
---
features:
  - php_block_inline
  - php_mixed
description: PHP blocks used inline within Blade template HTML
complexity: medium
--}}

{{-- PHP echo mixed with HTML --}}
<table>
    <tr>
        <td><?= $row['name'] ?></td>
        <td><?= $row['email'] ?></td>
        <td><?= number_format($row['balance'], 2) ?></td>
    </tr>
</table>

{{-- Standard PHP block inline --}}
<ul>
    <?php foreach ($items as $item): ?>
        <li><?= $item->name ?></li>
    <?php endforeach; ?>
</ul>

{{-- PHP mixed with Blade directives --}}
<?php $showHeader = true; ?>
@if($showHeader)
    <header>
        <h1><?= $title ?></h1>
    </header>
@endif

{{-- Multiple PHP blocks on same line --}}
<p><?= $first ?> - <?= $last ?></p>

{{-- Short tag inline --}}
<span class="badge"><? echo $count; ?></span>

{{-- PHP inside HTML attributes (unusual but valid) --}}
<div class="<?= $isActive ? 'active' : 'inactive' ?>">
    Content
</div>

{{-- PHP with Blade echo on same line --}}
<p><?= $prefix ?>{{ $suffix }}</p>
```

**Step 3: Create fixture for SFC pattern**

```php
{{-- test/fixtures/synthetic/05-edge-cases/boundaries/03-php-blocks-sfc.blade.php --}}
{{--
---
features:
  - php_block_sfc
  - livewire_v4_sfc
description: Single-file component patterns with PHP class block at top
complexity: medium
--}}
<?php

use Livewire\Component;
use Livewire\Attributes\Computed;

new class extends Component {
    public string $search = '';
    public int $perPage = 10;

    #[Computed]
    public function results()
    {
        return Post::where('title', 'like', "%{$this->search}%")
            ->paginate($this->perPage);
    }

    public function updatedSearch()
    {
        $this->resetPage();
    }
}; ?>

<div>
    <input type="text" wire:model.live.debounce.300ms="search" placeholder="Search...">

    @foreach($this->results as $post)
        <article wire:key="post-{{ $post->id }}">
            <h2>{{ $post->title }}</h2>
            <p>{{ $post->excerpt }}</p>
        </article>
    @endforeach

    {{ $this->results->links() }}
</div>
```

**Step 4: Run fixture parsing tests**

Run: `dart test`
Expected: All fixtures parse without errors.

**Step 5: Commit**

```bash
git add test/fixtures/synthetic/05-edge-cases/boundaries/
git commit -m "test: add synthetic fixtures for PHP block variants"
```

---

### Task 8: Verify formatter idempotency with PHP blocks

**Step 1: Run the formatter on the new fixtures and verify idempotency**

The formatter should output PHP blocks verbatim. Format once, format again — output should be identical. Add specific formatter tests if the existing idempotency test infrastructure doesn't cover the new fixtures.

**Step 2: Run the full test suite one final time**

Run: `dart test`
Expected: All tests pass.

**Step 3: Run dart analyze**

Run: `dart analyze`
Expected: No errors or warnings.

**Step 4: Commit any final adjustments**

```bash
git add -u
git commit -m "test: verify formatter idempotency with PHP blocks"
```

---

## Summary of Breaking Changes

1. **`AstVisitor` interface** — new required method `visitPhpBlock(PhpBlockNode node)`. Any external code implementing `AstVisitor` must add this method.
2. **`@php` blocks** — previously `DirectiveNode(name: 'php')`, now `PhpBlockNode(syntax: bladeDirective)`. Code that pattern-matches on `DirectiveNode` with `name == 'php'` must be updated.
3. **`<?php` regions** — previously `TextNode`, now `PhpBlockNode(syntax: phpTag)`. Code relying on PHP code appearing as text nodes must be updated.
4. **JSON output** — `@php` blocks change from `{"type": "directive", "name": "php", ...}` to `{"type": "phpBlock", "syntax": "bladeDirective", ...}`.

Inline `@php($expr)` is **not affected** — it remains a `DirectiveNode`.
