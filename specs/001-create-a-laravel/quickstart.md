# Quickstart Guide: Laravel Blade Parser

**Feature**: Laravel Blade Template Parser
**Date**: 2025-10-04
**Purpose**: Example usage and integration test scenarios

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  blade_parser: ^1.0.0
```

```bash
dart pub get
```

---

## Basic Usage

### 1. Parse a Blade Template (Full Mode)

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  // Create parser
  final parser = BladeParser();

  // Parse Blade template
  final template = '''
    <div>
      @if(\$user->isAdmin())
        <p>Welcome, admin!</p>
      @else
        <p>Welcome, {{ \$user->name }}!</p>
      @endif
    </div>
  ''';

  // Parse to AST
  final result = parser.parse(template);

  // Check for errors
  if (!result.isSuccess) {
    for (final error in result.errors) {
      print('Error at line ${error.position.line}: ${error.message}');
    }
    return;
  }

  // Access AST
  print('Parsed ${result.ast!.children.length} top-level nodes');
}
```

**Expected Output**:
```
Parsed 1 top-level nodes
```

---

### 2. Traverse AST with Visitor

```dart
import 'package:blade_parser/blade_parser.dart';

class DirectiveCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitDirective(DirectiveNode node) {
    count++;
    print('Found @${node.name} directive at line ${node.startPosition.line}');
    super.visitDirective(node);
  }

  @override
  void defaultVisit(AstNode node) {}
}

void main() {
  final parser = BladeParser();
  final template = '''
    @foreach(\$users as \$user)
      @if(\$user->active)
        <p>{{ \$user->name }}</p>
      @endif
    @endforeach
  ''';

  final result = parser.parse(template);

  final visitor = DirectiveCounter();
  result.ast!.accept(visitor);

  print('Total directives: ${visitor.count}');
}
```

**Expected Output**:
```
Found @foreach directive at line 1
Found @if directive at line 2
Total directives: 2
```

---

### 3. Serialize AST to JSON

```dart
import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final template = '<x-alert type="success">Task completed!</x-alert>';

  final result = parser.parse(template);

  // Convert to JSON
  final json = result.ast!.toJson();
  final jsonString = JsonEncoder.withIndent('  ').convert(json);

  print(jsonString);
}
```

**Expected Output**:
```json
{
  "type": "document",
  "position": {
    "start": {"line": 1, "column": 1, "offset": 0},
    "end": {"line": 1, "column": 55, "offset": 54}
  },
  "children": [
    {
      "type": "component",
      "name": "alert",
      "attributes": {
        "type": {
          "type": "standard",
          "name": "type",
          "value": "success"
        }
      },
      "slots": {
        "default": {
          "type": "slot",
          "name": "default",
          "children": [
            {
              "type": "text",
              "content": "Task completed!",
              "position": {...}
            }
          ]
        }
      },
      "isSelfClosing": false,
      "position": {...}
    }
  ]
}
```

---

### 4. Parse with Error Recovery

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();

  // Template with multiple errors
  final template = '''
    @if(\$condition)
      <p>Content</p>
      <!-- Missing @endif -->

    @foreach(\$items as \$item)
      {{ \$item }}
      <!-- Missing @endforeach -->
  ''';

  final result = parser.parse(template);

  // Parser continues despite errors
  print('Success: ${result.isSuccess}');
  print('Errors found: ${result.errors.length}');

  for (final error in result.errors) {
    print('---');
    print('Error: ${error.message}');
    print('Location: line ${error.position.line}, column ${error.position.column}');
    if (error.hint != null) {
      print('Hint: ${error.hint}');
    }
  }

  // Partial AST still available
  print('\nPartial AST has ${result.ast!.children.length} nodes');
}
```

**Expected Output**:
```
Success: false
Errors found: 2
---
Error: Unclosed @if directive starting at line 1, column 1. Expected @endif before end of file.
Location: line 1, column 1
Hint: Add @endif to close the conditional block
---
Error: Unclosed @foreach directive starting at line 5, column 1. Expected @endforeach before end of file.
Location: line 5, column 1
Hint: Add @endforeach to close the loop

Partial AST has 2 nodes
```

---

### 5. Streaming Mode for Large Files

```dart
import 'dart:io';
import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';

