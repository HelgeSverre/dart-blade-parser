# Blade Parser

A pure Dart parser for Laravel Blade templates. Produces a typed AST with full support for Blade directives, components, Alpine.js, and Livewire attributes. Includes robust error recovery, JSON serialization, and an idempotent formatter.

## Overview

This library tokenizes and parses Blade templates into a traversable abstract syntax tree. It handles the full complexity of modern Blade templates including nested directives, component slots, Alpine.js event handlers, and Livewire wire:model bindings.

Unlike simple regex-based approaches, this parser uses an iterative state machine lexer and recursive descent parser that correctly handles context-aware parsing: emails vs directives, quoted attributes, raw text elements (`<script>`, `<style>`), and verbatim blocks.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  blade_parser: ^1.1.0
```

Then install:

```shell
dart pub get
```

## Quick Start

### CLI Commands

Parse and format Blade templates from the command line:

```shell
# Parse file to JSON (full AST structure)
dart run blade_parser --json template.blade.php

# Parse to tree (default, human-readable)
dart run blade_parser template.blade.php
dart run blade_parser --tree template.blade.php

# Parse from stdin (useful in pipes)
cat template.blade.php | dart run blade_parser --stdin
echo "@if(\$user) Hello @endif" | dart run blade_parser --stdin

# Format templates with blade_formatter CLI
dart run blade_formatter template.blade.php                    # Print to stdout
dart run blade_formatter templates/ --write                     # Format all files in directory
dart run blade_formatter "templates/**/*.blade.php" --write     # Format with glob pattern
dart run blade_formatter templates/ --check                     # Check formatting (CI mode)
cat template.blade.php | dart run blade_formatter --stdin      # Format from stdin

# Format with options
dart run blade_formatter template.blade.php --indent-size 2 --indent-style tabs
dart run blade_formatter templates/ --config .blade-format.json --write

# Show help
dart run blade_parser --help
dart run blade_formatter --help
```

**Parser Output Formats:**

- `--tree` (default): Human-readable tree structure with node types and positions
- `--json`: Complete AST as JSON for programmatic processing
- `--stdin`: Read from standard input instead of a file

**Formatter Options:**

- `--write` or `-w`: Write formatted output back to files (default is stdout)
- `--check` or `-c`: Check if files need formatting without modifying them (for CI/CD)
- `--config <path>`: Load configuration from JSON file
- `--indent-size <n>`: Number of spaces for indentation (default: 4)
- `--indent-style <style>`: Use 'spaces' or 'tabs' (default: spaces)
- `--quote-style <style>`: Quote style - 'single', 'double', or 'preserve' (default: preserve)
- `--stdin`: Format from standard input
- `--verbose` or `-v`: Verbose output with file-by-file progress

### Development Commands

Common `just` commands for development workflow:

**Testing:**

```shell
# Run all tests
just test

# Run specific test file
just test-file test/unit/parser/parser_test.dart

# Run tests matching pattern
just test-name "directive"

# Generate coverage report with summary
just coverage

# Generate HTML coverage and open in browser
just coverage-html
```

**Code Quality:**

```shell
# Lint code (dart analyze)
just lint

# Format code and apply automatic fixes
just fix

# Run all checks (lint + format + test)
just check
```

**Performance:**

```shell
# Run performance benchmarks
just bench
# Measures throughput, memory usage, and nesting depth
```

**Formatter & Template Formatting:**

```shell
# Format templates in a directory
just format-templates templates/

# Check if templates need formatting (CI mode)
just check-templates templates/

# Format test fixtures (messy Blade files)
just format-fixtures

# Reset test fixtures to messy state
just reset-fixtures

# Show formatting changes without writing
just show-format-diff
```

**Documentation:**

```shell
# Generate API documentation (outputs to doc/api/)
just docs
```

**Build & Distribution:**

```shell
# Compile CLI to native binary for current platform
just compile

# Cross-compile for multiple platforms (Linux, macOS)
just cross-compile
# Outputs to build/ directory: blade-linux-x64, blade-macos-arm64, etc.
```

**Development Tools:**

```shell
# Run interactive playground (Flutter web app)
just playground

# Run acid test suite (parse all 112 fixtures)
just acid

# Get/upgrade dependencies
just deps
just deps-upgrade

# Check for outdated dependencies
just deps-outdated

# Dry-run publish to pub.dev
just publish-check

