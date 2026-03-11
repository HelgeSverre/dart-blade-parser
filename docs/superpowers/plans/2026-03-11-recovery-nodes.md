# Recovery Nodes Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace implicit error recovery (side-channel errors + discarded tokens) with explicit `RecoveryNode` AST nodes at three recovery sites: stray HTML closers, skipped regions, and unclosed directive boundaries.

**Architecture:** Add `RecoveryNode` to the sealed `AstNode` hierarchy with a `visitRecovery` method on `AstVisitor`. The parser inserts `RecoveryNode` instances at each recovery point instead of silently consuming tokens. The formatter outputs recovery nodes verbatim, preserving source fidelity.

**Tech Stack:** Dart, TDD with `package:test`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/src/ast/node.dart` | Modify | Add `RecoveryNode` class |
| `lib/src/ast/visitor.dart` | Modify | Add `visitRecovery` to `RecursiveAstVisitor` |
| `lib/src/parser/parser.dart` | Modify | Insert `RecoveryNode` at 3 recovery sites |
| `lib/src/formatter/formatter_visitor.dart` | Modify | Add `visitRecovery` — verbatim output |
| `test/unit/ast/recovery_node_test.dart` | Create | Unit tests for `RecoveryNode` |
| `test/unit/parser/recovery_node_parser_test.dart` | Create | Parser creates recovery nodes at all 3 sites |
| `test/unit/formatter/recovery_node_formatter_test.dart` | Create | Formatter outputs recovery nodes verbatim |

---

## Chunk 1: RecoveryNode AST Infrastructure

### Task 1: Add `RecoveryNode` to AST and visitor

**Files:**
- Modify: `lib/src/ast/node.dart` (after `ErrorNode` at line ~792)
- Modify: `lib/src/ast/node.dart` (add `visitRecovery` to `AstVisitor` at line ~82)
- Modify: `lib/src/ast/visitor.dart` (add `visitRecovery` to `RecursiveAstVisitor`)
- Create: `test/unit/ast/recovery_node_test.dart`

- [ ] **Step 1: Write failing tests for `RecoveryNode`**

```dart
// test/unit/ast/recovery_node_test.dart
import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/lexer/position.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryNode', () {
    test('stores content, reason, and positions', () {
      final node = RecoveryNode(
        content: '</bogus>',
        reason: 'stray closing tag',
        startPosition: Position(offset: 0, line: 1, column: 0),
        endPosition: Position(offset: 8, line: 1, column: 8),
      );

      expect(node.content, '</bogus>');
      expect(node.reason, 'stray closing tag');
      expect(node.children, isEmpty);
    });

    test('accepts visitor via visitRecovery', () {
      final node = RecoveryNode(
        content: '???',
        reason: 'skipped region',
        startPosition: Position(offset: 0, line: 1, column: 0),
        endPosition: Position(offset: 3, line: 1, column: 3),
      );

      final visited = node.accept(_TestVisitor());
      expect(visited, 'recovery:???');
    });

    test('serializes to JSON', () {
      final node = RecoveryNode(
        content: '</bogus>',
        reason: 'stray closing tag',
        startPosition: Position(offset: 5, line: 1, column: 5),
        endPosition: Position(offset: 13, line: 1, column: 13),
      );

      final json = node.toJson();
      expect(json['type'], 'recovery');
      expect(json['content'], '</bogus>');
      expect(json['reason'], 'stray closing tag');
    });
  });
}

class _TestVisitor implements AstVisitor<String> {
  @override String visitDocument(DocumentNode n) => '';
  @override String visitDirective(DirectiveNode n) => '';
  @override String visitComponent(ComponentNode n) => '';
  @override String visitEcho(EchoNode n) => '';
  @override String visitText(TextNode n) => '';
  @override String visitHtmlElement(HtmlElementNode n) => '';
  @override String visitComment(CommentNode n) => '';
  @override String visitError(ErrorNode n) => '';
  @override String visitSlot(SlotNode n) => '';
  @override String visitPhpBlock(PhpBlockNode n) => '';
  @override String visitRecovery(RecoveryNode n) => 'recovery:${n.content}';
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/unit/ast/recovery_node_test.dart`
Expected: Compilation errors — `RecoveryNode` and `visitRecovery` don't exist yet.

- [ ] **Step 3: Add `visitRecovery` to `AstVisitor`**

In `lib/src/ast/node.dart`, add after `visitPhpBlock` (line ~82):

```dart
  /// Visit a recovery node (preserved source from error recovery).
  T visitRecovery(RecoveryNode node);
```

- [ ] **Step 4: Add `RecoveryNode` class**

In `lib/src/ast/node.dart`, add after `ErrorNode` (line ~792):

```dart
/// Preserved source span from a parser recovery point.
///
/// Unlike [ErrorNode], which marks a parsing error location,
/// [RecoveryNode] captures the actual source text that was consumed
/// during recovery. The formatter outputs this content verbatim.
final class RecoveryNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The verbatim source content consumed during recovery.
  final String content;

