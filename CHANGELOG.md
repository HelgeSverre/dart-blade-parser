# Changelog

All notable changes to the Blade Parser project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-03-13

### Added
- **Malformed input recovery (Phases 1-3):** The formatter now uses best-effort formatting whenever the parser produces an AST, even with parse errors. Malformed templates that previously threw exceptions now produce formatted output with diagnostics.
- **`RecoveryNode` AST node:** Explicit recovery spans in the AST for stray closing tags, unclosed directives, and malformed tag heads. Each carries a `RecoveryConfidence` (high/low) indicating parser certainty.
- **`RecoverySummary` on `FormatResult`:** Formatted output now includes a curated list of recovery spans (position, confidence, reason) so tooling can highlight recovered regions without manual AST traversal.
- **Tag-head recovery:** Malformed attribute regions in HTML and component tag heads (e.g., `<div ???broken class="ok">`) are captured as `TagHeadRecovery` items and round-tripped verbatim.
- **High-confidence recovery formatting:** Missing closing directives (e.g., unclosed `@if`) are automatically synthesised by the formatter, producing idempotent output.
- **Recovery stress test suite:** 9 malformed template fixtures exercising deeply nested components, PHP blocks, void element closers, directive mismatches, and tag-head garbage.

### Fixed
- **Issue #13 - Default slot `<x-slot:default>` wrapping:** Components with anonymous default slot content no longer wrap children in `<x-slot:default>` tags (same as #11, now with dedicated regression test).
- **`@empty($var)` incorrectly treated as orphan directive:** Standalone `@empty($items)...@endempty` blocks were being caught by orphan directive recovery instead of parsing as block directives. Fixed by checking for a following expression token.
- **`@hasSection` / `@sectionMissing` incorrectly treated as orphan directives:** These inline conditional directives were in the orphan set, causing intermittent test failures and incorrect parsing. Removed from orphan list.
- **Brittle recovery formatter tests:** Replaced exact string equality assertions with structural invariants (startsWith, endsWith, contains, idempotency) so tests survive unrelated formatting changes.

## [1.3.1] - 2026-03-06

npm plugin versioning is now aligned with `blade_parser` (was 0.5.0, now 1.3.1). Both packages share the same version number going forward, published automatically via CI on tag push.

### Added
- **Package component `::` namespace test fixtures:** Exhaustive fixture covering 32 unique `::` component variations.
- **Issue #3 regression tests:** 8 Dart formatter tests and 5 Prettier plugin tests ensuring `<x-filament::button />` is never formatted as `<x-filament : :button />`.
- **Alpine.js attribute formatting (plugin):** Post-processing that formats JavaScript expressions inside Alpine.js attribute values (`x-data`, `@click`, `:class`, etc.) using Prettier's TypeScript parser. New `bladeFormatAlpine` option (default: `true`).
- **Editor setup documentation:** Setup guide for `prettier-plugin-laravel-blade` in 9 editors (VS Code, Cursor, Windsurf, PHPStorm, Neovim, Vim, Zed, Emacs, Nova, Lapce).
- **Directive parenthesis spacing:** New `directiveParenthesisSpacing` config option — `spaced` (`@if ($var)`), `compact` (`@if($var)`), or `preserve` (default). Now available in both Dart formatter and prettier plugin (`bladeDirectiveParenthesisSpacing`).
- **Automated release workflow:** CI publishes both npm and pub.dev packages on `v*.*.*` tag push.

### Fixed
- **Issue #11 - Anonymous component default slot:** Components with anonymous default slot content now render without `<x-slot:default>` tags.
- **Issue #10 - Empty HTML element self-closing:** Empty non-void HTML elements (`<span>`, `<div>`) no longer self-close when using `selfClosingStyle:always` (preserves HTML5 validity).
- **Plugin: `directiveParenthesisSpacing` not wired:** The option was implemented in Dart but not passed through the JS bridge or exposed as a prettier option. Now correctly wired end-to-end.
- **Plugin: broken self-closing test:** Test incorrectly asserted that `<div></div>` with `selfClosingStyle:always` should self-close; corrected to match the issue #10 fix behavior.

## [1.3.0] - 2026-02-27

## [1.2.1] - 2026-02-26

### Breaking Changes
- **`AstVisitor` interface:** New required method `visitPhpBlock(PhpBlockNode node)`. Any code implementing `AstVisitor` must add this method.
- **`@php` blocks:** Previously parsed as `DirectiveNode(name: 'php')`, now parsed as `PhpBlockNode(syntax: bladeDirective)`. Code matching on `DirectiveNode` with `name == 'php'` must be updated.

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
