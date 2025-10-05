# Parser API Contract

**Feature**: Laravel Blade Template Parser
**Date**: 2025-10-04
**Version**: 1.0.0

---

## Public API Surface

### BladeParser Class

Primary interface for parsing Blade templates.

#### Method: `parse(String source) → ParseResult`

**Purpose**: Parse Blade template source into AST (full-parse mode)

**Input**:
- `source: String` - Blade template source code

**Output**:
- `ParseResult` - Contains AST, errors, and warnings

**Guarantees**:
- Always returns a ParseResult (never throws for syntax errors)
- FR-026: Multiple errors reported without stopping
- FR-026a: Errors and warnings separated by severity
- FR-026b: Partial AST produced even with errors

**Contract**:
```dart
// Given valid Blade template
ParseResult result = parser.parse("{{ \$user }}");
assert(result.isSuccess == true);
assert(result.errors.isEmpty);
assert(result.ast != null);

// Given invalid Blade template
ParseResult result = parser.parse("@if(\$x)");
assert(result.isSuccess == false);
assert(result.errors.isNotEmpty);
assert(result.ast != null); // Partial AST
assert(result.ast.children.any((n) => n is ErrorNode));
```

---

#### Method: `parseStreaming(Stream<String> chunks) → Stream<AstNode>`

**Purpose**: Parse Blade template incrementally (streaming mode)

**Input**:
- `chunks: Stream<String>` - Stream of template chunks (lines or buffers)

**Output**:
- `Stream<AstNode>` - Stream of complete AST nodes as parsed

**Guarantees**:
- FR-029: Supports incremental parsing for large files
- Emits nodes as soon as complete (e.g., closed @if...@endif)
- Buffers incomplete constructs until closing tag found
- Memory usage proportional to buffered incomplete nodes, not file size

**Contract**:
```dart
// Given file stream
Stream<AstNode> nodes = parser.parseStreaming(file.openRead()
  .transform(utf8.decoder)
  .transform(LineSplitter()));

// Nodes emitted incrementally
await for (final node in nodes) {
  assert(node.startPosition != null);
  assert(node.endPosition != null);
  // Process node immediately without waiting for full file
}
```

---

### BladeLexer Class

Tokenization interface (used internally by BladeParser, but public for advanced use cases).

#### Method: `tokenize(String source) → List<Token>`

**Purpose**: Tokenize Blade template source

**Input**:
- `source: String` - Blade template source code

**Output**:
- `List<Token>` - All tokens in source order, ending with EOF token

**Guarantees**:
- FR-016: All tokens have position information (line, column)
- FR-042: Handles UTF-8 encoded content correctly
- FR-043: Handles LF and CRLF line endings correctly
- Always includes EOF token as last token

**Contract**:
```dart
List<Token> tokens = lexer.tokenize("{{ \$user }}");
assert(tokens.isNotEmpty);
assert(tokens.last.type == TokenType.eof);
assert(tokens.every((t) => t.startLine >= 1));
assert(tokens.every((t) => t.startColumn >= 1));
assert(tokens.every((t) => t.endOffset > t.startOffset));
```

---

### AstNode (Sealed Class Hierarchy)

Base class for all AST nodes.

#### Method: `accept<T>(AstVisitor<T> visitor) → T`

**Purpose**: Visitor pattern for AST traversal

**Input**:
- `visitor: AstVisitor<T>` - Visitor implementation

**Output**:
- `T` - Result from visitor (type parameter)

**Guarantees**:
- FR-017: All node types support visitor pattern
- Exhaustive: Sealed class ensures all subtypes handled

**Contract**:
```dart
class CountVisitor extends RecursiveAstVisitor<int> {
  int count = 0;

  @override
  int visitDirective(DirectiveNode node) {
    count++;
    return super.visitDirective(node);
  }

  @override
  int defaultVisit(AstNode node) => 0;
}

CountVisitor visitor = CountVisitor();
ast.accept(visitor);
assert(visitor.count == expectedDirectiveCount);
```

---

#### Method: `toJson() → Map<String, dynamic>`

**Purpose**: Serialize AST node to JSON

**Input**: None

**Output**:
- `Map<String, dynamic>` - JSON-serializable representation

**Guarantees**:
- FR-019: Full AST serializable to JSON
- All node information preserved (type, position, attributes, children)
- Can be round-tripped through JSON encoding/decoding

**Contract**:
```dart
Map<String, dynamic> json = ast.toJson();
assert(json['type'] != null);
assert(json['position'] != null);
assert(json['position']['start'] != null);
assert(json['position']['end'] != null);

// Can serialize to JSON string
String jsonString = jsonEncode(ast.toJson());
assert(jsonString.isNotEmpty);
```

---

### CLI Interface

Command-line tool for parsing Blade templates.

#### Command: `blade_parser [options] [file]`

**Purpose**: Parse Blade template via CLI

**Options**:
- `--json` - Output AST as JSON (FR-034)
- `--tree` - Output AST as human-readable tree (FR-035, default)
- `--streaming` - Use streaming mode (FR-029)
- `--stdin` - Read from stdin (FR-033)

**Input**:
- File path argument OR stdin (FR-032, FR-033)

**Output**:
- Normal output to stdout (FR-036)
- Errors to stderr (FR-036)
- Exit code 0 on success, non-zero on failure (FR-037)

**Guarantees**:
- FR-032, FR-033: Accepts file path or stdin
- FR-034, FR-035: Supports both JSON and tree output
- FR-036: stdout for output, stderr for errors
- FR-037: Non-zero exit on parse failure

