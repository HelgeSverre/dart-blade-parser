# Edge Cases and Known Limitations

**Last Updated:** 2025-11-27

This document catalogs all edge cases, limitations, and known issues in the dart-blade-parser. Issues are prioritized by severity and implementation complexity.

---

## ✅ FIXED - Recently Resolved

### 1. Raw Text Elements Not Handled (FIXED)

**Issue:** Content inside `<script>`, `<style>`, and `<textarea>` tags was incorrectly parsed as HTML/Blade.
**Status:** **FIXED**. The lexer now enters a "raw text" mode for these tags and correctly preserves their content.

### 2. Script Closing Tag in String Literal (FIXED)

**Issue:** The parser would prematurely close a `<script>` tag if it encountered `</script>` inside a string literal.
**Status:** **FIXED**. The raw text lexing mode now correctly handles quoted strings and ignores closing tags within them.

### 3. Escaped Script Tag Terminators (FIXED)

**Issue:** The lexer treated `<\/script>` as the end of a `<script>` block.
**Status:** **FIXED**. Escaped terminators are now treated as plain text, so JavaScript strings that contain `<\/script>` no longer end the raw text block.

### 4. Performance Benchmark Test Flaw (FIXED)

**Issue:** The HTML parsing benchmark used invalid HTML (missing closing tags), causing the parser to report errors.
**Status:** **FIXED**. The benchmark now renders balanced `<div>` elements so it measures parser throughput without triggering validation errors.

### 5. XML Namespace Attributes (FIXED)

**Issue:** Attributes such as `xmlns:xlink` were suspected of being misclassified as Alpine.js directives.
**Status:** **FIXED**. Regression tests confirm namespace attributes are parsed as standard attributes.

### 6. Unquoted URL Attribute Values (FIXED)

**Issue:** URLs with colons (`:`) in unquoted attribute values caused parse errors.
**Example:** `<a href=https://example.com>Link</a>`
**Status:** **FIXED**. Lexer now allows `:` in unquoted attribute values. All URL tests passing.
**Files:** `lib/src/lexer/lexer.dart`
**Fixed:** 2025-10-10

### 7. Empty Tag Name Validation (FIXED)

**Issue:** Parser accepted empty tag names (`<>content</>`) as valid text.
**Status:** **FIXED**. Lexer now detects `<>` and `</>` as invalid empty tags and emits error tokens.
**Files:** `lib/src/lexer/lexer.dart` (lines 313-333)
**Fixed:** 2025-10-10

### 8. PHP String Interpolation in Echo Statements (FIXED)

**Issue:** Echo statements containing `{$var}` inside double-quoted strings caused lexer errors (e.g., `{{ Arr::get($foo, "key.{$bar}") }}`). The brace counting only decremented on `}}`, so single `}` from PHP interpolation was never matched.
**Status:** **FIXED**. Single `}` now decrements braceCount when > 0; `}}` only closes echo at braceCount == 0.
**Files:** `lib/src/lexer/lexer.dart`
**Fixed:** 2025-02-25

### 9. Regex @props Parsing False Positives (FIXED)

**Issue:** Regex-based `@props` parsing extracted commented-out props as real props and missed required props (standalone entries without `=>`).
**Status:** **FIXED**. Replaced with `PhpArrayParser`, a recursive descent parser that handles comments, string escapes, nested arrays, and all PHP literal value types.
**Files:** `lib/src/docs/php_array_parser.dart`, `lib/src/docs/component_docs.dart`
**Fixed:** 2025-02-25

---

## 🟠 HIGH - Important for Correctness

---

## 🟡 MEDIUM - Nice to Have

_(No medium priority issues at this time)_

---

## 🔵 LOW - Future Enhancements

### 1. Streaming Parser Not Implemented

**Issue:** `StreamingParser` is a stub that buffers all input before parsing, offering no true streaming benefits.
**Status:** This is a major feature requiring a significant rewrite of the lexer and parser state management.
**Files:** `lib/src/streaming/streaming_parser.dart`

### 2. Nested Script Tags (Escaped)

