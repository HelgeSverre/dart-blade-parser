# Changelog

All notable changes to the Blade Parser project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-02-26

### Added
- **Livewire v4 support:** Full support for single-file components (SFC), functional API, and advanced attributes (`wire:navigate`, `wire:confirm`, `wire:stream`, etc.)
- **Volt directive support:** `@volt` / `@endvolt` paired directives for Laravel Volt single-file components
- **Blaze directive support:** `@blaze` (inline marker), `@unblaze` / `@endunblaze` (paired block) for Livewire Blaze component optimization
- **LivewireAttribute sub-action parsing:** `wire:sort:item` now parses structured `action="sort"` and `subAction="item"` fields
- **Component namespace syntax:** `<x-package::component>` and `</x-package::component>` with `::` namespace separator
- **Livewire tag name support:** `<livewire:counter>`, `<livewire:post.create>`, and `<livewire:pages::post.create>` — colons and dots in HTML tag names
- **`@livewire` directive:** Inline directive for embedding Livewire components
- **Echo expressions in tag attributes:** `{{ $attributes->class([...]) }}` and `{!! $attributes !!}` inside component and HTML tag attribute lists
- **Stress test suite:** 826 real-world Blade fixtures from Filament (v2/v3/v4) and FluxUI with 99.9% error-free parse rate

### Fixed
- **`@unless` / `@endif` compatibility:** `@unless` blocks can now be closed with `@endif`, matching real-world Laravel template conventions
- **`@php` block raw content mode:** `@php` blocks (without expressions) scan to `@endphp` as raw text, preventing PHP comments and strings containing HTML-like tags from breaking the parser
- **Component closing tag simplification:** Unified closing tag scanning for `</x-slot:name>` and `</x-package::component>` using consistent colon support

## [1.2.1] - 2026-02-26

### Fixed
- **Formatter idempotency:** Fix 14 cases where whitespace between inline text and HTML elements or Blade directives expanded on each re-format pass. Introduced `_beginLine()` helper to centralize indentation logic and made `visitText` sibling-aware.
- **Inline element preservation:** Inline HTML elements (`span`, `a`, `strong`, `br`, etc.) now stay on the same line as surrounding text instead of being broken onto separate lines. A `maxLineLength` guard ensures graceful fallback to block formatting.

### Prettier Plugin (v0.3.2)
- Rebuilt with formatter idempotency fixes.

## [1.2.0] - 2025-02-26

### Fixed
- **Lexer performance:** Fix O(n²) bottleneck in directive context detection — reorder checks so cheap whitespace/newline conditions are evaluated before expensive backward-scanning methods. Directive-heavy benchmark improved from ~4.2K to ~1.49M directives/sec.
- **Syntax highlighter:** Fix `@directive(...)` inside HTML tags breaking highlighting. The `>` in PHP `=>` arrows and `->` method calls no longer prematurely closes the tag scan. `@class([...])`, `@style([...])` etc. are now properly tokenized as directive + expression.

### Prettier Plugin (v0.3.1)
- Rebuilt with latest lexer performance fix and highlighter improvements.

## [1.1.0] - 2025-02-25

### Added
- **Slot name style** (`slotNameStyle`): Control how slot names are rendered — `colon` (`<x-slot:header>`), `attribute` (`<x-slot name="header">`), or `preserve` original syntax
- **Slot spacing** (`slotSpacing`): Control blank lines around slot elements — `after` (default), `before`, `around`, or `none`
- `@else` branch support inside `@empty` and `@isset` directives
- Livewire dashboard page fixture and playground example

### Fixed
- `<x-slot name="header">` no longer produces `<x-slot:header name="header">` (duplicate name attribute)
- `@empty` inside `@forelse` is now correctly treated as an intermediate directive (no `@endempty` emitted)
- Standalone `@empty($var)` blocks correctly emit `@endempty` closing tag
- Unknown/custom directives are now preserved as text instead of being dropped

### Prettier Plugin (v0.3.0)
- Rebuilt with latest parser fixes — directives like `@inertia()` are no longer dropped
- Fixed site deployment to always use fresh `blade-formatter.js` build

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