void main() async {
  final parser = BladeParser();
  final file = File('large_template.blade.php');

  // Create stream of lines
  final stream = file.openRead()
    .transform(utf8.decoder)
    .transform(LineSplitter());

  // Parse incrementally
  final nodeStream = parser.parseStreaming(stream);

  int nodeCount = 0;
  await for (final node in nodeStream) {
    nodeCount++;

    // Process each node as it's parsed
    if (node is DirectiveNode) {
      print('Directive @${node.name} at line ${node.startPosition.line}');
    }
  }

  print('Processed $nodeCount nodes from stream');
}
```

---

### 6. CLI Usage

```bash
# Parse file to JSON
$ dart run blade_parser --json template.blade.php > ast.json

# Parse file to human-readable tree
$ dart run blade_parser --tree template.blade.php

# Parse from stdin
$ cat template.blade.php | dart run blade_parser --stdin --json

# Use streaming mode
$ dart run blade_parser --streaming --json large_file.blade.php

# Check exit code
$ dart run blade_parser invalid.blade.php
$ echo $?  # Non-zero on error
```

**Example tree output**:
```
Document (line 1-5)
├─ DirectiveNode @if (line 1)
│  ├─ Expression: $user->isAdmin()
│  └─ Children:
│     └─ HtmlElementNode <p> (line 2)
│        └─ TextNode "Welcome, admin!" (line 2)
└─ DirectiveNode @else (line 3)
   └─ Children:
      └─ HtmlElementNode <p> (line 4)
         ├─ TextNode "Welcome, " (line 4)
         ├─ EchoNode {{ $user->name }} (line 4)
         └─ TextNode "!" (line 4)
```

---

## Integration Test Scenarios

### Scenario 1: Parse Dashboard Template (Acceptance Scenario 1)

**Given**: A valid Blade template with control structures (@if, @foreach)

**Template**:
```blade
<div class="dashboard">
  @foreach($widgets as $widget)
    @if($widget->isVisible())
      <div class="widget">
        <h3>{{ $widget->title }}</h3>
        <p>{{ $widget->content }}</p>
      </div>
    @endif
  @endforeach
</div>
```

**When**: The parser processes the file

**Then**:
- Parse succeeds (no errors)
- AST contains DirectiveNode for @foreach with expression "$widgets as $widget"
- AST contains nested DirectiveNode for @if with expression "$widget->isVisible()"
- AST contains EchoNode for {{ $widget->title }} and {{ $widget->content }}

**Test**:
```dart
test('Parse dashboard with control structures', () {
  final parser = BladeParser();
  final result = parser.parse(dashboardTemplate);

  expect(result.isSuccess, isTrue);
  expect(result.errors, isEmpty);

  // Find @foreach directive
  final foreach = result.ast!.children
    .whereType<DirectiveNode>()
    .firstWhere((n) => n.name == 'foreach');
  expect(foreach.expression, contains('\$widgets as \$widget'));

  // Find nested @if
  final ifNode = foreach.children
    .whereType<DirectiveNode>()
    .firstWhere((n) => n.name == 'if');
  expect(ifNode.expression, contains('\$widget->isVisible()'));

  // Find echo statements
  final echos = result.ast!.descendants.whereType<EchoNode>();
  expect(echos.length, equals(2));
});
```

---

### Scenario 2: Parse Component with Slots (Acceptance Scenario 2)

**Given**: A Blade template with component syntax

**Template**:
```blade
<x-card class="shadow-lg">
  <x-slot:header>
    <h2>Card Title</h2>
  </x-slot>

  <p>Card content goes here</p>

  <x-slot:footer>
    <button>Action</button>
  </x-slot>
</x-card>
```

**When**: The parser processes the file

**Then**:
- AST contains ComponentNode with name "card"
- Component has attribute "class" with value "shadow-lg"
- Component has slots: "header", "default", "footer"
- Each slot contains correct child content

**Test**:
```dart
test('Parse component with named slots', () {
  final parser = BladeParser();
  final result = parser.parse(componentTemplate);

  expect(result.isSuccess, isTrue);

  final component = result.ast!.children.first as ComponentNode;
  expect(component.name, equals('card'));
  expect(component.attributes['class']?.value, equals('shadow-lg'));

  // Check slots
  expect(component.slots.keys, containsAll(['header', 'default', 'footer']));

  final header = component.slots['header']!;
  expect(header.children.any((n) =>
    n is HtmlElementNode && n.tagName == 'h2'), isTrue);
});
```

---

### Scenario 3: Parse Alpine.js Attributes (Acceptance Scenario 3)

**Given**: A Blade template with Alpine.js attributes

**Template**:
```blade
<div x-data="{ open: false }" class="dropdown">
  <button @click="open = !open">Toggle</button>
  <div x-show="open" x-transition>
    <a href="#" :class="{ 'active': isActive }">Link</a>
  </div>