**Issue:** Parser doesn't recognize escaped closing script tags (e.g., `<\/script>`).
**Status:** Addressed by the raw-text lexer fix; retained here for monitoring in case new edge cases appear.

### 3. XML Namespace Attributes

**Issue:** Attributes with namespace colons (e.g., `xmlns:xlink`) might be misclassified as Alpine.js attributes.
**Status:** Covered by unit tests; no misclassification observed.

### 4. Component Tag Name Validation Gaps

**Issue:** Mismatched component tag names (e.g., `<x-alert></x-button>`) may not produce errors in all cases.
**Status:** Validation exists but may have gaps.

---

## 📋 Completed Tasks (2025-10-10)

1. ✅ **Refactor `_lexText` to use a `StringBuffer`** - COMPLETED
   - Solved token fragmentation issue for `@@` escapes
   - Improved lexer robustness and performance
2. ✅ **Fix "Unquoted URL Attribute Values Fail"** - COMPLETED
   - Re-implemented fix for unquoted URLs with colons
   - All URL parsing tests passing
3. ✅ **Fix "Empty Tag Name Validation"** - COMPLETED
   - Lexer now detects and reports empty tag names
   - `isSuccess` correctly returns false when errors exist

---

## 📋 Pending Tasks

### Formatter & Linter - In Progress

**Completed:**

- ✅ Core formatter infrastructure (config, visitor, indent tracker)
- ✅ Main formatter class with format() and needsFormatting()
- ✅ 28 formatter unit tests + 13 idempotency tests (all passing)
- ✅ Test fixtures (8 messy Blade files for integration testing)
- ✅ Justfile commands (format-fixtures, reset-fixtures, show-format-diff)
- ✅ Removed directiveSpacing feature (produces invalid Blade syntax)
- ✅ **CLI Tool** (COMPLETED 2025-10-26)
  - ✅ Created `bin/blade_formatter.dart` with full argument parsing
  - ✅ Glob pattern support (`**/*.blade.php`, directories, individual files)
  - ✅ `--check` mode for CI/CD with proper exit codes
  - ✅ `--write` flag for in-place formatting
  - ✅ `--config` flag for JSON configuration files
  - ✅ stdin/stdout mode support
  - ✅ `--verbose` flag for detailed output
  - ✅ `--indent-size`, `--indent-style`, `--quote-style` CLI overrides
  - ✅ Added to pubspec.yaml as executable
  - ✅ Justfile commands: `format-templates`, `check-templates`
  - ✅ Documentation in README.md with examples
- ✅ **Unified CLI** (COMPLETED 2025-10-26)
  - ✅ Consolidated `blade_parser` and `blade_formatter` into single `blade` CLI
  - ✅ Subcommand structure: `blade parse` and `blade format`
  - ✅ Created `bin/blade.dart` with ArgParser subcommand routing
  - ✅ Removed old `bin/blade_parser.dart` and `bin/blade_formatter.dart`
  - ✅ Updated `pubspec.yaml` to single `blade` executable
  - ✅ Updated all documentation (README.md) with new command structure
  - ✅ Updated justfile commands to use new CLI
  - ✅ Ergonomic improvements: shorter command name, clear subcommands

**Completed:**

- ✅ **Comprehensive Test Coverage** (COMPLETED 2025-11-27)
  - ✅ CLI Integration Tests (39 tests for bin/blade.dart)
  - ✅ Configuration Tests (52 tests for FormatterConfig)
  - ✅ Formatter Edge Case Tests (94 tests)
  - ✅ Formatter Performance Tests (15 tests)
  - ✅ Formatter Regression Tests (39 tests)
  - ✅ Formatter Livewire Tests (39 tests)
  - ✅ Formatter Wrapping Tests (33 tests)
  - ✅ Formatter Sorting Tests (39 tests)
  - ✅ Idempotency Tests (verified across all fixtures)
  - ✅ **Test Suite: 984 tests, 100% passing**

**Completed - Formatter Enhancements (2025-11-27):**

1. ✅ **Line Wrapping** - COMPLETED
   - Implemented maxLineLength feature
   - Wrap long attribute lists to multiple lines
   - Configurable via `WrapAttributes` enum (auto, always, never)

