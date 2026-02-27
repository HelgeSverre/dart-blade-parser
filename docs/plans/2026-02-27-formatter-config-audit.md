# Formatter Config Audit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix broken/dead config options, add new useful config options (echoSpacing, htmlBlockSpacing, trailingNewline), and remove dead code (formatPhpExpressions).

**Architecture:** Six independent config changes to the formatter. Tasks 1/6 are simple additions/removals. Tasks 2/5 fix spacing logic in `_needsSpacingBetween()` and sibling iteration loops. Task 3 threads quote metadata through lexer→parser→AST→formatter. Task 4 adds echo expression raw storage and configurable echo brace spacing.

**Tech Stack:** Dart, TDD with `dart test`, Blade template parser/formatter.

**Test runner:** `dart test` (full suite), `dart test test/formatter/` (formatter only)

**Pre-existing failure:** Filament v2 repeater.blade.php idempotency test — ignore this.

---

## Task 1: Remove `formatPhpExpressions` config (dead code)

**Files:**
- Modify: `lib/src/formatter/formatter_config.dart`
- Modify: `test/formatter/formatter_config_test.dart`
- Modify: `bin/blade.dart`
- Modify: `.blade.json`

**Step 1: Remove the field, constructor param, fromMap, toMap, toString from FormatterConfig**

In `lib/src/formatter/formatter_config.dart`:
- Delete field `final bool formatPhpExpressions;` (line 17)
- Delete doc comment for it (lines 12-16)
- Delete constructor param `this.formatPhpExpressions = false,` (line 56)
- Delete fromMap line: `formatPhpExpressions: map['format_php_expressions'] as bool? ?? false,` (line 92)
- Delete toMap entry: `'format_php_expressions': formatPhpExpressions,` (line 118)
- Delete toString segment: `'formatPhpExpressions: $formatPhpExpressions, '` (line 137)

**Step 2: Update tests**

In `test/formatter/formatter_config_test.dart`, remove/update all references:
- Line 12: remove `expect(config.formatPhpExpressions, false);`
- Lines 41-45: delete test 'allows custom formatPhpExpressions'
- Lines 48-61: remove `formatPhpExpressions: true,` from constructor and `expect(config.formatPhpExpressions, true);`
- Line 70: remove `expect(config.formatPhpExpressions, false);`
- Lines 84-98: remove `'format_php_expressions': true,` from map and remove `expect(config.formatPhpExpressions, true);`
- Lines 141-150: remove entire test group entry for `format_php_expressions` when null
- Lines 234-249: remove tests 'handles format_php_expressions as false/true'
- Lines 252-268: update 'serializes all values correctly' — remove `formatPhpExpressions: true,` and `expect(map['format_php_expressions'], true);`
- Lines 307-337: update roundtrip tests — remove `formatPhpExpressions` references
- Lines 350-368: update toString test — remove `formatPhpExpressions: true,` and related expect
- Lines 399-448: update real-world scenario tests — remove `format_php_expressions` from maps and expects

**Step 3: Update CLI and config file**

In `bin/blade.dart`:
- Line 489: remove `"format_php_expressions": false,` from help text

In `.blade.json`:
- Remove `"format_php_expressions": false,` entry

**Step 4: Run tests and verify**

Run: `dart test test/formatter/formatter_config_test.dart`
Expected: All config tests pass.

Run: `dart test`
Expected: Full suite passes (minus pre-existing failure).

**Step 5: Commit**

```bash
git add lib/src/formatter/formatter_config.dart test/formatter/formatter_config_test.dart bin/blade.dart .blade.json
git commit -m "refactor: remove dead formatPhpExpressions config option"
```

---

## Task 2: Fix `DirectiveSpacing.preserve` (broken — acts same as `none`)

**Files:**
- Modify: `lib/src/formatter/formatter_visitor.dart`
- Modify: `test/formatter/formatter_test.dart`

### Analysis

The `visitDocument` loop (lines 628-639) already preserves blank lines from whitespace-only TextNodes that have 2+ newlines. This is how blank lines in source survive formatting. For `DirectiveSpacing.preserve`, the fix is:

1. `_needsSpacingBetween` should NOT inject blank lines (return false) for directive pairs — let the existing whitespace TextNode preservation handle it.
2. But there's a subtlety: whitespace TextNodes between directives inside `visitDirective` children (lines 708-711) are currently **skipped** (`continue`). This means preserve can't work for nested directives via TextNode preservation alone.

**Solution:** Add a `_sourceHasBlankLineBetween(AstNode a, AstNode b)` helper. For `preserve`, use source gap detection in `_needsSpacingBetween`. This is robust regardless of whether whitespace TextNodes survive.

**Step 1: Write failing tests**

In `test/formatter/formatter_test.dart`, add tests inside the directive spacing group:

```dart
test('preserves blank lines with DirectiveSpacing.preserve', () {
  final preserveFormatter = BladeFormatter(
    config: const FormatterConfig(
      directiveSpacing: DirectiveSpacing.preserve,
    ),
  );

  const input = '''
@foreach(\$items as \$item)
    <p>{{ \$item }}</p>
@endforeach

@while(\$count > 0)
    <p>Count: {{ \$count }}</p>
@endwhile
''';
  // Should preserve the blank line between directives
  final result = preserveFormatter.format(input);
  expect(result, contains('@endforeach\n\n@while'));
});

test('does not insert blank lines with DirectiveSpacing.preserve', () {
  final preserveFormatter = BladeFormatter(
    config: const FormatterConfig(
      directiveSpacing: DirectiveSpacing.preserve,
    ),
  );

  const input = '''
@foreach(\$items as \$item)
    <p>{{ \$item }}</p>
@endforeach
@while(\$count > 0)
    <p>Count: {{ \$count }}</p>
@endwhile
''';
  // Should NOT insert a blank line where there wasn't one
  final result = preserveFormatter.format(input);
  expect(result, contains('@endforeach\n@while'));
});
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/formatter/formatter_test.dart --name "preserves blank lines with DirectiveSpacing.preserve"`
Expected: FAIL — currently preserve acts like none, the first test fails because blank line is stripped.

**Step 3: Implement the fix**

In `lib/src/formatter/formatter_visitor.dart`:

Add helper method to the `FormatterVisitor` class (after `_outputRaw` around line 374):

```dart
/// Checks if the original source has a blank line between two nodes.
///
/// Used by preserve-style spacing configs to detect whether the author
/// intended a visual break between elements.
bool _sourceHasBlankLineBetween(AstNode a, AstNode b) {
  final source = _source;
  if (source == null) return false;
  final start = a.endPosition.offset;
  final end = b.startPosition.offset;
  if (start < 0 || end > source.length || start >= end) return false;
  final gap = source.substring(start, end);
  // A blank line means two newlines with only whitespace between them
  return RegExp(r'\n[ \t]*\n').hasMatch(gap);
}
```

Update `_needsSpacingBetween` directive section (around lines 1797-1819):

Replace:
```dart
// Handle directive spacing based on configuration
if (current is DirectiveNode && next is DirectiveNode) {
  // Never add blank lines before intermediate directives (@else, @elseif,
  // @case, @default, @empty inside @forelse) — they are branches of the same parent block.
  if (_isIntermediateDirective(next)) {
    return false;
  }

  // Check if we should add spacing between block directives
  if (config.directiveSpacing == DirectiveSpacing.betweenBlocks) {
    // Add blank line between two block-level directives
    // Current directive has just finished (including its @end tag if it has one)
    // Next directive is about to start
    final isCurrentBlock = _blockDirectives.contains(current.name);
    final isNextBlock = _blockDirectives.contains(next.name) ||
        _inlineDirectives.contains(next.name);

    if (isCurrentBlock && isNextBlock) {
      return true;
    }
  }
  // For DirectiveSpacing.none or preserve, don't add spacing
  return false;
}
```

With:
```dart
// Handle directive spacing based on configuration
if (current is DirectiveNode && next is DirectiveNode) {
  // Never add blank lines before intermediate directives (@else, @elseif,
  // @case, @default, @empty inside @forelse) — they are branches of the same parent block.
  if (_isIntermediateDirective(next)) {
    return false;
  }

  switch (config.directiveSpacing) {
    case DirectiveSpacing.betweenBlocks:
      // Add blank line between two block-level directives
      final isCurrentBlock = _blockDirectives.contains(current.name);
      final isNextBlock = _blockDirectives.contains(next.name) ||
          _inlineDirectives.contains(next.name);
      if (isCurrentBlock && isNextBlock) {
        return true;
      }
      return false;
    case DirectiveSpacing.none:
      return false;
    case DirectiveSpacing.preserve:
      return _sourceHasBlankLineBetween(current, next);
  }
}
```

