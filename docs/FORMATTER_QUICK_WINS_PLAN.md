# Formatter Quick Wins - Implementation Plan

This document outlines the implementation plan for three formatter enhancements:
1. Ignore Comments (`blade-formatter:off` / `blade-formatter:on`)
2. Closing Tag Style (bracket on new line)
3. Self-closing Tag Normalization

---

## 1. Ignore Comments Feature

### Overview

Allow users to disable formatting for specific sections of their template using special comments.

### Syntax Support

Both Blade and HTML comments should work:

```blade
{{-- blade-formatter:off --}}
<div    class="preserve"   >
    This   content    is   preserved   exactly
</div>
{{-- blade-formatter:on --}}

<!-- blade-formatter:off -->
<table>
<tr><td>1</td><td>2</td><td>3</td></tr>
</table>
<!-- blade-formatter:on -->
```

### Comment Variations

The following should all be recognized (case-insensitive):
- `blade-formatter:off` / `blade-formatter:on`
- `blade-formatter-disable` / `blade-formatter-enable`
- `format:off` / `format:on` (short form)

### Implementation Strategy

#### Step 1: Pass Original Source to FormatterVisitor

Currently `FormatterVisitor` only receives the AST. To preserve original text, we need to:

```dart
// In formatter.dart
String format(String source) {
  final parser = BladeParser();
  final result = parser.parse(source);

  if (!result.isSuccess) {
    throw FormatterException(...);
  }

  // Pass original source to visitor
  final visitor = FormatterVisitor(config, source: source);
  return visitor.format(result.ast!);
}
```

#### Step 2: Track Formatting State in Visitor

```dart
class FormatterVisitor implements AstVisitor<String> {
  final String? _source;  // Original source for raw output
  bool _formattingEnabled = true;

  FormatterVisitor(this.config, {String? source})
      : _source = source,
        _indent = IndentTracker(config);
```

#### Step 3: Detect Control Comments

```dart
/// Check if a comment is a formatter control comment.
/// Returns: 'off', 'on', or null
String? _getFormatterControl(CommentNode node) {
  final content = node.content.toLowerCase().trim();

  // Strip comment delimiters
  var text = content;
  if (text.startsWith('{{--')) text = text.substring(4);
  if (text.endsWith('--}}')) text = text.substring(0, text.length - 4);
  if (text.startsWith('<!--')) text = text.substring(4);
  if (text.endsWith('-->')) text = text.substring(0, text.length - 3);
  text = text.trim();

  // Check for control commands
  if (text == 'blade-formatter:off' ||
      text == 'blade-formatter-disable' ||
      text == 'format:off') {
    return 'off';
  }
  if (text == 'blade-formatter:on' ||
      text == 'blade-formatter-enable' ||
      text == 'format:on') {
    return 'on';
  }

  return null;
}
```

#### Step 4: Handle Raw Output in Visitor

When formatting is disabled, output the original source text between nodes:

```dart
@override
String visitComment(CommentNode node) {
  final control = _getFormatterControl(node);

  if (control == 'off') {
    _formattingEnabled = false;
    // Output the comment itself
    _outputRaw(node);
    return '';
  }

  if (control == 'on') {
    _formattingEnabled = true;
    // Output the comment itself
    _outputRaw(node);
    return '';
  }

  if (!_formattingEnabled) {
    _outputRaw(node);
    return '';
  }

  // Normal formatting...
}

void _outputRaw(AstNode node) {
  if (_source == null) return;

  final start = node.startPosition.offset;
  final end = node.endPosition.offset;
  _output.write(_source!.substring(start, end));
}
```

#### Step 5: Apply to All Visit Methods

Each visit method needs to check `_formattingEnabled`:

```dart
@override
String visitHtmlElement(HtmlElementNode node) {
  if (!_formattingEnabled) {
    _outputRaw(node);
    return '';
  }

  // Normal formatting...
}
```

### Test Cases

1. Basic off/on with Blade comments
2. Basic off/on with HTML comments
3. Multiple off/on regions in same file
4. Nested structures within off region
5. Off without matching on (disable to end of file)
6. Already disabled region (no double output)
7. Case insensitivity
8. Short form (format:off/on)

---

## 2. Closing Tag Style Feature

### Overview

When attributes are wrapped to multiple lines, control where the closing `>` appears.

### Options

```dart
enum ClosingBracketStyle {
  /// Closing bracket on same line as last attribute (default)
  /// Example:
  /// ```
  /// <div
  ///     class="foo"
  ///     id="bar">
  /// ```
  sameLine,

  /// Closing bracket on its own line
  /// Example:
  /// ```
  /// <div
  ///     class="foo"
  ///     id="bar"
  /// >
  /// ```
  newLine,
}
```

### Implementation

#### Step 1: Add to FormatterConfig

```dart
class FormatterConfig {
  // ... existing fields