2. ✅ **Multi-line Attribute Formatting** - COMPLETED
   - Break attributes to separate lines when line exceeds maxLineLength
   - Each attribute on its own line with proper indentation
   - Works with HTML elements, components, and slots

3. ✅ **Attribute Sorting** - COMPLETED
   - Sort attributes alphabetically or by category
   - `AttributeSort.byType` sorts: HTML → data-* → Alpine → Livewire → other
   - Within categories, sorts alphabetically

4. **Formatter Documentation** - Low Priority
   - README.md updated with new configuration options
   - Add before/after examples for wrapping and sorting ✅
   - Create `docs/FORMATTER.md` with all formatting rules (future)

**Completed - Quick Wins (2025-11-27):**

1. ✅ **Ignore Comments** - COMPLETED
   - `{{-- blade-formatter:off --}}` / `{{-- blade-formatter:on --}}`
   - `<!-- blade-formatter:off -->` / `<!-- blade-formatter:on -->`
   - Preserve original source text verbatim in ignored sections
   - Support both Blade and HTML comment syntax
   - Also supports `format:off` / `format:on` short syntax

2. ✅ **Closing Tag Style** - COMPLETED
   - Option to put `>` on new line when wrapping attributes
   - `ClosingBracketStyle.sameLine` (default): `class="foo">`
   - `ClosingBracketStyle.newLine`: `class="foo"\n>`

3. ✅ **Self-closing Tag Normalization** - COMPLETED
   - `SelfClosingStyle.preserve` (default): Keep as-is
   - `SelfClosingStyle.always`: Convert empty `<div></div>` to `<div />`
   - `SelfClosingStyle.never`: Convert `<div />` to `<div></div>`
   - Apply to components and non-void HTML elements

**Completed - EditorConfig Integration (2025-11-27):**

- ✅ **EditorConfig Integration** - COMPLETED
  - Read indent_size, indent_style, tab_width from .editorconfig
  - Search parent directories for .editorconfig files
  - Respects root = true to stop searching
  - Priority: EditorConfig < .blade.json < CLI arguments
  - Created EditorConfig parser and section matcher
  - Supports glob patterns: `*`, `*.blade.php`, `{*.html,*.blade.php}`

**Future Enhancements - Formatter:**

- **Format Range** (3-4 hours)
  - Format only a selection/range instead of whole file
  - Useful for editor integrations

- **Trailing Comma in Attributes** (1-2 hours)
  - Option to add trailing comma when attributes are wrapped

**Future Enhancements - Linter:**

- **Linter Rules** (1-2 days)
  - Require @csrf in forms
  - Warn on raw echo `{!! !!}` usage (security)
  - Check max nesting depth
  - Enforce consistent component naming
  - Detect unclosed directives

- **Unused Slot Detection** (3-4 hours)
  - Warn when a slot is defined but never filled

- **Component Prop Validation** (4-6 hours)
  - Check that required props are passed to components

**Future Enhancements - Integrations:**

- **Prettier Plugin** (1-2 weeks)
  - Research integration strategies (CLI wrapper vs dart2js vs LSP)
  - Implement adapter for Prettier API
  - Publish as npm package

- **VS Code Extension** (2-3 weeks)
  - Format on save
  - Configuration file support
  - Hover documentation for directives
  - Status bar integration
  - Diagnostics panel for linter warnings

**Future Enhancements - Analysis:**

- **Include/Extends Graph** (4-6 hours)
  - Build dependency tree of template relationships
  - Visualize @extends and @include chains

- ✅ **Component Discovery** - COMPLETED (2025-11-27)
  - `blade docs <directory>` command to generate markdown docs
  - Extracts @props with names, types, and defaults
  - Detects slot usage and descriptions from comments
  - Generates table of contents, props tables, usage examples

### High Priority - Quick Wins (Code Cleanup)

1. ✂️ **Remove unused variable `tagStartPos`** - 2 min
   - File: `lib/src/lexer/lexer.dart:861`
2. ✂️ **Remove unused variable `attrStart`** - 2 min
   - File: `lib/src/lexer/lexer.dart:949`