**Step 4: Run tests and verify**

Run: `dart test test/formatter/formatter_test.dart --name "DirectiveSpacing"`
Expected: All directive spacing tests pass (existing + new).

Run: `dart test`
Expected: Full suite passes.

**Step 5: Commit**

```bash
git add lib/src/formatter/formatter_visitor.dart test/formatter/formatter_test.dart
git commit -m "fix: DirectiveSpacing.preserve now correctly preserves source blank lines"
```

---

## Task 3: Fix `QuoteStyle.preserve` (can't preserve — defaults to double)

**Files:**
- Modify: `lib/src/ast/node.dart` (add `quoteChar` to `AttributeNode`)
- Modify: `lib/src/parser/parser.dart` (store source, infer quote from token offset)
- Modify: `lib/src/formatter/formatter_visitor.dart` (use `quoteChar` when preserve)
- Modify: `test/formatter/formatter_test.dart` (new tests)
- Modify: `test/formatter/formatter_config_test.dart` (if needed)

### Analysis

The lexer strips quotes in `_lexAttributeValue()` — the `attributeValue` token contains only the inner value. The quote char is at `source[valueToken.startOffset - 1]`. The parser can recover this since it has access to `source` in `parse()`.

**Step 1: Write failing tests**

In `test/formatter/formatter_test.dart`, add a new group:

```dart
group('QuoteStyle.preserve', () {
  test('preserves single quotes on attributes', () {
    final formatter = BladeFormatter(
      config: const FormatterConfig(quoteStyle: QuoteStyle.preserve),
    );
    const input = "<div class='foo'></div>";
    final result = formatter.format(input);
    expect(result, contains("class='foo'"));
  });

  test('preserves double quotes on attributes', () {
    final formatter = BladeFormatter(
      config: const FormatterConfig(quoteStyle: QuoteStyle.preserve),
    );
    const input = '<div class="foo"></div>';
    final result = formatter.format(input);
    expect(result, contains('class="foo"'));
  });

  test('preserves mixed quotes on different attributes', () {
    final formatter = BladeFormatter(
      config: const FormatterConfig(quoteStyle: QuoteStyle.preserve),
    );
    const input = "<div class='foo' id=\"bar\"></div>";
    final result = formatter.format(input);
    expect(result, contains("class='foo'"));
    expect(result, contains('id="bar"'));
  });

  test('defaults to double quotes for boolean attributes with preserve', () {
    final formatter = BladeFormatter(
      config: const FormatterConfig(quoteStyle: QuoteStyle.preserve),
    );
    const input = '<input disabled>';
    final result = formatter.format(input);
    // Boolean attrs have no value/quotes — should just be 'disabled'
    expect(result.trim(), '<input disabled>');
  });
});
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/formatter/formatter_test.dart --name "QuoteStyle.preserve"`
Expected: FAIL — "preserves single quotes" test fails because preserve currently uses double quotes.

**Step 3: Add `quoteChar` field to `AttributeNode`**

In `lib/src/ast/node.dart`, update `AttributeNode`:

```dart
sealed class AttributeNode {
  final String name;
  final String? value;
  
  /// The original quote character used in source (' or "), or null for
  /// boolean/unquoted attributes.
  final String? quoteChar;
  
  final Position startPosition;
  final Position endPosition;

  AttributeNode({
    required this.name,
    this.value,
    this.quoteChar,
    required this.startPosition,
    required this.endPosition,
  });
  
  Map<String, dynamic> toJson();
}
```

Update all three subclass constructors (`StandardAttribute`, `AlpineAttribute`, `LivewireAttribute`) to pass through `super.quoteChar`:

```dart
// In StandardAttribute:
StandardAttribute({
  required super.name,
  super.value,
  super.quoteChar,
  required super.startPosition,
  required super.endPosition,
});

// Same pattern for AlpineAttribute and LivewireAttribute
```