  /// Human-readable reason describing what recovery occurred.
  final String reason;

  RecoveryNode({
    required this.content,
    required this.reason,
    required this.startPosition,
    required this.endPosition,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitRecovery(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'recovery',
        'content': content,
        'reason': reason,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}
```

- [ ] **Step 5: Add `visitRecovery` to `RecursiveAstVisitor`**

In `lib/src/ast/visitor.dart`, add after `visitPhpBlock` (line ~92):

```dart
  @override
  T visitRecovery(RecoveryNode node) {
    // Recovery nodes are leaf nodes (preserved source text)
    return defaultValue;
  }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `dart test test/unit/ast/recovery_node_test.dart`
Expected: All 3 tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/src/ast/node.dart lib/src/ast/visitor.dart test/unit/ast/recovery_node_test.dart
git commit -m "feat: add RecoveryNode to AST for explicit recovery spans"
```

---

### Task 2: Add `visitRecovery` to `FormatterVisitor`

**Files:**
- Modify: `lib/src/formatter/formatter_visitor.dart` (add `visitRecovery`)
- Create: `test/unit/formatter/recovery_node_formatter_test.dart`

- [ ] **Step 1: Write failing test for formatter recovery output**

```dart
// test/unit/formatter/recovery_node_formatter_test.dart
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter RecoveryNode output', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('stray closer inside element is preserved as recovery node', () {
      // Parser should insert RecoveryNode for </bogus>, formatter outputs verbatim
      const input = '<div><span>Text</bogus>More</span></div>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('Text'));
      expect(result.formatted, contains('More'));
    });

    test('unclosed directive at EOF preserves content and reports error', () {
      const input = '@if(\$x)\n    <p>Hello</p>';
      final result = formatter.formatWithResult(input);

      expect(result.hasErrors, isTrue);
      expect(result.formatted, contains('@if'));
      expect(result.formatted, contains('<p>Hello</p>'));
    });