# Full pre-publish checks
just pre-publish
```

See [justfile](justfile) for complete command reference and additional options.

## Features

- 108 Blade directives (@if, @foreach, @section, @component, @auth, @livewireStyles, etc.)
- Blade components (`<x-alert>`) with named and default slots
- Alpine.js attributes (x-data, x-show, @click, :bind) with modifier parsing
- Livewire attributes (wire:click, wire:model.live) with full modifier support
- Echo statements ({{ }}, {!! !!}, {{{ }}})
- Multiple error reporting with positions and hints
- Error recovery continues parsing after syntax errors
- Visitor pattern for AST traversal
- JSON serialization for interoperability
- Zero external parsing dependencies
- Idempotent formatter with configurable style
- 112 test fixtures (17,500+ lines) covering real-world and synthetic cases

## Use Cases

**Formatter**: Standardize indentation, normalize spacing, tidy attribute quoting. The included formatter is idempotent and deterministic.

**Linter**: Build static analysis tools to enforce style rules, security policies (flag raw echoes, require `@csrf`), or best practices (prefer `@forelse`, limit nesting depth).

**Code Search & Refactoring**: Find and rename components, migrate directive patterns, or transform attributes with AST-safe operations.

**CI/CD Quality Gates**: Parse all templates in CI to catch syntax errors before deployment. Use format checking to enforce consistent code style.

**Documentation & Metrics**: Generate component usage catalogs, directive frequency reports, or include/extends dependency graphs.

**IDE Integration**: Foundation for editor tooling like syntax highlighting, structure outline, go-to-definition, and on-save formatting.

## Code Examples

### Parse a Template

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
    print('Parsed ${result.ast!.children.length} nodes');
  } else {
    for (final error in result.errors) {
      print('${error.position.line}:${error.position.column}: ${error.message}');
    }
  }
}
```

### Traverse with Visitor Pattern

```dart
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

### Export to JSON

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

### Format Templates

```dart
import 'package:blade_parser/blade_parser.dart';

void main() {
  final formatter = BladeFormatter(
    config: FormatterConfig(
      indentSize: 4,
      indentStyle: IndentStyle.spaces,
    ),
  );

  final messy = '''
    <div   class="container"  >
    {{   \$user->name   }}\n    @if(  \$condition  )
    <p  >  Hello  </p  >
    @endif
    </div>
  ''';

  final result = formatter.formatWithResult(messy);

  if (!result.hasErrors && result.wasChanged) {
    print(result.formatted);
    // Output:
    // <div class="container">
    //     {{ \$user->name }}
    //     @if(\$condition)
    //         <p>Hello</p>
    //     @endif
    // </div>
  }
}
```

### Check if Formatting Needed

```dart
final formatter = BladeFormatter();

if (formatter.needsFormatting(source)) {
  print('File needs formatting');
  exit(1); // For CI/CD
}
```

## Formatter

The formatter produces deterministic, idempotent output: `format(format(x)) == format(x)`.

### Configuration

```dart
final config = FormatterConfig(
  indentSize: 2,                    // Default: 4
  indentStyle: IndentStyle.spaces,  // or IndentStyle.tabs
  quoteStyle: QuoteStyle.preserve,  // or QuoteStyle.single, QuoteStyle.double
);

final formatter = BladeFormatter(config: config);
```

### API

```dart
// Format and throw on parse errors
final formatted = formatter.format(source);

// Format and get detailed result
final result = formatter.formatWithResult(source);
if (result.isSuccess) {
  print(result.formatted);
  print('Changed: ${result.wasChanged}');
} else {
  for (final error in result.errors) {
    print('Error: ${error.message}');
  }
}

// Check if formatting needed (useful for CI/CD)
if (formatter.needsFormatting(source)) {
  stderr.writeln('File needs formatting');
  exit(1);
}
```

### Features

- Configurable indentation (size and style: spaces or tabs)
- Smart inline vs block formatting (simple content stays inline)
- Normalizes attribute quoting
- Preserves boolean attributes
- Adds final newline
- Spacing between top-level blocks
- Guaranteed idempotency (verified with 13 idempotency tests)

### Before/After Example

**Before:**

```blade
<div   class="container"  >
{{$user->name}}
@if(  $condition  )
<p  >  Hello  </p  >
@endif
</div>
```

**After:**

```blade
<div class="container">
    {{ $user->name }}
    @if($condition)
        <p>Hello</p>
    @endif