**Step 4: Store source in parser, recover quote char**

In `lib/src/parser/parser.dart`:

Add a field to store source:
```dart
String _source = '';
```

In `parse()` method, store it:
```dart
ParseResult parse(String source) {
  _source = source;
  final lexer = BladeLexer(source);
  ...
```

Add helper to infer quote char:
```dart
/// Recovers the quote character used for an attribute value token.
///
/// The lexer strips quotes from attribute values, but the original
/// quote char is at `source[token.startOffset - 1]`.
String? _inferQuoteChar(Token valueToken) {
  final i = valueToken.startOffset - 1;
  if (i < 0 || i >= _source.length) return null;
  final ch = _source[i];
  return (ch == '"' || ch == "'") ? ch : null;
}
```

In `_parseTagHead()`, around line 1400-1404 where `attributeValue` tokens are consumed, recover the quote:

```dart
} else if (_check(TokenType.attributeValue)) {
  final valueToken = _advance();
  attrValue = valueToken.value;
  attrEndPos = valueToken.endPosition;
  quoteChar = _inferQuoteChar(valueToken);
}
```

Declare `String? quoteChar;` alongside `String? attrValue;` and pass it to `_classifyAttribute`.

Update `_classifyAttribute` signature to accept `String? quoteChar` and pass it through to all `AttributeNode` constructors.

**Step 5: Use `quoteChar` in formatter**

In `lib/src/formatter/formatter_visitor.dart`, update `_formatAttribute` to pass through quote info, and update `_formatAttributeValue` to accept it:

The challenge: `_formatAttribute` receives an `AttributeNode` which now has `quoteChar`. Update `_formatAttributeValue`:

```dart
String _formatAttributeValue(String value, {String? sourceQuoteChar}) {
  String quote;
  if (config.quoteStyle == QuoteStyle.preserve) {
    quote = sourceQuoteChar ?? '"';
  } else {
    quote = config.quoteStyle.quoteChar;
  }

  // ... rest of the method using `quote` variable (already does this)
  // Update the escaping branch to check preserve properly:
  // For plain HTML attribute values: escape quotes normally
  String escaped = value;
  if (quote == "'") {
    escaped = value.replaceAll(r"\'", "'").replaceAll("'", r"\'");
  } else {
    escaped = value.replaceAll(r'\"', '"').replaceAll('"', r'\"');
  }
  return '$quote$escaped$quote';
}
```

Update `_formatAttribute` to pass `sourceQuoteChar`:
```dart
String _formatAttribute(AttributeNode attr) {
  if (attr.value == null) {
    return attr.name;
  }
  if (attr.name.startsWith('@') && _isBladeAttributeDirectiveName(attr.name)) {
    return '${attr.name}${attr.value}';
  }
  return '${attr.name}=${_formatAttributeValue(attr.value!, sourceQuoteChar: attr.quoteChar)}';
}
```

**Step 6: Run tests and verify**

Run: `dart test test/formatter/formatter_test.dart --name "QuoteStyle"`
Expected: All pass.

Run: `dart test`
Expected: Full suite passes. Check for any AST JSON snapshot tests that might need `quoteChar` added.

**Step 7: Commit**

```bash
git add lib/src/ast/node.dart lib/src/parser/parser.dart lib/src/formatter/formatter_visitor.dart test/formatter/formatter_test.dart
git commit -m "fix: QuoteStyle.preserve now preserves original quote characters"
```

---

## Task 4: Add `EchoSpacing` config (spaced/compact/preserve)

**Files:**
- Modify: `lib/src/formatter/formatter_config.dart` (add enum + field)
- Modify: `lib/src/ast/node.dart` (add `rawExpression` to `EchoNode`)
- Modify: `lib/src/parser/parser.dart` (store raw expression)
- Modify: `lib/src/formatter/formatter_visitor.dart` (centralize echo rendering, use config)
- Create: `test/formatter/formatter_echo_spacing_test.dart`
- Modify: `test/formatter/formatter_config_test.dart`

### Analysis

Echo rendering currently happens in 4 places in the visitor:
1. `visitEcho` in raw text context (lines 768-773)
2. `visitEcho` normal (lines 782-786)
3. Raw text element reconstruction in `visitHtmlElement` (lines 1007-1010)
4. `_renderInlineNode` (lines 1712-1715)