**Contract**:
```bash
# Parse file to JSON
$ blade_parser --json template.blade.php > ast.json
$ echo $?  # 0 on success

# Parse from stdin to tree
$ cat template.blade.php | blade_parser --stdin --tree

# Error to stderr
$ blade_parser invalid.blade.php 2> errors.txt
$ echo $?  # non-zero exit code
```

---

## Performance Contracts

### Throughput (FR-027)

**Contract**: Parser MUST achieve ≥1000 lines/sec for typical templates

**Measurement**:
```dart
final stopwatch = Stopwatch()..start();
final result = parser.parse(templateWith1000Lines);
stopwatch.stop();

assert(stopwatch.elapsedMilliseconds <= 1000); // ≤1s for 1000 lines
```

---

### Memory Usage (FR-028)

**Contract**: Parser MUST use <100MB for typical templates (<5000 lines)

**Measurement**:
```dart
// Requires Dart Observatory heap snapshot
// Peak memory usage < 100MB for 5000-line template
```

---

### Streaming Performance (FR-029)

**Contract**: Streaming mode uses O(buffered nodes) memory, not O(file size)

**Measurement**:
```dart
// Memory usage for 10k-line file in streaming mode
// should be similar to 1k-line file (buffering incomplete nodes only)
```

---

### Nesting Depth (FR-030)

**Contract**: No significant degradation up to 20 nesting levels

**Measurement**:
```dart
// Parse time for 20-level nested @if should be <10% slower than flat template
final flatTime = measureParse(flatTemplate);
final nestedTime = measureParse(nested20LevelsTemplate);

assert((nestedTime - flatTime) / flatTime < 0.10); // <10% slowdown
```

---

## Error Handling Contracts

### Multiple Errors (FR-026)

**Contract**: Parser continues after errors to find all issues

```dart
String template = """
@if(\$a)
  <p>Content</p>
  // Missing @endif

@foreach(\$items as \$item)
  {{ \$item }}
  // Missing @endforeach
""";

ParseResult result = parser.parse(template);
assert(result.errors.length == 2); // Both unclosed directives reported
assert(result.errors[0].message.contains("@if"));
assert(result.errors[1].message.contains("@foreach"));
```

---

### Error Severity (FR-026a)

**Contract**: Errors and warnings separated by severity

```dart
String template = "{{{ \$old }}}"; // Deprecated but valid

ParseResult result = parser.parse(template);
assert(result.errors.isEmpty);
assert(result.warnings.length == 1);
assert(result.warnings[0].message.contains("deprecated"));
```

---

### Partial AST (FR-026b)

**Contract**: Produce partial AST with error markers

```dart
String template = "@if(\$x) <p>Content</p>"; // Missing @endif

ParseResult result = parser.parse(template);
assert(result.ast != null); // Partial AST exists
assert(result.ast.children.any((n) => n is DirectiveNode && n.hasError));
assert(result.errors.isNotEmpty);
```

---

### Error Messages (FR-022)

**Contract**: Error messages are descriptive and actionable

```dart
ParseError error = result.errors[0];
assert(error.message.contains("line"));
assert(error.message.contains("column"));
assert(error.message.contains("@if")); // Specific directive mentioned
assert(error.hint != null); // Suggestion provided
```

---

## Platform Compatibility Contracts

### Pure Dart (FR-038)

**Contract**: No platform-specific dependencies

```dart
// Must compile and run on all Dart platforms:
// - Dart CLI (dart run)
// - Flutter (iOS, Android, web, desktop)
// - Dart web compilation (dart2js)

// No imports from:
// - dart:io (use only in CLI, not core parser)
// - dart:ffi
// - dart:mirrors
// - platform channels
```

---

### UTF-8 Support (FR-042)

**Contract**: Handle UTF-8 encoded templates correctly

```dart
String template = "{{ 'Héllo Wörld 你好' }}";
ParseResult result = parser.parse(template);
assert(result.isSuccess);

EchoNode echo = result.ast.children[0] as EchoNode;
assert(echo.expression.contains("你好"));
```

---

### Line Endings (FR-043)

**Contract**: Handle LF and CRLF line endings correctly

```dart
String templateLF = "@if(\$x)\n  <p>Test</p>\n@endif";
String templateCRLF = "@if(\$x)\r\n  <p>Test</p>\r\n@endif";

ParseResult resultLF = parser.parse(templateLF);
ParseResult resultCRLF = parser.parse(templateCRLF);

assert(resultLF.isSuccess);
assert(resultCRLF.isSuccess);
assert(resultLF.ast.toJson() == resultCRLF.ast.toJson());
```

---

## Backward Compatibility

### Semantic Versioning

**Contract**: Public API follows semantic versioning

- **Major version**: Breaking changes to public API
- **Minor version**: New features, backward compatible
- **Patch version**: Bug fixes, no API changes

**Public API includes**:
- BladeParser class and methods
- ParseResult structure
- AstNode hierarchy
- TokenType enum
- CLI interface and flags

**Not part of public API** (internal, may change):
- Lexer state machine implementation
- Parser internals
- Visitor base class internals
- Token stream management

---

## Contract Test Requirements

All contracts above MUST have corresponding contract tests that:

1. **Verify API Signature**: Ensure method signatures match contract
2. **Test Guarantees**: Assert all promises in "Guarantees" section
3. **Fail on Violation**: Any contract violation fails the test
4. **Run in CI**: Executed before every merge
5. **Block Breaking Changes**: Major version bump required if contract tests fail

---

**Contract Status**: ✅ Complete
**Aligned with FR-031 through FR-043**: ✅ Yes
**Ready for Contract Test Generation**: ✅ Yes