</div>
```

## Architecture

The parser uses a two-stage architecture:

### Lexer (Tokenization)

An iterative state machine scanner that emits tokens. Key features:

- Iterative (non-recursive) to avoid stack overflow
- Disambiguates `@` in emails vs directives
- Handles `@@` escapes and `@{{ }}` escaped echoes
- Raw text mode for `<script>`, `<style>`, `<textarea>`
- Recognizes Alpine.js shorthand (`@click`, `:bind`)
- Parses Livewire modifiers (`wire:model.live.debounce.500ms`)

### Parser (AST Construction)

Recursive descent parser building typed AST. Key features:

- Multiple error reporting with positions and hints
- Error recovery via synchronization
- Tag stack validation for matching open/close tags
- Component slot synthesis (named and default slots)
- Specialized handling for control flow, loops, and template inheritance

### AST Node Types

- **DocumentNode**: Root containing all top-level nodes
- **DirectiveNode**: Blade directives (`@if`, `@foreach`, etc.)
- **EchoNode**: Echo statements (`{{ }}`, `{!! !!}`)
- **HtmlElementNode**: HTML tags with attributes
- **ComponentNode**: Blade components (`<x-alert>`) with slots
- **SlotNode**: Component slot definitions
- **TextNode**: Plain text content
- **CommentNode**: HTML and Blade comments
- **ErrorNode**: Placeholder for parse errors

### Attributes

- **StandardAttribute**: Regular HTML attributes
- **AlpineAttribute**: Alpine.js directives with modifiers
- **LivewireAttribute**: Livewire attributes with modifiers

## Supported Directives (108)

### Control Flow

@if, @elseif, @else, @endif, @unless, @endunless, @isset, @endisset, @empty, @endempty, @switch, @case, @default, @endswitch

### Loops

@foreach, @endforeach, @forelse, @empty, @endforelse, @for, @endfor, @while, @endwhile, @continue, @break

### Template Inheritance

@extends, @section, @endsection, @yield, @parent, @show, @overwrite

### Stacks

@push, @endpush, @prepend, @endprepend, @stack, @once, @endonce, @pushOnce, @endPushOnce, @pushIf, @prependOnce, @endPrependOnce

### Components

@component, @endcomponent, @slot, @endslot, @props, @aware

### Includes

@include, @includeIf, @includeWhen, @includeUnless, @includeFirst, @each

### Authorization

@auth, @endauth, @guest, @endguest, @can, @endcan, @cannot, @endcannot, @canany, @endcanany

### Environment

@env, @endenv, @production, @endproduction, @session, @endsession

### Livewire & Filament

@livewireStyles, @livewireScripts, @livewireScriptConfig, @script, @endscript, @assets, @endassets, @filamentStyles, @filamentScripts

### Utilities

@php, @endphp, @verbatim, @endverbatim, @inject, @use, @json, @method, @csrf, @vite, @dd, @dump, @class, @style, @checked, @selected, @disabled, @readonly, @required, @fragment, @endfragment

## Performance

Measured on typical hardware with the benchmark suite. All claims verified by automated benchmarks in CI.

**Throughput:**

- 100,000+ lines/sec on simple templates (benchmarks show 47,000-637,000 lines/sec)
- 500,000+ components/sec on component-heavy templates
- Maintains performance across template sizes (linear scaling)

**Memory:**

- Linear growth: <2KB per line for large files
- ~3MB for 100,000 line templates
- Efficient memory usage with proper GC behavior

**Nesting:**

- No degradation up to 20 levels
- Successfully parses 1,000+ nested levels in <2 seconds
- Iterative lexer avoids stack overflow issues

**Benchmarks are verified in CI**: Run `just bench` to measure performance on your hardware. See [test/performance/](test/performance/) for benchmark source code.

## Test Fixtures

112 test fixtures (17,500+ lines) covering real-world and synthetic cases.

- **Real-world fixtures**: Production templates from Laravel apps (chatflow, reflow, boatflow, unlimit, crescat, kassalapp)
- **Synthetic fixtures**: Systematically generated feature tests covering all directives and edge cases
- **Format fixtures**: 8 intentionally messy files for idempotency and formatting tests

Browse the catalog: [test/fixtures/INDEX.md](test/fixtures/INDEX.md)

Format fixtures for testing:

- [test/fixtures/format/](test/fixtures/format/) - Messy templates for formatter tests
- [test/fixtures/format/README.md](test/fixtures/format/README.md) - Usage instructions and workflow

## Tools

The project includes several tools for development, testing, and demonstration:

### Playground (Interactive Web App)

Interactive Flutter web app for live parsing with JSON/tree visualization and error display. Parse Blade templates in your browser with real-time feedback.

```shell
just playground
# Opens Chrome with the Flutter web app
```

**Features:**

- Live parsing as you type
- JSON and tree visualization
- Error highlighting with positions
- Share example templates

Located in [tool/playground/](tool/playground/).

### Acid Test (Bulk Parse Testing)

Bulk parse testing across all 112 fixtures with console and HTML reporting. Validates parser correctness across the entire fixture suite.

```shell
just acid
# Runs all fixtures and opens HTML report in browser
```

**Output:**

- Console summary with pass/fail counts
- HTML report with detailed results per fixture
- Parse time metrics
- Error details for failed fixtures

Located in [tool/acid/](tool/acid/).

### Format File (Standalone Formatter)

Standalone formatter script for formatting individual Blade files.

```shell
# Preview formatting changes
dart run tool/format_file.dart template.blade.php

# Format and write back to file
dart run tool/format_file.dart template.blade.php --write
```

**Options:**

- No flags: Print formatted output to stdout
- `--write`: Write formatted output back to file

Located in [tool/format_file.dart](tool/format_file.dart).

## Limitations

- Formatter does not reformat PHP expressions inside directives/echoes
- True streaming/incremental parsing not implemented (stub exists)
- Some component error positions are coarse but recoverable
- Line wrapping not implemented (maxLineLength is a placeholder)
- Not a PHP evaluator or security engine (parses syntax safely)

## API Documentation

Full API documentation: [pub.dev/documentation/blade_parser](https://pub.dev/documentation/blade_parser/latest/)

## Platform Support

Works on all Dart platforms:

- Flutter (iOS, Android, Web, Desktop)
- Dart CLI
- Dart Web (dart2js)

## Contributing

Contributions are welcome. Ensure:

- All tests pass (`just test`)
- Code follows Dart style guidelines (`just lint`)
- New features include tests
- Formatter is idempotent on new fixtures

## License

MIT License. See [LICENSE](LICENSE) for details.