All should be unified into a single `_renderEcho(EchoNode node)` helper.

The parser trims expressions at line 768 of parser.dart (`expression.trim()`). We need to also store the raw (untrimmed) expression for preserve mode.

**Step 1: Add `EchoSpacing` enum to config**

In `lib/src/formatter/formatter_config.dart`, add after `SelfClosingStyle`:

```dart
/// Controls spacing inside echo braces {{ }} and {!! !!}.
enum EchoSpacing {
  /// Always add spaces inside braces: `{{ $var }}`, `{!! $expr !!}`
  spaced('spaced'),

  /// No spaces inside braces: `{{$var}}`, `{!!$expr!!}`
  compact('compact'),

  /// Preserve the original spacing from the source.
  preserve('preserve');

  final String value;
  const EchoSpacing(this.value);

  static EchoSpacing fromString(String? s) => switch (s) {
        'compact' => compact,
        'preserve' => preserve,
        _ => spaced,
      };
}
```

Add field to `FormatterConfig`:
```dart
final EchoSpacing echoSpacing;
```

Add to constructor default: `this.echoSpacing = EchoSpacing.spaced,`

Add to fromMap: `echoSpacing: EchoSpacing.fromString(map['echo_spacing'] as String?),`

Add to toMap: `'echo_spacing': echoSpacing.value,`

Add to toString: `'echoSpacing: $echoSpacing, '`

**Step 2: Add `rawExpression` to `EchoNode`**

In `lib/src/ast/node.dart`, update `EchoNode`:

```dart
final class EchoNode extends AstNode {
  // ... existing fields ...
  
  /// The PHP expression to be echoed (trimmed).
  final String expression;
  
  /// The raw expression as it appeared in source (untrimmed, preserves spacing).
  final String rawExpression;

  /// Whether this is a raw (unescaped) echo.
  final bool isRaw;

  EchoNode({
    required this.startPosition,
    required this.endPosition,
    required this.expression,
    String? rawExpression,
    required this.isRaw,
  }) : rawExpression = rawExpression ?? expression;
  
  // ... toJson can optionally include rawExpression ...
}
```

**Step 3: Store raw expression in parser**

In `lib/src/parser/parser.dart`, update `_parseEchoVariant` (around line 742):

```dart
EchoNode _parseEchoVariant({
  required TokenType closeType,
  required String label,
  required bool isRaw,
}) {
  final openToken = _advance();

  String expression = '';
  if (_check(TokenType.expression)) {
    expression = _advance().value;
  }

  if (!_check(closeType)) {
    _errors.add(
      ParseError(
        message: 'Unclosed $label',
        position: openToken.startPosition,
      ),
    );
  } else {
    _advance();
  }

  return EchoNode(
    startPosition: openToken.startPosition,
    endPosition: _previous().endPosition,
    expression: expression.trim(),
    rawExpression: expression,
    isRaw: isRaw,
  );
}
```

**Step 4: Write failing tests**

Create `test/formatter/formatter_echo_spacing_test.dart`:

```dart
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('EchoSpacing config', () {
    group('EchoSpacing.spaced (default)', () {
      final formatter = BladeFormatter();

      test('adds spaces inside echo braces', () {
        final result = formatter.format('{{\$var}}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('normalizes existing spacing', () {
        final result = formatter.format('{{  \$var  }}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('adds spaces inside raw echo braces', () {
        final result = formatter.format('{!!\$var!!}');
        expect(result.trim(), '{!! \$var !!}');
      });
    });

    group('EchoSpacing.compact', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(echoSpacing: EchoSpacing.compact),
      );

      test('removes spaces inside echo braces', () {
        final result = formatter.format('{{ \$var }}');
        expect(result.trim(), '{{\$var}}');
      });

      test('removes spaces inside raw echo braces', () {
        final result = formatter.format('{!! \$var !!}');
        expect(result.trim(), '{!!\$var!!}');
      });

      test('works inline in HTML elements', () {
        final result = formatter.format('<p>{{ \$name }}</p>');
        expect(result.trim(), '<p>{{\$name}}</p>');
      });
    });

    group('EchoSpacing.preserve', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(echoSpacing: EchoSpacing.preserve),
      );

      test('preserves spaces when present', () {
        final result = formatter.format('{{ \$var }}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('preserves no spaces when absent', () {
        final result = formatter.format('{{\$var}}');
        expect(result.trim(), '{{\$var}}');
      });

      test('preserves asymmetric spacing', () {
        final result = formatter.format('{{ \$var}}');
        expect(result.trim(), '{{ \$var}}');
      });

      test('preserves raw echo spacing', () {
        final result = formatter.format('{!!\$var!!}');
        expect(result.trim(), '{!!\$var!!}');
      });
    });
  });
}
```

