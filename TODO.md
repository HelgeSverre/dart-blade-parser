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

---

## 🟠 HIGH - Important for Correctness

### 1. Unquoted URL Attribute Values Fail

**Issue:** URLs with colons (`:`) in unquoted attribute values cause parse errors.
**Example:** `<a href=https://example.com>Link</a>`
**Status:** A fix was attempted but caused regressions in component attribute parsing. The fix needs to be re-implemented and the regression resolved.
**Files:** `lib/src/lexer/lexer.dart`

### 2. Empty Tag Name Validation

**Issue:** Parser accepts empty tag names (`<>content</>`) as valid, when it should report an error.
**Status:** `ParseResult.isSuccess` incorrectly returns `true` even when an error is reported.
**Files:** `lib/src/error/parse_result.dart`

---

## 🟡 MEDIUM - Nice to Have

### 1. @@ Escape Creates Fragmented Tokens

**Issue:** Using `@@` to escape the `@` symbol works but creates multiple text tokens instead of a single consolidated one (e.g., `admin`, `@`, `example.com`).
**Impact:** Functional but inefficient and can make AST processing more complex. Data loss issue is resolved.
**Files:** `lib/src/lexer/lexer.dart`

### 2. Performance Benchmark Test Flaw

**Issue:** The HTML parsing benchmark test uses invalid syntax (unclosed tags) and expects success. The parser is correctly reporting errors.
**Fix:** The test should be updated to use valid, closed HTML tags.
**Files:** `test/performance/html_parsing_benchmark_test.dart`

---

## 🔵 LOW - Future Enhancements

### 1. Streaming Parser Not Implemented

**Issue:** `StreamingParser` is a stub that buffers all input before parsing, offering no true streaming benefits.
**Status:** This is a major feature requiring a significant rewrite of the lexer and parser state management.
**Files:** `lib/src/streaming/streaming_parser.dart`

### 2. Nested Script Tags (Escaped)

**Issue:** Parser doesn't recognize escaped closing script tags (e.g., `<\/script>`).
**Severity:** LOW (edge case).

### 3. XML Namespace Attributes

**Issue:** Attributes with namespace colons (e.g., `xmlns:xlink`) might be misclassified as Alpine.js attributes.
**Status:** Untested, potential issue.

### 4. Component Tag Name Validation Gaps

**Issue:** Mismatched component tag names (e.g., `<x-alert></x-button>`) may not produce errors in all cases.
**Status:** Validation exists but may have gaps.

---

## 📋 Newly Added Tasks

1.  **Refactor `_lexText` to use a `StringBuffer`:** This will solve the token fragmentation issue for `@@` escapes and improve the lexer's robustness.
2.  **Fix "Unquoted URL Attribute Values Fail":** Re-apply the fix for unquoted URLs and investigate and fix the component parsing regression it caused.
3.  **Fix "Empty Tag Name Validation":** The `isSuccess` property on `ParseResult` should return `false` if there are any errors. This seems to be a simple bug fix.
4.  **Fix "Performance Benchmark Test Flaw":** The test `test/performance/html_parsing_benchmark_test.dart` uses invalid HTML. This should be corrected.
5.  **Improve `_isDirectiveContext()`:** The current implementation is a bit fragile. It could be improved with more robust checks, for example by using a regex or more context from the parser.
6.  **Add more tests for `_isDirectiveContext()`:** Add specific tests for edge cases like `@` in quoted attributes, and other places where it could be ambiguous.
7.  **Implement true streaming parser:** The current `StreamingParser` is a stub. A true implementation would be a major feature improvement. The first step would be to create a more detailed implementation plan.
8.  **Add support for escaped script tags (`<\/script>`):** This is a low-priority edge case from the `TODO.md`, but it's a concrete task.
9.  **Investigate XML namespace attribute handling:** The `TODO.md` mentions that attributes like `xmlns:xlink` might be misclassified. This needs investigation and a test case.
10. **Enhance Component Tag Name Validation:** The `TODO.md` mentions that mismatched component tags are not always caught. Add more comprehensive tests and fix any gaps in the validation logic in `_parseComponent`.

---

## 📊 Current Status

**Working Well:**
- ✅ All 75+ Blade directives
- ✅ Component parsing with slots (both syntaxes)
- ✅ HTML elements (void elements, attributes, nesting)
- ✅ Unquoted attributes (except URLs with colons)
- ✅ Alpine.js and Livewire attributes
- ✅ Error recovery and multiple error reporting
- ✅ Performance (30-200x faster than targets)
- ✅ Raw text elements (`<script>`, `<style>`, `<textarea>`)

**Known Limitations:**
- ❌ `@@` escape creates fragmented tokens.
- ❌ Unquoted URL attributes fail.
- ❌ True streaming (stub implementation only).
- ❌ `isSuccess` can be true even with errors.