</div>
```

**When**: The parser processes the file

**Then**:
- AST preserves Alpine.js directives as distinct AlpineAttribute nodes
- x-data, x-show, x-transition parsed separately from standard attributes
- Shorthand syntax @click and :class recognized as Alpine.js

**Test**:
```dart
test('Parse Alpine.js attributes', () {
  final parser = BladeParser();
  final result = parser.parse(alpineTemplate);

  expect(result.isSuccess, isTrue);

  final div = result.ast!.children.first as HtmlElementNode;

  // Check Alpine.js attributes
  expect(div.attributes['x-data'], isA<AlpineAttribute>());
  expect(div.attributes['x-data']!.value, contains('open: false'));

  // Check standard attribute separate
  expect(div.attributes['class'], isA<StandardAttribute>());

  // Check Alpine.js shorthand
  final button = div.children.first as HtmlElementNode;
  expect(button.attributes, containsKey('@click')); // Alpine shorthand
});
```

---

### Scenario 4: Parse Livewire Attributes (Acceptance Scenario 8)

**Given**: A Blade template with Livewire attributes

**Template**:
```blade
<div wire:poll.5s>
  <form wire:submit.prevent="save">
    <input wire:model.live="name" type="text">
    <button wire:click="submit" wire:loading.attr="disabled">
      Submit
    </button>
  </form>
</div>
```

**When**: The parser processes the file

**Then**:
- AST preserves Livewire attributes with modifiers
- wire:poll.5s parsed as action="poll", modifiers=["5s"]
- wire:submit.prevent parsed as action="submit", modifiers=["prevent"]
- wire:model.live parsed as action="model", modifiers=["live"]

**Test**:
```dart
test('Parse Livewire attributes with modifiers', () {
  final parser = BladeParser();
  final result = parser.parse(livewireTemplate);

  expect(result.isSuccess, isTrue);

  final form = result.ast!.descendants
    .whereType<HtmlElementNode>()
    .firstWhere((n) => n.tagName == 'form');

  final submitAttr = form.attributes['wire:submit'] as LivewireAttribute;
  expect(submitAttr.action, equals('submit'));
  expect(submitAttr.modifiers, contains('prevent'));

  final input = form.children
    .whereType<HtmlElementNode>()
    .firstWhere((n) => n.tagName == 'input');

  final modelAttr = input.attributes['wire:model'] as LivewireAttribute;
  expect(modelAttr.modifiers, contains('live'));
});
```

---

### Scenario 5: Error Reporting (Acceptance Scenario 4)

**Given**: A Blade template with syntax errors

**Template**:
```blade
@if($user)
  <p>Welcome</p>
  <!-- Missing @endif -->