**Step 5: Run tests to verify they fail**

Run: `dart test test/formatter/formatter_echo_spacing_test.dart`
Expected: FAIL — compact and preserve tests fail.

**Step 6: Centralize echo rendering in visitor**

In `lib/src/formatter/formatter_visitor.dart`, add a helper method:

```dart
/// Renders an echo node's delimiters and expression according to echoSpacing config.
String _renderEchoString(EchoNode node) {
  final String inner;
  switch (config.echoSpacing) {
    case EchoSpacing.spaced:
      inner = ' ${node.expression} ';
    case EchoSpacing.compact:
      inner = node.expression;
    case EchoSpacing.preserve:
      inner = node.rawExpression;
  }
  return node.isRaw ? '{!!$inner!!}' : '{{$inner}}';
}
```

Replace all 4 echo rendering sites to use `_renderEchoString`:

**Site 1** — `visitEcho` raw text context (lines ~768-773):
```dart
_output.write(_renderEchoString(node));
```

**Site 2** — `visitEcho` normal (lines ~782-786):
```dart
_output.write(_renderEchoString(node));
```

**Site 3** — raw text reconstruction in `visitHtmlElement` (lines ~1003-1014):
```dart
} else if (child is EchoNode) {
  rawContent.write(_renderEchoString(child));
}
```

**Site 4** — `_renderInlineNode` (lines ~1712-1715):
```dart
if (node is EchoNode) {
  return _renderEchoString(node);
}
```

**Step 7: Run tests and verify**

Run: `dart test test/formatter/formatter_echo_spacing_test.dart`
Expected: All pass.

Run: `dart test`
Expected: Full suite passes. Watch for tests that assert specific echo formatting (e.g., `{{ $var }}`) — those use default config (spaced) and should still pass.

**Step 8: Commit**

```bash
git add lib/src/formatter/formatter_config.dart lib/src/ast/node.dart lib/src/parser/parser.dart lib/src/formatter/formatter_visitor.dart test/formatter/formatter_echo_spacing_test.dart test/formatter/formatter_config_test.dart
git commit -m "feat: add EchoSpacing config (spaced/compact/preserve)"
```

---

## Task 5: Add `HtmlBlockSpacing` config (betweenBlocks/none/preserve)

**Files:**
- Modify: `lib/src/formatter/formatter_config.dart` (add enum + field)
- Modify: `lib/src/formatter/formatter_visitor.dart` (use config in `_needsSpacingBetween`)
- Create: `test/formatter/formatter_html_block_spacing_test.dart`
- Modify: `test/formatter/formatter_config_test.dart`

### Analysis

Currently `_needsSpacingBetween` hardcodes blank lines between block-level HTML siblings (lines 1787-1789). The behavior IS already sibling-only (called within child iteration loops), so no separate "siblingOnly" option is needed.

**Step 1: Add `HtmlBlockSpacing` enum to config**

In `lib/src/formatter/formatter_config.dart`, add:

```dart
/// Controls blank lines between block-level HTML element siblings.
enum HtmlBlockSpacing {
  /// Add blank line between block-level HTML siblings (e.g., consecutive divs).
  betweenBlocks('between_blocks'),

  /// No blank lines between HTML block elements.
  none('none'),

  /// Preserve blank lines as written in the source.
  preserve('preserve');

  final String value;
  const HtmlBlockSpacing(this.value);

  static HtmlBlockSpacing fromString(String? s) => switch (s) {
        'none' => none,
        'preserve' => preserve,
        _ => betweenBlocks,
      };
}
```

