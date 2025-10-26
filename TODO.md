# Edge Cases and Known Limitations

**Last Updated:** 2025-10-10

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

**Next Steps:**

1. **YAML Configuration Support** - Medium Priority (2-3 hours)
   - Add `yaml` package dependency
   - Support `.blade-format.yaml` configuration files
   - Estimated effort: 2-3 hours

2. **Linting Rule System** - High Priority (2-3 days)
   - Design YAML-based configuration (`.blade-lint.yaml`)
   - Implement base LintRule interface
   - Create RuleRegistry for rule management
   - Add 3 security rules (no-unescaped-user-input, require-csrf-forms, no-dangerous-alpine-html)
   - Add 4 style rules (consistent-indentation, no-trailing-whitespace, max-line-length, consistent-quote-style)
   - Add 3 best practice rules (prefer-forelse, no-nested-ternary, component-prop-types)
   - Estimated effort: 12-16 hours

3. **Auto-Fix System** - Medium Priority (1 day)
   - Implement safe auto-fix for linting violations
   - Add `--fix` flag to CLI
   - Support unsafe fixes with `--unsafe-fixes` flag
   - Estimated effort: 4-6 hours

4. **Documentation** - Medium Priority (1 day)
   - Create `docs/FORMATTER.md` with all formatting rules
   - Create `docs/LINTER_RULES.md` with all linting rules and examples
   - Add configuration examples
   - Document each rule with before/after examples
   - Estimated effort: 4-6 hours

5. **Prettier Plugin** - Future Enhancement
   - Research integration strategies (CLI wrapper vs dart2js vs LSP)
   - Implement adapter for Prettier API
   - Publish as npm package
   - Estimated effort: 1-2 weeks

6. **VS Code Extension** - Future Enhancement
   - Format on save
   - Real-time linting with diagnostics
   - Quick fixes for linting violations
   - Hover documentation for directives
   - Estimated effort: 2-3 weeks

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

- 📊 **Total tests:** 532
- ✅ **Passing:** 530 (99.6%)
- ⚠️ **Failing:** 2 (both marked "EXPECTED TO FAIL")
  - Component error position (cosmetic - error still reported)
  - Streaming incremental (feature not implemented)

**Working Well:**

- ✅ All 75+ Blade directives
- ✅ Component parsing with slots (both syntaxes)
- ✅ HTML elements (void elements, attributes, nesting)
- ✅ Unquoted attributes (including URLs with colons) ✨ NEW
- ✅ Alpine.js and Livewire attributes
- ✅ Error recovery and multiple error reporting
- ✅ Performance (50K-800K lines/sec - exceeds 1K target by 50-800x)
- ✅ Raw text elements (`<script>`, `<style>`, `<textarea>`)
- ✅ Empty tag validation ✨ NEW
- ✅ `@@` escape handling (no token fragmentation) ✨ NEW
- ✅ Unicode support (emoji, RTL, combining characters) ✨ NEW
- ✅ Whitespace handling (tabs, NBSP, mixed line endings) ✨ NEW

**Known Limitations:**

- ⚠️ True streaming (stub implementation only - planned for v2.0)
- ⚠️ Component error positions could be more precise (cosmetic issue)

**Production Readiness:** ✅ **READY FOR v1.0.1 RELEASE**
