# Changelog

All notable changes to the Blade Parser project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Package component `::` namespace test fixtures:** Exhaustive fixture (`04-package-components-exhaustive.blade.php`) covering 32 unique `::` component variations — self-closing, dotted, deeply dotted, with standard/bound/Alpine/Livewire/mixed attributes, `@class()`, `@style()`, default and named slots, deep nesting, echo expressions, and components inside Blade directives. Verifies Issue #3 fix across all plausible real-world patterns.
- **Issue #3 regression tests:** 8 Dart formatter tests and 5 Prettier plugin tests ensuring `<x-filament::button />` is never formatted as `<x-filament : :button />`.
- **Alpine.js attribute formatting (Prettier plugin):** Post-processing that formats JavaScript expressions inside Alpine.js attribute values (`x-data`, `@click`, `:class`, etc.) using Prettier's TypeScript parser. New `bladeFormatAlpine` option (default: `true`).
- **Editor setup documentation:** Comprehensive documentation for setting up `prettier-plugin-laravel-blade` in 9 editors (VS Code, Cursor, Windsurf, PHPStorm, Neovim, Vim, Zed, Emacs, Nova, Lapce).
- **Directive parenthesis spacing:** New `directiveParenthesisSpacing` config option — `spaced` (`@if ($var)`), `compact` (`@if($var)`), or `preserve` (default).

### Fixed
- **Issue #11 - Anonymous component default slot:** Components with anonymous default slot content now render without `<x-slot:default>` tags.
- **Issue #10 - Empty HTML element self-closing:** Empty non-void HTML elements (`<span>`, `<div>`) no longer self-close when using `selfClosingStyle:always` (preserves HTML5 validity).

## [1.3.0] - 2026-02-27

### Removed
- **`ExpressionParser` class:** Removed unused Pratt expression parser and its tests. The lexer emits PHP expressions as single opaque tokens, so the parser was never wired into production code. Expressions continue to be captured as raw text.
- **`formatPhpExpressions`:** Removed dead config option that was declared but never referenced by the formatter

### Added
- **Component `tagHead` support:** `ComponentNode` now has a `tagHead` field (like `HtmlElementNode`) that preserves structural directives (`@if`/`@endif`, `@class`, etc.) inside component opening tags. The formatter correctly renders these using `_writeTagHead`.
- **Echo spacing** (`echoSpacing`): Control spacing inside echo braces — `spaced` (`{{ $var }}`, default), `compact` (`{{$var}}`), or `preserve` original spacing
- **HTML block spacing** (`htmlBlockSpacing`): Control blank lines between block-level HTML siblings — `betweenBlocks` (default), `none`, or `preserve`
- **Trailing newline** (`trailingNewline`): Control whether formatted output ends with a newline (default: `true`)