Add field: `final HtmlBlockSpacing htmlBlockSpacing;`
Constructor default: `this.htmlBlockSpacing = HtmlBlockSpacing.betweenBlocks,`
fromMap: `htmlBlockSpacing: HtmlBlockSpacing.fromString(map['html_block_spacing'] as String?),`
toMap: `'html_block_spacing': htmlBlockSpacing.value,`
toString: `'htmlBlockSpacing: $htmlBlockSpacing, '`

**Step 2: Write failing tests**

Create `test/formatter/formatter_html_block_spacing_test.dart`:

```dart
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlBlockSpacing config', () {
    group('HtmlBlockSpacing.betweenBlocks (default)', () {
      final formatter = BladeFormatter();

      test('adds blank line between block-level siblings', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, contains('<div>A</div>\n\n<div>B</div>'));
      });
    });

    group('HtmlBlockSpacing.none', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          htmlBlockSpacing: HtmlBlockSpacing.none,
        ),
      );

      test('no blank line between block-level siblings', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, '<div>A</div>\n<div>B</div>\n');
      });
    });

    group('HtmlBlockSpacing.preserve', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          htmlBlockSpacing: HtmlBlockSpacing.preserve,
        ),
      );

      test('preserves blank line when present in source', () {
        const input = '<div>A</div>\n\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, contains('<div>A</div>\n\n<div>B</div>'));
      });

      test('does not insert blank line when absent from source', () {
        const input = '<div>A</div>\n<div>B</div>';
        final result = formatter.format(input);
        expect(result, '<div>A</div>\n<div>B</div>\n');
      });
    });
  });
}
```

**Step 3: Run tests to verify they fail**

Run: `dart test test/formatter/formatter_html_block_spacing_test.dart`
Expected: FAIL — `none` and `preserve` tests fail.

**Step 4: Implement**

In `lib/src/formatter/formatter_visitor.dart`, update `_needsSpacingBetween` (around lines 1786-1790):

Replace:
```dart
// Add spacing between block-level HTML elements
if (current is HtmlElementNode && next is HtmlElementNode) {
  return _blockElements.contains(current.tagName.toLowerCase()) &&
      _blockElements.contains(next.tagName.toLowerCase());
}
```

With:
```dart
// Add spacing between block-level HTML elements
if (current is HtmlElementNode && next is HtmlElementNode) {
  final bothBlock = _blockElements.contains(current.tagName.toLowerCase()) &&
      _blockElements.contains(next.tagName.toLowerCase());
  if (!bothBlock) return false;

  switch (config.htmlBlockSpacing) {
    case HtmlBlockSpacing.betweenBlocks:
      return true;
    case HtmlBlockSpacing.none:
      return false;
    case HtmlBlockSpacing.preserve:
      return _sourceHasBlankLineBetween(current, next);
  }
}
```

Note: `_sourceHasBlankLineBetween` was added in Task 2. If implementing this before Task 2, add the helper here.

**Step 5: Run tests and verify**

Run: `dart test test/formatter/formatter_html_block_spacing_test.dart`
Expected: All pass.

Run: `dart test`
Expected: Full suite passes. Some existing tests may assume `betweenBlocks` behavior — they use default config and should still work.

**Step 6: Commit**

```bash
git add lib/src/formatter/formatter_config.dart lib/src/formatter/formatter_visitor.dart test/formatter/formatter_html_block_spacing_test.dart test/formatter/formatter_config_test.dart
git commit -m "feat: add HtmlBlockSpacing config (betweenBlocks/none/preserve)"
```

---

## Task 6: Add `trailingNewline` config (bool, default: true)

**Files:**
- Modify: `lib/src/formatter/formatter_config.dart` (add field)
- Modify: `lib/src/formatter/formatter_visitor.dart` (conditional trailing newline)
- Create: `test/formatter/formatter_trailing_newline_test.dart`
- Modify: `test/formatter/formatter_config_test.dart`

**Step 1: Add field to config**

In `lib/src/formatter/formatter_config.dart`:

Add field: `final bool trailingNewline;`
Constructor default: `this.trailingNewline = true,`
fromMap: `trailingNewline: map['trailing_newline'] as bool? ?? true,`
toMap: `'trailing_newline': trailingNewline,`
toString: `'trailingNewline: $trailingNewline, '`

