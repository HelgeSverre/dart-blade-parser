# Blade Parser

A pure Dart parser for Laravel Blade templates that tokenizes, parses, and produces a traversable AST supporting
complete Blade directive syntax, Alpine.js attributes, Livewire attributes, echo statements, and components.

## Features

- ✅ **Complete Blade Syntax**: 75+ directives (@if, @foreach, @section, @component, etc.)
- ✅ **Component Support**: Full `<x-component>` tag parsing with slots and attributes
- ✅ **Alpine.js Integration**: Parse x-data, x-show, @click, :bind and other Alpine.js attribute
- ✅ **Livewire Support**: Parse wire:click, wire:model with modifiers
- ✅ **Error Recovery**: Continue parsing after errors with descriptive messages
- ✅ **Multiple Error Reporting**: Find all syntax errors in one pass
- ✅ **JSON Serialization**: Export complete AST to JSON
- ✅ **Pure Dart**: Zero external dependencies, works on all platforms
- ✅ **CLI Tool**: Command-line interface for JSON/tree output

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  blade_parser: ^1.0.0
```

Then run:

```shell
dart pub get
```

## Quick Start

### Basic Parsing

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final result = parser.parse('''
    <div>
      @if(\$user->isAdmin())
        <p>Welcome, admin!</p>
      @else
        <p>Welcome, {{ \$user->name }}!</p>
      @endif
    </div>
  ''');

  if (result.isSuccess) {
    print('Parsed successfully!');
    print('AST has ${result.ast!.children.length} top-level nodes');
  } else {
    for (final error in result.errors) {
      print('Error at line ${error.position.line}: ${error.message}');
    }
  }
}
```

### Traverse AST with Visitor Pattern

```dart
import 'package:blade_parser/blade_parser.dart';

class DirectiveCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitDirective(DirectiveNode node) {
    count++;
    print('Found @${node.name} at line ${node.startPosition.line}');
    super.visitDirective(node);
  }

  @override
  void defaultVisit(AstNode node) {}
}

void main() {
  final parser = BladeParser();
  final result = parser.parse('''
    @foreach(\$users as \$user)
      @if(\$user->active)
        <p>{{ \$user->name }}</p>
      @endif
    @endforeach
  ''');

  final visitor = DirectiveCounter();
  result.ast!.accept(visitor);
  print('Total directives: ${visitor.count}');
}
```

### Export AST to JSON

```dart
import 'dart:convert';
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final result = parser.parse('<x-alert type="success">Done!</x-alert>');

  final json = result.ast!.toJson();
  print(JsonEncoder.withIndent('  ').convert(json));
}
```

### Error Handling

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final parser = BladeParser();
  final result = parser.parse('''
    @if(\$condition)
      <p>Content</p>
      <!-- Missing @endif -->
  ''');

  for (final error in result.errors) {
    print('Error: ${error.message}');
    print('Location: line ${error.position.line}, column ${error.position.column}');
    if (error.hint != null) {
      print('Hint: ${error.hint}');
    }
  }

  // Partial AST still available for analysis
  print('Partial AST has ${result.ast!.children.length} nodes');
}
```

## CLI Usage

Parse Blade templates from the command line:

```shell
# Parse file to JSON
dart run blade_parser --json template.blade.php > ast.json

# Parse file to human-readable tree
dart run blade_parser --tree template.blade.php

# Parse from stdin
cat template.blade.php | dart run blade_parser --stdin --json
```

### Exploring Test Fixtures

View the AST of large test fixtures to understand complex template structures:

```shell
# View large template as tree
dart run blade_parser test/fixtures/valid/large_template.blade.php

# Export large template to JSON
dart run blade_parser --json test/fixtures/valid/large_template.blade.php > large.json

# View Alpine.js fixture
dart run blade_parser test/fixtures/alpine/02-faq.blade.php

# Export Alpine.js fixture to JSON
dart run blade_parser --json test/fixtures/alpine/02-faq.blade.php > faq.json

# View all components in a fixture
dart run blade_parser test/fixtures/valid/components.blade.php

# View nested directives
dart run blade_parser test/fixtures/valid/nested_directives.blade.php

# Pretty-print any fixture as JSON with jq (if installed)
dart run blade_parser --json test/fixtures/valid/large_template.blade.php | jq
```

## Performance

- **Throughput**: ≥1000 lines/sec on typical hardware
- **Memory**: <100MB for files under 5000 lines
- **Latency**: <10 seconds for 10,000 line files
- **Nesting**: No degradation up to 20 levels deep

## Platform Support

Works on all Dart platforms:

- Flutter (iOS, Android, Web, Desktop)
- Dart CLI
- Dart Web (dart2js)

## Documentation

- [API Documentation](https://pub.dev/documentation/blade_parser/latest/)
- [Quickstart Guide](specs/001-create-a-laravel/quickstart.md)
- [Data Model](specs/001-create-a-laravel/data-model.md)
- [Parser API Contract](specs/001-create-a-laravel/contracts/parser-api.md)

## Development

```shell
# Run tests
dart test

# Analyze code
dart analyze

# Format code
dart format .

# Generate documentation
dart doc
```

## Contributing

Contributions are welcome! Please ensure:

- All tests pass
- Code follows Dart style guidelines
- New features include tests
- Documentation is updated

## License

MIT License - see LICENSE file for details
