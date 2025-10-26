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
# Parse file to JSON
dart run blade_parser --json template.blade.php

# Parse to tree (default)
dart run blade_parser template.blade.php
dart run blade_parser --tree template.blade.php

# Parse from stdin
cat template.blade.php | dart run blade_parser --stdin

# Format a file (show output)
dart run tool/format_file.dart template.blade.php

# Format and write back to file
dart run tool/format_file.dart template.blade.php --write

# Show help
dart run blade_parser --help
```

### Development Commands

Common `just` commands for development:

```shell
# Run all tests
just test

# Run specific test file
just test-file test/unit/parser/parser_test.dart

# Run tests matching pattern
just test-name "directive"

# Generate coverage report
just coverage

# Generate HTML coverage and open in browser
just coverage-html

# Lint code
just lint

# Format code and apply fixes
just fix

# Run all checks (lint + format + test)
just check

# Run benchmarks
just bench

# Format test fixtures (messy Blade files)
just format-fixtures

# Reset test fixtures to messy state
just reset-fixtures

# Show formatting changes without writing
just show-format-diff

# Generate API documentation
just docs

# Compile CLI to binary
just compile

# Cross-compile for multiple platforms
just cross-compile

# Run playground (Flutter web app)
just playground

# Run acid test suite (parse all fixtures)
just acid
```

See [justfile](justfile) for complete command reference.

## Features

- 75+ Blade directives (@if, @foreach, @section, @component, @auth, @livewireStyles, etc.)
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
- 110+ test fixtures (8,000+ lines) covering real-world and synthetic cases

## Use Cases

**Formatter**: Standardize indentation, normalize spacing, tidy attribute quoting. The included formatter is idempotent and deterministic.

**Linter**: Build static analysis tools to enforce style rules, security policies (flag raw echoes, require `@csrf`), or best practices (prefer `@forelse`, limit nesting depth).

**Code Search & Refactoring**: Find and rename components, migrate directive patterns, or transform attributes with AST-safe operations.

**CI/CD Quality Gates**: Parse all templates in CI to catch syntax errors before deployment. Use format checking to enforce consistent code style.

**Documentation & Metrics**: Generate component usage catalogs, directive frequency reports, or include/extends dependency graphs.

**IDE Integration**: Foundation for editor tooling like syntax highlighting, structure outline, go-to-definition, and on-save formatting.