3. ✂️ **Remove unused method `_peekWord`** - 2 min
   - File: `lib/src/lexer/lexer.dart:1093`
4. ✂️ **Remove unused variable `startToken`** - 2 min
   - File: `lib/src/parser/parser.dart:1072`

5. 🗑️ **Delete old HTML reports** - 1 min
   - Files: `my_report.html`, `test_report.html`
6. 📝 **Add \*.html to .gitignore** - 1 min

### Medium Priority - Polish & Cleanup

7. **Remove unnecessary null assertions in tests** - 5 min
   - 7 instances across test files
8. **Remove unused test variables** - 3 min
   - 3 instances in test files
9. **Add explicit type arguments** - 10 min
   - 13 places (List<dynamic>, Map<dynamic, dynamic>)
10. **Fix Future.delayed type inference** - 30 min
    - 6 instances in examples and tests
11. **Fix asFuture type inference** - 15 min
    - 2 instances in examples
12. **Update CHANGELOG.md** - 15 min
    - Add v1.0.1 entry with today's fixes
13. **Archive outdated STATUS.md** - 5 min
    - Move to archive/, keep IMPLEMENTATION_STATUS.md
14. **Update version to 1.0.1** - 5 min
    - File: `pubspec.yaml`
15. **Commit changes and prepare release** - 30 min

### Low Priority - Future Enhancements

16. **Improve `_isDirectiveContext()`** - Optional enhancement
    - Consider adding quote-aware tag detection
    - Handle @ inside CSS/JavaScript strings more robustly
    - Current implementation works for 99%+ of cases
    - Estimated effort: 3-4 hours

17. **Implement true streaming parser** - Major feature
    - Current `StreamingParser` is a stub
    - Would require significant rewrite of lexer/parser state management
    - Estimated effort: 2-3 weeks

18. **Enhance Component Tag Name Validation** - Nice to have
    - Improve error position for mismatched component tags
    - Add more comprehensive validation tests
    - Estimated effort: 2-3 hours

---

## 📊 Current Status

**Test Suite Statistics:**

- 📊 **Total tests:** 1343
- ✅ **Passing:** 1343 (100%)
- Test breakdown:
  - Parser/Lexer tests: ~608 (includes echo interpolation tests)
  - Formatter tests: ~508 (edge cases, regression, Livewire, performance, wrapping, sorting, closing style, self-closing, ignore comments, stress, chaos, idempotency, EditorConfig)
  - Docs tests: ~82 (component docs generation + PHP array parser)
  - Integration tests: ~100
  - Performance benchmarks: ~40

**Working Well:**

- ✅ All 108 Blade directives
- ✅ Component parsing with slots (both syntaxes)
- ✅ HTML elements (void elements, attributes, nesting)
- ✅ Unquoted attributes (including URLs with colons)
- ✅ Alpine.js and Livewire attributes
- ✅ Error recovery and multiple error reporting
- ✅ Performance (50K-800K lines/sec - exceeds 1K target by 50-800x)
- ✅ Raw text elements (`<script>`, `<style>`, `<textarea>`)
- ✅ Empty tag validation
- ✅ `@@` escape handling (no token fragmentation)
- ✅ Unicode support (emoji, RTL, combining characters)
- ✅ Whitespace handling (tabs, NBSP, mixed line endings)
- ✅ **Formatter with idempotent output**
- ✅ **CLI tool (`blade parse`, `blade format`)**
- ✅ **Line wrapping** (wrap attributes when line exceeds maxLineLength)
- ✅ **Attribute sorting** (alphabetical or by type)
- ✅ **Closing bracket style** (same line or new line)
- ✅ **Self-closing normalization** (preserve, always, never)
- ✅ **Ignore comments** (blade-formatter:off/on)
- ✅ **EditorConfig integration** (reads settings from .editorconfig)
- ✅ **Component docs generator** (`blade docs` command)

**Known Limitations:**

- ⚠️ True streaming parser not implemented (placeholder only)
- ⚠️ PHP expression formatting not implemented

**Production Readiness:** ✅ **PRODUCTION READY**