{{ $unclosed
```

**When**: The parser processes the file

**Then**:
- Parser reports error with line 1, column 1 for unclosed @if
- Parser reports error for malformed echo at line 5
- Error messages are descriptive and actionable

**Test**:
```dart
test('Report syntax errors with line and column', () {
  final parser = BladeParser();
  final result = parser.parse(errorTemplate);

  expect(result.isSuccess, isFalse);
  expect(result.errors.length, equals(2));

  final ifError = result.errors[0];
  expect(ifError.message, contains('@if'));
  expect(ifError.message, contains('line 1'));
  expect(ifError.position.line, equals(1));
  expect(ifError.position.column, equals(1));
  expect(ifError.hint, isNotNull);

  final echoError = result.errors[1];
  expect(echoError.message, contains('echo'));
  expect(echoError.position.line, equals(5));
});
```

---

### Scenario 6: Performance (Acceptance Scenario 5)

**Given**: A large Blade template file (10,000+ lines)

**When**: The parser processes the file

**Then**:
- Parsing completes in under 10 seconds
- Memory usage stays under 100MB

**Test**:
```dart
test('Parse large file within performance targets', () {
  final parser = BladeParser();
  final largeTemplate = generateLargeTemplate(10000); // 10k lines

  final stopwatch = Stopwatch()..start();
  final result = parser.parse(largeTemplate);
  stopwatch.stop();

  expect(result.isSuccess, isTrue);
  expect(stopwatch.elapsedSeconds, lessThan(10)); // <10s for 10k lines

  // Memory measurement requires Observatory/DevTools
  // Manual verification: heap snapshot < 100MB
});
```

---

### Scenario 7: JSON Serialization (Acceptance Scenario 6)

**Given**: A parsed AST

**When**: Requested as JSON output

**Then**:
- Entire tree structure serializable to valid JSON
- All node types, attributes, relationships preserved

**Test**:
```dart
test('AST serializes to valid JSON', () {
  final parser = BladeParser();
  final template = '<x-alert>{{ \$message }}</x-alert>';
  final result = parser.parse(template);

  final json = result.ast!.toJson();

  // Serialize to JSON string
  final jsonString = jsonEncode(json);
  expect(jsonString, isNotEmpty);

  // Can deserialize
  final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
  expect(decoded['type'], equals('document'));
  expect(decoded['children'], isA<List>());
  expect(decoded['position'], isNotNull);
});
```

---

### Scenario 8: CLI Interface (Acceptance Scenario 7)

**Given**: A Blade template file

**When**: Using the CLI interface

**Then**:
- Accepts file path and stdin
- Outputs JSON or tree format to stdout
- Outputs errors to stderr

**Test**:
```bash
#!/bin/bash

# Test JSON output
dart run blade_parser --json test.blade.php > output.json
if [ $? -eq 0 ]; then
  echo "✓ JSON output successful"
fi

# Test tree output
dart run blade_parser --tree test.blade.php > output.txt
if [ $? -eq 0 ]; then
  echo "✓ Tree output successful"
fi

# Test stdin input
cat test.blade.php | dart run blade_parser --stdin --json > output.json
if [ $? -eq 0 ]; then
  echo "✓ Stdin input successful"
fi

# Test error reporting
dart run blade_parser invalid.blade.php 2> errors.txt
if [ $? -ne 0 ]; then
  echo "✓ Error exit code correct"
fi
```

---

## Common Use Cases

### Use Case 1: Build a Blade Formatter

```dart
import 'package:blade_parser/blade_parser.dart';

class BladeFormatter {
  String format(String template) {
    final parser = BladeParser();
    final result = parser.parse(template);

    if (!result.isSuccess) {
      throw FormatException('Cannot format invalid template');
    }

    // Use visitor to rebuild formatted template
    final formatter = FormattingVisitor();
    return result.ast!.accept(formatter);
  }
}
```

---

### Use Case 2: Build a Blade Linter

```dart
import 'package:blade_parser/blade_parser.dart';

class BladeLinter {
  List<LintWarning> lint(String template) {
    final parser = BladeParser();
    final result = parser.parse(template);

    final linter = LintVisitor();
    result.ast?.accept(linter);

    return linter.warnings;
  }
}

class LintVisitor extends RecursiveAstVisitor<void> {
  final warnings = <LintWarning>[];

  @override
  void visitEcho(EchoNode node) {
    if (node.isLegacy) {
      warnings.add(LintWarning(
        'Deprecated {{{ }}} syntax, use {{ }} instead',
        node.startPosition,
      ));
    }
    super.visitEcho(node);
  }
}
```

---

### Use Case 3: Extract Translatable Strings

```dart
import 'package:blade_parser/blade_parser.dart';

class TranslationExtractor extends RecursiveAstVisitor<void> {
  final strings = <String>[];

  @override
  void visitText(TextNode node) {
    if (node.content.trim().isNotEmpty) {
      strings.add(node.content.trim());
    }
  }

  @override
  void visitEcho(EchoNode node) {
    // Extract literal strings from expressions
    final pattern = RegExp(r"'([^']+)'");
    for (final match in pattern.allMatches(node.expression)) {
      strings.add(match.group(1)!);
    }
  }
}
```

---

## Next Steps

After understanding the quickstart:

1. **Read API Documentation**: Review `contracts/parser-api.md` for detailed API contracts
2. **Explore Data Model**: See `data-model.md` for complete AST node types
3. **Run Tests**: Execute contract and integration tests
4. **Build Tools**: Use the parser to build formatters, linters, or analyzers

---

**Quickstart Status**: ✅ Complete
**All User Scenarios Covered**: ✅ Yes (Scenarios 1-7 from spec)
**Ready for Implementation**: ✅ Yes