### Fixed
- **`_TrackedBuffer` performance:** Replaced `_output.toString().isEmpty` with `_output.isEmpty` to avoid O(N) buffer materialization on every format call; added `removeLast()` method to avoid tripling memory when stripping trailing newlines (`trailingNewline: false`)
- **PHP HEREDOC/NOWDOC in PHP blocks:** The lexer now correctly scans past `<<<EOT`/`<<<'EOT'` bodies inside `<?php ?>` blocks, so `?>` inside HEREDOC strings no longer prematurely terminates the PHP block. Supports PHP 7.3+ flexible (indented) heredoc syntax.
- **Directive expression with space (`@if ($x)`):** The lexer now correctly handles the PSR-12 style space between directive name and opening parenthesis. Previously `@if ($x)` was misparsed — the expression was lost and `$x` became a spurious attribute or text node. Affects both standalone directives and structural directives inside tag heads.
- **Echo expressions in tag heads now trigger `tagHead`:** Blade echo expressions (`{{ $attributes }}`, `{!! $attributes !!}`) inside component/HTML opening tags now populate `tagHead` to preserve attribute order, preventing the formatter's attribute sorting from reordering echoes relative to other attributes (which could alter CSS precedence or attribute merging behavior).
- **Blade comments in tag heads preserved:** `{{-- comment --}}` inside HTML/component opening tags are no longer silently dropped. They are stored as `TagHeadComment` items and rendered by the formatter.
- **`@isset`/`@empty` accept `@endif` as closing tag:** Matches real-world Laravel convention where `@isset` and `@empty` blocks are closed with `@endif` instead of `@endisset`/`@endempty`.
- **Compound colon attributes (`:wire:click`, `:x-bind:class`, `:wire:model.live`):** The lexer's Alpine.js `:bind` shorthand scanner now accepts `:` and `.` in attribute names, so compound attributes like `:wire:model.live.debounce.300ms` are emitted as a single token instead of being split into multiple tokens.
- **Echoes inside quoted attribute values:** Blade echo expressions (`{{ }}`, `{!! !!}`, `{{-- --}}`) inside quoted attribute values no longer prematurely close the attribute. The lexer now tracks echo boundaries and string context within them, correctly handling cases like `wire:key="{{ $this->getId() }}"`.
- **Formatter quote style for Blade attribute values:** When an attribute value contains Blade echo expressions with quotes matching the outer quote style (e.g., `"{{ route("x") }}"`), the formatter now switches to the alternate quote style instead of producing invalid backslash escapes.
- **PHP blocks in tag heads (`<?php if(...): ?>`):** PHP blocks inside HTML/component opening tags are now lexed and preserved as `TagHeadPhpBlock` AST nodes instead of being silently skipped or causing parse errors.
- **Contoso real-world stress fixtures:** 3 anonymized production Blade templates (settings layout, contact detail, ticket detail) covering `@class` in component tags, deep nesting, Livewire/Alpine patterns, and complex slots.
- **`PhpBlockNode` AST node:** Dedicated node for PHP code regions (`<?php ?>`, `<?= ?>`, `<? ?>`, `@php/@endphp`) with `PhpBlockSyntax` enum. PHP blocks are now structurally represented in the AST instead of being treated as raw text or generic directives. Inline `@php($expr)` remains a `DirectiveNode`.
- **Livewire v4 compatibility:** Correctly handles single-file components (SFC) containing inline PHP classes without breaking the parser, and advanced `wire:*` attributes (`wire:navigate`, `wire:confirm`, `wire:stream`, etc.)
- **Volt directive support:** `@volt` / `@endvolt` paired directives for Laravel Volt single-file components
- **Blaze directive support:** `@blaze` (inline marker), `@unblaze` / `@endunblaze` (paired block) for Livewire Blaze component optimization
- **LivewireAttribute sub-action parsing:** `wire:sort:item` now parses structured `action="sort"` and `subAction="item"` fields
- **Component namespace syntax:** `<x-package::component>` and `</x-package::component>` with `::` namespace separator
- **Livewire tag name support:** `<livewire:counter>`, `<livewire:post.create>`, and `<livewire:pages::post.create>` — colons and dots in HTML tag names
- **`@livewire` directive:** Inline directive for embedding Livewire components
- **Echo expressions in tag attributes:** `{{ $attributes->class([...]) }}` and `{!! $attributes !!}` inside component and HTML tag attribute lists
- **Stress test suite:** 826 real-world Blade fixtures from Filament (v2/v3/v4) and FluxUI with 99.9% error-free parse rate
- **`DirectiveSpacing.preserve`:** Was broken — acted the same as `none`. Now correctly preserves blank lines from source between directives, including inside nested contexts
- **`QuoteStyle.preserve`:** Was broken — always defaulted to double quotes because the AST didn't store the original quote character. Now threads quote metadata through lexer → parser → AST → formatter
- **`:$var` shorthand attributes:** Blade `:$attributes`, `:$name`, `:$icon` shorthand syntax is now correctly preserved as a single attribute instead of being split into `:` + `var`
- **Echo attributes dropped with directives:** `{{ $attributes->class([...]) }}` in tag attribute lists was silently dropped when structural directives (`@if`, `@endif`) were also present in the same tag
- **`@unless` / `@endif` compatibility:** `@unless` blocks can now be closed with `@endif`, matching real-world Laravel template conventions
- **`@php` block raw content mode:** `@php` blocks (without expressions) scan to `@endphp` as raw text, preventing PHP comments and strings containing HTML-like tags from breaking the parser
- **Component closing tag simplification:** Unified closing tag scanning for `</x-slot:name>` and `</x-package::component>` using consistent colon support
- **Formatter idempotency (15 fixes):** Resolved remaining idempotency failures in real-world stress fixtures:
  - Empty `<x-slot>` tags now correctly emit closing `</x-slot>` tag (was silently dropped, causing slot to consume subsequent content on re-parse)
  - Inline content optimization skipped when tag head contains structural directives (wrapped attributes made `totalLineLength` check unstable between passes)
  - `_isInlineRenderableElement` newline check aligned with `visitHtmlElement` to prevent `<td><a>...</a></td>` collapse on second pass
- **Stress suite idempotency:** 99.9% (825/826 files), up from 98.1% (810/826)
- **`@else` inside authorization/authentication/environment directives:** `@can`, `@cannot`, `@canany`, `@auth`, `@guest`, `@env`, and `@production` now support `@else` as an intermediate directive. Previously `@else` branches were silently dropped from the AST and formatted output.
- **Void element self-closing slash stripped:** `selfClosingStyle` was not applied to void elements (`<br />`, `<img />`, etc.) — the formatter always output `>` regardless of config. Now `preserve` keeps the original slash, `always` adds it, and `never` strips it. Affected both block formatting (`visitHtmlElement`) and inline rendering (`_renderInlineElement`).

### Prettier Plugin (v0.4.0)
- Rebuilt with all v1.3.0 fixes and features: echo spacing, HTML block spacing, trailing newline, component `tagHead` support, PHP HEREDOC/NOWDOC, directive expression space handling, echo/comment preservation in tag heads, and 15 idempotency fixes.

### Prettier Plugin (v0.4.1)
- Fixed void element self-closing slash (`<br />`, `<img />`, etc.) being stripped regardless of `selfClosingStyle` config.

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