**Step 2: Write failing test**

Create `test/formatter/formatter_trailing_newline_test.dart`:

```dart
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('trailingNewline config', () {
    test('default adds trailing newline', () {
      final formatter = BladeFormatter();
      final result = formatter.format('<div></div>');
      expect(result, endsWith('\n'));
    });

    test('trailingNewline: false omits trailing newline', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: false),
      );
      final result = formatter.format('<div></div>');
      expect(result, isNot(endsWith('\n')));
      expect(result, equals('<div></div>'));
    });

    test('trailingNewline: false with multiple elements', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: false),
      );
      final result = formatter.format('<div></div>\n<p>Hello</p>');
      expect(result, isNot(endsWith('\n')));
    });

    test('trailingNewline: true explicitly adds trailing newline', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: true),
      );
      final result = formatter.format('<div></div>');
      expect(result, endsWith('\n'));
      expect(result, isNot(endsWith('\n\n')));
    });
  });
}
```

**Step 3: Run tests to verify they fail**

Run: `dart test test/formatter/formatter_trailing_newline_test.dart`
Expected: FAIL — "trailingNewline: false" test fails because formatter always adds newline.

**Step 4: Implement**

In `lib/src/formatter/formatter_visitor.dart`, update `visitDocument` (around lines 663-673):

Replace:
```dart
// Ensure file ends with newline
final isEmpty = _output.toString().isEmpty;
if (isEmpty) {
  // If document had children (even if just whitespace), add newline
  // If document was truly empty, keep output empty
  if (node.children.isNotEmpty) {
    _output.writeln();
  }
} else if (!_output.endsWithNewline()) {
  _output.writeln();
}
```

With:
```dart
if (config.trailingNewline) {
  // Ensure file ends with newline
  final isEmpty = _output.toString().isEmpty;
  if (isEmpty) {
    if (node.children.isNotEmpty) {
      _output.writeln();
    }
  } else if (!_output.endsWithNewline()) {
    _output.writeln();
  }
} else {
  // Strip trailing newline if present
  final str = _output.toString();
  if (str.endsWith('\n')) {
    _output.clear();
    _output.write(str.substring(0, str.length - 1));
  }
}
```

Note: The "strip trailing newline" approach is needed because individual node visitors (e.g., `visitHtmlElement`) add trailing newlines after each element. When `trailingNewline: false`, we need to remove the final one. The cleanest way is to strip it at the end of `visitDocument`.

**Step 5: Run tests and verify**

Run: `dart test test/formatter/formatter_trailing_newline_test.dart`
Expected: All pass.

Run: `dart test`
Expected: Full suite passes (all existing tests use default `trailingNewline: true`).

**Step 6: Commit**

```bash
git add lib/src/formatter/formatter_config.dart lib/src/formatter/formatter_visitor.dart test/formatter/formatter_trailing_newline_test.dart test/formatter/formatter_config_test.dart
git commit -m "feat: add trailingNewline config option (default: true)"
```

---

## Implementation Order

Execute tasks in this order (each is independent after completion):

1. **Task 1** — Remove `formatPhpExpressions` (simplest, pure deletion)
2. **Task 6** — Add `trailingNewline` (simple bool, low risk)
3. **Task 2** — Fix `DirectiveSpacing.preserve` (adds `_sourceHasBlankLineBetween` helper reused by Tasks 5)
4. **Task 5** — Add `HtmlBlockSpacing` (uses helper from Task 2)
5. **Task 3** — Fix `QuoteStyle.preserve` (touches AST + parser, moderate complexity)
6. **Task 4** — Add `EchoSpacing` (touches AST + parser + 4 rendering sites, highest complexity)

## Post-Implementation Checklist

After all tasks:
- [ ] Run full test suite: `dart test`
- [ ] Run idempotency stress tests: `dart test test/formatter/formatter_idempotency_stress_test.dart`
- [ ] Update README.md configuration docs to add new options and remove `formatPhpExpressions`
- [ ] Update `.blade.json` if it serves as an example config
- [ ] Update `bin/blade.dart` CLI help text to document new config keys
- [ ] Run `dart format` on all changed files
