# Changelog

All notable changes to the Blade Parser project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-02-25

### Parser

- Complete Blade template tokenization with iterative state machine lexer
- Recursive descent parser with error recovery
- Support for 108 Blade directives
- Component parsing with `<x-component>` tag syntax and slot support
- Echo statement parsing (`{{ }}`, `{!! !!}`, `{{{ }}}`)
- PHP string interpolation (`{$var}`) handled correctly inside echo statements
- Raw text elements (`<script>`, `<style>`, `<textarea>`) with string-aware closing tag detection
- Alpine.js and Livewire attribute recognition
- Multiple error reporting with descriptive messages, line/column numbers, and hints
- Partial AST generation even with syntax errors
- Complete sealed class hierarchy with visitor pattern, JSON serialization, and position tracking
- Performance: 50K-800K lines/sec throughput

### Formatter

- Idempotent Blade template formatter with configurable options
- **Line wrapping:** Automatically wrap long attribute lists (`WrapAttributes.auto`, `.always`, `.never`)
- **Attribute sorting:** Sort by type (HTML, data-*, Alpine, Livewire) or alphabetically
- **Closing bracket style:** Same line or new line when attributes are wrapped
- **Self-closing normalization:** Preserve, always, or never
- **Ignore comments:** `{{-- blade-formatter:off --}}` / `{{-- blade-formatter:on --}}`
- **Directive spacing:** Control blank lines between directive blocks
- **Slot formatting:** Compact or block style
- **EditorConfig integration:** Reads `indent_size`, `indent_style`, `tab_width` from `.editorconfig`
- Configuration via `.blade.json` files with CLI overrides

### CLI

- Unified `blade` CLI with subcommands:
  - `blade parse` - Parse templates to tree or JSON AST
  - `blade format` - Format templates with `--write`, `--check`, `--config` options
  - `blade docs` - Generate markdown documentation from Blade components
- Stdin/stdout support for all commands
- Glob pattern support for batch operations

### Component Documentation Generator

- `blade docs <directory>` scans components and generates markdown
- Extracts `@props` directives with names, types, and default values using `PhpArrayParser`
- Correctly handles PHP comments, string escapes, nested arrays inside `@props`
- Detects required props (standalone entries without defaults)
- Detects slot usage and descriptions from Blade comments
- Generates table of contents, props tables, slots lists, and usage examples

### Platform Support

- Pure Dart implementation with zero external parsing dependencies
- Works on Flutter (iOS, Android, Web, Desktop), Dart CLI, and Dart Web
- UTF-8 encoding, LF and CRLF line ending support

### Testing

- 1,343 tests covering parser, formatter, CLI, docs, performance, and security
- Stress tests for extreme whitespace, deep nesting, unicode, and chaos scenarios
- Idempotency verification across all formatter features
- Performance benchmarks for throughput, memory, and nesting depth