    test('recovery node content round-trips verbatim', () {
      // Malformed input with stray closer — format twice, same output
      const input = '<div>Text</bogus>More</div>';
      final pass1 = formatter.format(input);
      final pass2 = formatter.format(pass1);

      expect(pass2, equals(pass1), reason: 'recovery output must be idempotent');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/unit/formatter/recovery_node_formatter_test.dart`
Expected: Compilation error — `visitRecovery` not implemented in `FormatterVisitor`.

- [ ] **Step 3: Add `visitRecovery` to `FormatterVisitor`**

In `lib/src/formatter/formatter_visitor.dart`, add after `visitError` (line ~1699):

```dart
  @override
  String visitRecovery(RecoveryNode node) {
    _output.write(node.content);
    return '';
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test test/unit/formatter/recovery_node_formatter_test.dart`
Expected: All 3 tests pass (the parser doesn't emit `RecoveryNode` yet, so these tests exercise the existing behavior which should still work; the formatter test for verbatim output will be fully exercised once the parser emits `RecoveryNode` in later tasks).

- [ ] **Step 5: Run full test suite to check nothing broke**

Run: `dart test`
Expected: All existing tests pass — adding `visitRecovery` is additive.

- [ ] **Step 6: Commit**

```bash
git add lib/src/formatter/formatter_visitor.dart test/unit/formatter/recovery_node_formatter_test.dart
git commit -m "feat: add visitRecovery to FormatterVisitor for verbatim output"
```

---

## Chunk 2: Parser Recovery Sites

### Task 3: Stray HTML closer → `RecoveryNode`

When `</bogus>` appears inside `<span>` and doesn't match any ancestor, the parser currently calls `_consumeClosingTag()` and discards the tokens. Instead, insert a `RecoveryNode` as a child of the current element.

**Files:**
- Modify: `lib/src/parser/parser.dart` (line ~1770, stray closer branch)
- Create: `test/unit/parser/recovery_node_parser_test.dart`

- [ ] **Step 1: Write failing test for stray closer recovery node**

```dart
// test/unit/parser/recovery_node_parser_test.dart
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/node.dart';
import 'package:test/test.dart';

void main() {
  group('Parser RecoveryNode emission', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('stray HTML closers', () {
      test('stray closer becomes RecoveryNode child', () {
        final result = parser.parse('<div><span>Text</bogus>More</span></div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final span = div.children[0] as HtmlElementNode;

        final recoveryNodes = span.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
        expect(recoveryNodes.first.reason, contains('stray'));
      });

      test('top-level stray closer becomes RecoveryNode', () {
        final result = parser.parse('Hello</bogus>World');

        expect(result.isSuccess, isFalse);
        final recoveryNodes = result.ast!.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
      });

      test('multiple stray closers each get their own RecoveryNode', () {
        final result =
            parser.parse('<div>A</foo>B</bar>C</div>');

        final div = result.ast!.children[0] as HtmlElementNode;
        final recoveryNodes = div.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(2));
      });
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart`
Expected: FAIL — stray closers are consumed but no `RecoveryNode` is created.

- [ ] **Step 3: Modify parser to emit `RecoveryNode` for stray closers inside elements**

In `lib/src/parser/parser.dart`, around line 1770 (the stray closer branch inside `_parseHtmlElement` children loop), change from:

```dart
        _error(
          'Unexpected closing tag </$closingTagName> inside <$tagName>',
          closingStartPos,
        );
        _consumeClosingTag();
        continue;
```

To:

```dart
        _error(
          'Unexpected closing tag </$closingTagName> inside <$tagName>',
          closingStartPos,
        );
        final consumed = _consumeClosingTag();
        if (consumed != null) {
          children.add(RecoveryNode(
            content: '</${consumed.name}>',
            reason: 'stray closing tag </${consumed.name}>',
            startPosition: closingStartPos,
            endPosition: consumed.endPosition,
          ));
        }
        continue;
```

- [ ] **Step 4: Modify parser to emit `RecoveryNode` for top-level stray closers**

In `_parseHtmlElement()`, around line 1622 (the closing-tag-at-top-level branch), change the branch that handles non-void stray closers. Currently it calls `_error()` and returns `null`. Change it to return a `RecoveryNode` instead:

Replace (lines ~1634-1638):

```dart
        } else {
          _error(
            'Unexpected closing tag </$closingTagName>',
            closingStartPos,
          );
        }
      } else if (consumedClosingTag == null) {
        _error('Expected tag name after </', closingStartPos);
      }

      return null; // Closing tags handled by parent
```

With a version that reconstructs the consumed source and returns a `RecoveryNode`. Note: `_parseHtmlElement` returns `HtmlElementNode?`, so we cannot directly return a `RecoveryNode` from it. Instead, the caller (`_parseNode`) must handle this. The simplest approach: create a new helper method `_parseStrayClosingTag()` that returns an `AstNode?` (a `RecoveryNode`), and call it from `_parseNode` before `_parseHtmlElement`.

Alternative (simpler): Since the top-level stray closer handling is in `_parseHtmlElement` which returns `HtmlElementNode?`, and the calling code in `_parseNode` treats `null` returns as "skip", we need to handle this at the `_parseNode` level instead.

In `_parseNode()`, add a check before the HTML element branch. Find the line where `_parseNode` checks for `TokenType.htmlClosingTagStart` or delegates to `_parseHtmlElement`. Add:

```dart
    // Stray closing tag at top level → RecoveryNode
    if (_check(TokenType.htmlClosingTagStart)) {
      final closingStartPos = _peek().startPosition;
      final closingTagName = _peekClosingTagName();
      final consumed = _consumeClosingTag();

      final name = closingTagName ?? '';
      final reason = closingTagName != null
          ? 'stray closing tag </$closingTagName>'
          : 'malformed closing tag';
      _error('Unexpected closing tag </$name>', closingStartPos);

      return RecoveryNode(
        content: consumed != null ? '</${consumed.name}>' : '</',
        reason: reason,
        startPosition: closingStartPos,
        endPosition: consumed?.endPosition ?? _previous().endPosition,
      );
    }
```

And remove the stray-closer handling from `_parseHtmlElement()` (lines 1622-1644) since `_parseNode` now handles it before calling `_parseHtmlElement`. Keep only the opening-tag logic.

**Important:** Read `_parseNode()` carefully before editing to find the exact insertion point. The `htmlClosingTagStart` check must come before the `htmlTagOpen` check that delegates to `_parseHtmlElement`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart`
Expected: All 3 stray-closer tests pass.

- [ ] **Step 6: Run full test suite**

Run: `dart test`
Expected: All tests pass. Some existing tests may need updated assertions if they checked for `null` returns from stray closers — update those to check for `RecoveryNode` instead.

- [ ] **Step 7: Commit**

```bash
git add lib/src/parser/parser.dart test/unit/parser/recovery_node_parser_test.dart
git commit -m "feat: emit RecoveryNode for stray HTML closing tags"
```

---

### Task 4: Skipped tokens in HTML children → `RecoveryNode`

When the parser's children loop calls `_parseNode()` and gets `null`, the token was consumed but nothing was added to the tree. This loses content. Wrap these in `RecoveryNode`.

**Files:**
- Modify: `lib/src/parser/parser.dart` (children loop, line ~1778)
- Modify: `test/unit/parser/recovery_node_parser_test.dart`

- [ ] **Step 1: Write failing test for skipped-token recovery**

Add to `test/unit/parser/recovery_node_parser_test.dart`:

```dart
    group('skipped regions', () {
      test('tokens skipped by _parseNode become RecoveryNode', () {
        // A bare closing tag for a void element is skipped —
        // it should still appear in the tree as a recovery node.
        final result = parser.parse('<div></br></div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final recoveryNodes = div.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, contains('br'));
      });
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart -N "skipped by _parseNode"`
Expected: FAIL — no `RecoveryNode` in tree.

- [ ] **Step 3: Implement skipped-token recovery**

This is already handled by Task 3's top-level stray closer logic. The `</br>` case is a void-element closer, which is now caught as a stray closer and wrapped in `RecoveryNode` by the code from Task 3 step 4.

If the test still fails, it means the void-element closer path needs the same treatment. Check that the `_parseNode` stray-closer handler (added in Task 3) also covers void-element closers — it should, since `_consumeClosingTag()` works for any closer regardless of whether the tag is void.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add test/unit/parser/recovery_node_parser_test.dart lib/src/parser/parser.dart
git commit -m "test: add skipped-region recovery node tests"
```

---

### Task 5: Unclosed directive → `RecoveryNode` marker

When `@if`/`@foreach`/etc reach EOF without their closing directive, the parser already creates a valid `DirectiveNode` with all children and adds a `ParseError`. To make recovery explicit in the tree, add a `RecoveryNode` as the **last child** of the directive, marking where the missing closer should have been.

**Files:**
- Modify: `lib/src/parser/parser.dart` (all block directive parse methods)
- Modify: `test/unit/parser/recovery_node_parser_test.dart`

- [ ] **Step 1: Write failing tests for unclosed directive recovery nodes**

Add to `test/unit/parser/recovery_node_parser_test.dart`:

```dart
    group('unclosed directives', () {
      test('unclosed @if gets RecoveryNode marker', () {
        final result = parser.parse('@if(\$x)\n<p>Hello</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        expect(directive.name, 'if');

        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endif'));
      });

      test('unclosed @foreach gets RecoveryNode marker', () {
        final result = parser.parse('@foreach(\$items as \$item)\n<li>{{ \$item }}</li>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        expect(directive.name, 'foreach');

        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endforeach'));
      });

      test('unclosed @while gets RecoveryNode marker', () {
        final result = parser.parse('@while(true)\n<p>loop</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endwhile'));
      });

      test('unclosed generic directive gets RecoveryNode marker', () {
        final result = parser.parse('@auth\n<p>Secret</p>');

        expect(result.isSuccess, isFalse);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.reason, contains('@endauth'));
      });

      test('properly closed directive has no RecoveryNode', () {
        final result = parser.parse('@if(\$x)\n<p>Hello</p>\n@endif');

        expect(result.isSuccess, isTrue);
        final directive = result.ast!.children[0] as DirectiveNode;
        final recoveryNodes = directive.children.whereType<RecoveryNode>();
        expect(recoveryNodes, isEmpty);
      });
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart -N "unclosed"`
Expected: FAIL — no `RecoveryNode` in directive children.

- [ ] **Step 3: Add recovery node to `_parseIfDirective`**

In the unclosed-directive error branch (line ~411), after adding the `ParseError`, also add a `RecoveryNode`:

```dart
    if (!_check(TokenType.directiveEndif)) {
      _errors.add(
        ParseError(
          message:
              'Unclosed @if directive starting at line ${startToken.startLine}',
          position: startToken.startPosition,
          hint: 'Add @endif to close the conditional block',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endif',
        startPosition: pos,
        endPosition: pos,
      ));
    } else {
      _advance();
    }
```

- [ ] **Step 4: Add recovery node to `_parseForeachDirective`**

Apply the same pattern. Find the unclosed check (`if (!_check(TokenType.directiveEndforeach))`), add:

```dart
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endforeach',
        startPosition: pos,
        endPosition: pos,
      ));
```

- [ ] **Step 5: Add recovery node to `_parseForDirective`**

Same pattern for `@for`/`@endfor`.

- [ ] **Step 6: Add recovery node to `_parseWhileDirective`**

Same pattern for `@while`/`@endwhile`.

- [ ] **Step 7: Add recovery node to `_parseSwitchDirective`**

Same pattern for `@switch`/`@endswitch`.

- [ ] **Step 8: Add recovery node to `_parseGenericDirective`**

Same pattern for generic block directives. The closing directive name comes from `_closingDirectiveName(name)` or the matched token type.

- [ ] **Step 9: Run tests to verify they pass**

Run: `dart test test/unit/parser/recovery_node_parser_test.dart`
Expected: All unclosed-directive tests pass.

- [ ] **Step 10: Run full test suite**

Run: `dart test`
Expected: All tests pass. Some existing tests may need minor adjustments if they assert exact children counts on unclosed directives — add `RecoveryNode` to the expected count.

- [ ] **Step 11: Commit**

```bash
git add lib/src/parser/parser.dart test/unit/parser/recovery_node_parser_test.dart
git commit -m "feat: emit RecoveryNode markers for unclosed directives"
```

---

## Chunk 3: Integration and Idempotency

### Task 6: Formatter integration tests

Verify the full pipeline: parse → recovery nodes in tree → format verbatim → idempotent.

**Files:**
- Modify: `test/unit/formatter/recovery_node_formatter_test.dart`

- [ ] **Step 1: Add integration tests**

Add to `test/unit/formatter/recovery_node_formatter_test.dart`:

```dart
    group('integration: parse + format with recovery', () {
      test('stray closer in element formats and re-formats identically', () {
        const input = '<div>Text</bogus>More</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('unclosed @if formats and re-formats identically', () {
        const input = '@if(\$x)\n    <p>Hello</p>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('multiple recovery sites in one template are all idempotent', () {
        const input = '<div></bogus>@if(\$x)<p>Hi</p></div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });

      test('ancestor-close recovery is idempotent', () {
        const input = '<div><span>Text</div>';
        final pass1 = formatter.format(input);
        final pass2 = formatter.format(pass1);
        expect(pass2, equals(pass1));
      });
    });
```

- [ ] **Step 2: Run tests**

Run: `dart test test/unit/formatter/recovery_node_formatter_test.dart`
Expected: All pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/formatter/recovery_node_formatter_test.dart
git commit -m "test: add recovery node formatter integration and idempotency tests"
```

---

### Task 7: Update existing tests and WIP.md

Some existing tests may assert exact children counts or error message patterns that changed. Update them.

**Files:**
- Modify: tests that break (identify by running full suite)
- Modify: `WIP.md`

- [ ] **Step 1: Run full test suite and fix any failures**

Run: `dart test`
Fix any assertion mismatches in existing tests caused by the new `RecoveryNode` children.

- [ ] **Step 2: Update WIP.md**

Add a section documenting Phase 2 Slice 3 / Phase 3 implementation:

```markdown
### Phase 3 Implementation (Recovery Nodes)

Implemented:

- `RecoveryNode` AST node for explicit recovery spans
  - stores verbatim `content` and human-readable `reason`
  - accepted by `visitRecovery` on `AstVisitor`
- Parser emits `RecoveryNode` at three recovery sites:
  - stray HTML closing tags (e.g. `</bogus>` inside `<span>`)
  - top-level stray closing tags
  - unclosed directive boundaries (`@if` without `@endif`, etc.)
- Formatter outputs `RecoveryNode` content verbatim
- All recovery sites are idempotent under re-formatting

Files changed:

- `lib/src/ast/node.dart`
- `lib/src/ast/visitor.dart`
- `lib/src/parser/parser.dart`
- `lib/src/formatter/formatter_visitor.dart`
- `test/unit/ast/recovery_node_test.dart` (new)
- `test/unit/parser/recovery_node_parser_test.dart` (new)
- `test/unit/formatter/recovery_node_formatter_test.dart` (new)
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs: update WIP.md with Phase 3 recovery node implementation"
```