  /// Style for closing bracket when attributes are wrapped.
  final ClosingBracketStyle closingBracketStyle;

  const FormatterConfig({
    // ... existing params
    this.closingBracketStyle = ClosingBracketStyle.sameLine,
  });
}
```

#### Step 2: Update _writeAttributes

```dart
void _writeAttributes(List<AttributeNode> attributes, {
  required bool wrap,
  required String closingBracket,
}) {
  // ... existing code for attributes

  if (wrap) {
    // Multi-line formatting
    for (var i = 0; i < sortedAttrs.length; i++) {
      _output.write(_indent.current);
      _output.write(_formatAttribute(sortedAttrs[i]));
      _output.writeln();
    }

    // Closing bracket based on style
    if (config.closingBracketStyle == ClosingBracketStyle.newLine) {
      _output.write(_indent.current);
    }
    _output.write(closingBracket);
    _indent.decrease();
  } else {
    // ... single line (unchanged)
  }
}
```

### Test Cases

1. sameLine style (default behavior preserved)
2. newLine style with HTML elements
3. newLine style with components
4. newLine style with self-closing tags
5. No effect when not wrapping (single line)

---

## 3. Self-closing Tag Normalization

### Overview

Control whether empty elements are formatted as self-closing or with explicit close tags.

### Options

```dart
enum SelfClosingStyle {
  /// Preserve original style
  preserve,

  /// Convert empty elements to self-closing: <div />
  always,

  /// Convert self-closing to explicit close: <div></div>
  never,
}
```

### Scope

- **Applies to:** Components (`<x-alert />`) and non-void HTML elements (`<div />`)
- **Does NOT apply to:** Void elements (img, br, input, etc.) - these are always self-closing

### Implementation

#### Step 1: Add to FormatterConfig

```dart
class FormatterConfig {
  // ... existing fields

  /// How to format empty (no children) elements.
  final SelfClosingStyle selfClosingStyle;

  const FormatterConfig({
    // ... existing params
    this.selfClosingStyle = SelfClosingStyle.preserve,
  });
}
```

#### Step 2: Track Original Style in AST

We need to know if the original element was self-closing. Check if `HtmlElementNode` already has this info:

```dart
// In node.dart - HtmlElementNode may need:
final bool isSelfClosing;  // Was it written as <div /> in source?
```

If not available, we may need to:
- Add it to the parser
- Or infer from children being empty AND checking source

#### Step 3: Update visitHtmlElement

```dart
@override
String visitHtmlElement(HtmlElementNode node) {
  final tagName = node.tagName.toLowerCase();
  final isVoid = _voidElements.contains(tagName);

  // Void elements are always self-closing
  if (isVoid) {
    _writeOpeningTag(node);
    _output.writeln();
    return '';
  }

  final hasContent = node.children.any(
    (c) => c is! TextNode || c.content.trim().isNotEmpty
  );

  // Determine if we should self-close
  final shouldSelfClose = !hasContent && _shouldSelfClose(node, isComponent: false);

  if (shouldSelfClose) {
    _writeOpeningTagSelfClosing(node);
    _output.writeln();
    return '';
  }

  // Normal formatting with explicit close tag...
}

bool _shouldSelfClose(dynamic node, {required bool isComponent}) {
  switch (config.selfClosingStyle) {
    case SelfClosingStyle.preserve:
      // Check if original was self-closing
      return node.isSelfClosing ?? false;
    case SelfClosingStyle.always:
      return true;
    case SelfClosingStyle.never:
      return false;
  }
}
```

#### Step 4: Update visitComponent

Similar logic for components.

### Test Cases

1. preserve style - self-closing stays self-closing
2. preserve style - explicit close stays explicit
3. always style - empty div becomes self-closing
4. always style - empty component becomes self-closing
5. always style - element with content NOT converted
6. never style - self-closing becomes explicit close
7. never style - void elements unchanged (always self-closing)
8. Works with attribute wrapping

---

## Implementation Order

1. **Closing Tag Style** (simplest, isolated change)
2. **Self-closing Normalization** (may need parser changes)
3. **Ignore Comments** (most complex, touches all visit methods)

## Files to Modify

- `lib/src/formatter/formatter_config.dart` - Add new enums and config options
- `lib/src/formatter/formatter_visitor.dart` - Implement features
- `lib/src/formatter/formatter.dart` - Pass source to visitor (for ignore comments)
- `lib/src/ast/node.dart` - May need `isSelfClosing` flag
- `lib/src/parser/parser.dart` - May need to track self-closing style
- `test/formatter/` - New test files for each feature
- `README.md` - Document new options
- `CHANGELOG.md` - Document changes

## Estimated Total Effort

- Closing Tag Style: 1-2 hours
- Self-closing Normalization: 2-3 hours (may be more if parser changes needed)
- Ignore Comments: 2-3 hours

**Total: ~6-8 hours**
