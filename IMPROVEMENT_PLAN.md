# Lexer Improvements & Edge Case Test Plan

**Created:** 2025-10-10  
**Focus:** Lexer robustness, performance, and comprehensive edge case testing

---

## 🎯 Priority 1: Critical Lexer Fixes

### 1.1 Refactor `_lexText()` to Use StringBuffer
**Issue:** Multiple `_emitToken()` calls create fragmented text tokens (e.g., `@@` escape creates 3 tokens instead of 1)  
**Impact:** Performance degradation, complex AST traversal  
**Files:** `lib/src/lexer/lexer.dart` (lines 94-250)

**Implementation:**
```dart
_LexerState _lexText() {
  final buffer = StringBuffer();
  _start = _position;
  _startLine = _line;
  _startColumn = _column;
  
  while (!_isAtEnd()) {
    final ch = _peek();
    
    // Handle @@ escape
    if (ch == '@' && _peekNext() == '@') {
      buffer.write('@'); // Single @ in output
      _advance(); _advance(); // Skip both
      continue;
    }
    
    // Check for special sequences that end text mode
    if (shouldBreakTextMode(ch)) {
      if (buffer.isNotEmpty) {
        _emitToken(TokenType.text, buffer.toString());
      }
      return nextState;
    }
    
    buffer.write(ch);
    _advance();
  }
  
  if (buffer.isNotEmpty) {
    _emitToken(TokenType.text, buffer.toString());
  }
  return _LexerState.done;
}
```

**Benefits:**
- Single consolidated text token
- Fixes `@@` fragmentation issue
- ~10-20% performance improvement for text-heavy templates
- Simpler AST structure

**Estimated Time:** 2-3 hours  
**Tests Fixed:** 3 tests in `lexer_blade_escapes_test.dart`

---

### 1.2 Fix Unquoted URL Attribute Parsing
**Issue:** URLs with colons (`https://example.com`) fail because `:` is treated as Alpine.js delimiter  
**Current Code:** `lib/src/lexer/lexer.dart` (lines 946-973)  
**Root Cause:** Attribute name parsing stops at `:` for Alpine.js/Livewire detection

**Solution:**
```dart
// In _lexAttributeValue() - unquoted value section
while (!_isAtEnd()) {
  final ch = _peek();
  
  // Allow : in attribute values (for URLs)
  // But still stop at invalid HTML5 unquoted chars
  if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') break;
  if (ch == '>' || (ch == '/' && _peekNext() == '>')) break;
  if (ch == '"' || ch == "'" || ch == '=' || ch == '<' || ch == '`') break;
  
  _advance(); // This now accepts : in values
}
```

**Edge Cases to Handle:**
- `href=https://example.com` ✓
- `href=https://example.com:8080/path` ✓
- `wire:click=handleClick` (still valid) ✓
- `x-bind:href=url` (attribute name has :, value doesn't) ✓

**Estimated Time:** 1-2 hours  
**Tests Fixed:** 1 test in `unquoted_attributes_test.dart` (line 185-197)

---

### 1.3 Improve `_isDirectiveContext()` Robustness
**Issue:** Fragile heuristic for @ disambiguation  
**Current Code:** `lib/src/lexer/lexer.dart` (lines 421-450)  
**Problems:**
- Doesn't handle quoted attribute values properly
- Backward scan for `<` can be fooled by text content
- No handling of @ in CSS/JavaScript strings

**Enhanced Implementation:**
```dart
bool _isDirectiveContext() {
  if (_position == 0) return true;
  
  final prev = _position > 0 ? input[_position - 1] : '\x00';
  
  // Email/domain detection
  if (_isAlphaNumeric(prev) || prev == '.') return false;
  
  // Line start detection
  if (prev == '\n' || prev == '\r' || prev == ' ' || prev == '\t') return true;
  
  // Enhanced tag detection with quote awareness
  if (_isInsideTag()) {
    // Check if we're inside a quoted attribute value
    if (_isInsideQuotedValue()) {
      return false; // @ in "text @here" is literal
    }
    return false; // Alpine.js/Livewire in tags
  }
  
  // Inside <script> or <style> raw text
  if (_rawTextTagName != null) return false;
  
  return true;
}

bool _isInsideTag() {
  int pos = _position - 1;
  bool inQuote = false;
  String? quoteChar;
  
  while (pos >= 0) {
    final ch = input[pos];
    
    if ((ch == '"' || ch == "'") && (pos == 0 || input[pos - 1] != '\\')) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = ch;
      } else if (ch == quoteChar) {
        inQuote = false;
        quoteChar = null;
      }
    }
    
    if (!inQuote) {
      if (ch == '<') return true;
      if (ch == '>') return false;
    }
    
    pos--;
  }
  return false;
}
```

**Estimated Time:** 3-4 hours  
**New Tests Needed:** 10+ (see Test Plan below)

---

## 🧪 Priority 2: Comprehensive Edge Case Tests

### 2.1 Lexer-Specific Edge Cases

**Create:** `test/unit/lexer/lexer_escape_sequences_test.dart`
```dart
// Tests for all escape sequences
- @@ at start of input
- @@ at end of input
- Multiple consecutive @@ (e.g., @@@@)
- @@ inside verbatim blocks
- @@ in script/style tags
- @{{ combined with other escapes
- Escaped quotes inside @{{ ... }}
```

**Create:** `test/unit/lexer/lexer_unicode_test.dart`
```dart
// Extended Unicode testing
- Emoji in directives: @if($emoji == '😀')
- RTL text (Arabic, Hebrew)
- Zero-width characters (ZWJ, ZWNJ)
- Combining diacritics in variable names
- Surrogate pairs
- BOM (Byte Order Mark) handling
- Mixed scripts (Latin + Cyrillic + CJK)
```

**Create:** `test/unit/lexer/lexer_whitespace_test.dart`
```dart
// Whitespace edge cases
- Tab characters in directives
- Vertical tabs, form feeds
- Non-breaking spaces (U+00A0)
- Zero-width spaces (U+200B)
- Mixed line endings (LF, CR, CRLF in same file)
- Trailing whitespace in attributes
- Leading/trailing whitespace in echo expressions
```

**Create:** `test/unit/lexer/lexer_malformed_input_test.dart`
```dart
// Malformed input handling
- Unclosed echo: {{ $var
- Unclosed comment: {{-- comment
- Unclosed directive expression: @if($x
- Nested echo: {{ {{ $x }} }}
- Invalid directive names: @123invalid
- @ followed by special chars: @!, @#, @$
- Component tags with invalid names: <x->, <x-123>
```

**Create:** `test/unit/lexer/lexer_directive_disambiguation_test.dart`
```dart
// @ symbol disambiguation (expansion of directive_context_test.dart)
- @ in CSS: <style>body::before { content: "@"; }</style>
- @ in JavaScript: <script>const x = "@test";</script>
- @ in data attributes: <div data-email="user@example.com">
- @ in quoted attribute: <div title="Email: admin@site.com">
- @ after alphanumeric: test@example.com (email)
- @ after punctuation: !@# (should be directive)
- @ in Alpine.js shorthand: @click vs x-on:click
- @ in Livewire modifiers: wire:model.defer vs @blur
- @@ before directive name: @@foreach should be literal
- Multiple @ symbols: @@@ (should be @ + directive)
```

**Create:** `test/unit/lexer/lexer_attribute_values_test.dart`
```dart
// Comprehensive attribute value testing
- URL protocols: http://, https://, ftp://, mailto:
- Port numbers: https://example.com:8080
- URL fragments: /path#fragment
- URL query strings: /path?key=value&key2=value2
- Data URIs: data:image/png;base64,...
- JavaScript URIs: javascript:void(0)
- Unquoted with periods: class=text.lg.bold
- Unquoted with hyphens: class=text-sm-center
- Unquoted with underscores: data-test_value=some_value
- Mixed case: onclick=handleClick
- Numeric values: tabindex=0, maxlength=100
- Boolean-like: disabled=false, checked=true
- Empty values: class=""
- Single-quoted with escapes: title='It\'s working'
- Double-quoted with escapes: title="Say \"hello\""
- Alpine expressions: x-text="`Hello ${name}`"
```

### 2.2 Parser-Specific Edge Cases

**Create:** `test/unit/parser/parser_error_recovery_test.dart`
```dart
// Error recovery scenarios
- Mismatched component tags: <x-alert></x-button>
- Missing @endif for @if
- Extra @endif without @if
- Overlapping directive blocks
- Component inside verbatim
- Slot outside component
- Invalid slot names: <x-slot:123>
- Self-closing non-void tags: <div />
```

**Create:** `test/unit/parser/parser_nesting_limits_test.dart`
```dart
// Deep nesting edge cases
- 100 levels of @if nesting
- 50 levels of component nesting
- Mixed directive/component nesting
- Circular-like references in slots
- Deep HTML nesting with directives
```

**Create:** `test/unit/parser/parser_expression_edge_cases_test.dart`
```dart
// PHP expression parsing edge cases
- Nested parentheses: @if((($x + $y) * $z))
- Array access: {{ $arr['key']['nested'] }}
- Object chaining: {{ $user->profile->name }}
- Ternary: {{ $x ? $y : $z }}
- Null coalescing: {{ $x ?? $y ?? 'default' }}
- String concatenation: {{ 'Hello ' . $name }}
- Anonymous functions: @php($callback = function() { ... })
- Heredoc/Nowdoc: {{ <<<EOT ... EOT }}
```

### 2.3 Integration Edge Cases

**Create:** `test/integration/real_world_templates_test.dart`
```dart
// Real Laravel Blade patterns from production
- Jetstream authentication views
- Breeze components
- Livewire forms with validation
- Alpine.js modal components
- TailwindCSS utility classes
- Mix of @include, @section, @extends
- API documentation templates
```

**Create:** `test/integration/security_test.dart`
```dart
// Security-related edge cases
- XSS in echo: {{ '<script>alert(1)</script>' }}
- SQL in echo: {{ "'; DROP TABLE users; --" }}
- Path traversal: @include('../../../etc/passwd')
- Very long attribute values (DOS)
- Deeply nested structures (stack overflow)
- Recursive @include patterns
```

---

## 📊 Priority 3: Performance & Stress Tests

### 3.1 Lexer Performance Tests

**Create:** `test/performance/lexer_benchmark_test.dart`
```dart
// Lexer-specific benchmarks
- Tokenize 1M characters of text (no Blade)
- Tokenize 10K directives
- Tokenize complex attribute-heavy HTML
- Tokenize with many @@ escapes
- Memory usage for large files
```

### 3.2 Parser Performance Tests

**Enhance:** `test/performance/throughput_benchmark_test.dart`
```dart
// Add new benchmarks
- 100K line template
- 10K component instances
- 1000 nested levels
- Memory profiling
- GC pressure measurement
```

---

## 🔧 Priority 4: Lexer Code Quality Improvements

### 4.1 Extract Helper Methods
```dart
// Improve code organization in lexer.dart

bool _isValidUnquotedAttrChar(String ch) {
  return ch != ' ' && ch != '\t' && ch != '\n' && ch != '\r' &&
         ch != '>' && ch != '"' && ch != "'" && ch != '=' && 
         ch != '<' && ch != '`';
}

bool _isInsideQuotedValue() { /* implementation */ }
bool _isInsideRawTextElement() { return _rawTextTagName != null; }
bool _shouldStopTextMode(String ch) { /* implementation */ }
```

### 4.2 Add Lexer State Validation
```dart
// Add assertions to catch bugs early
void _validateState() {
  assert(_position >= 0 && _position <= input.length);
  assert(_start >= 0 && _start <= _position);
  assert(_line >= 1);
  assert(_column >= 1);
}
```

### 4.3 Improve Error Messages
```dart
// Add position-aware error reporting
void _emitError(String message) {
  throw BladeLexerException(
    message: message,
    position: Position(line: _line, column: _column),
    context: _getContextSnippet(),
  );
}
```

---

## 📋 Implementation Checklist

### Phase 1: Critical Fixes (Week 1)
- [ ] Refactor `_lexText()` with StringBuffer
- [ ] Fix unquoted URL attribute parsing  
- [ ] Improve `_isDirectiveContext()`
- [ ] Run full test suite (should go from 325/328 to 328/328)

### Phase 2: Lexer Edge Cases (Week 2)
- [ ] Create `lexer_escape_sequences_test.dart` (15 tests)
- [ ] Create `lexer_unicode_test.dart` (10 tests)
- [ ] Create `lexer_whitespace_test.dart` (8 tests)
- [ ] Create `lexer_malformed_input_test.dart` (12 tests)
- [ ] Create `lexer_directive_disambiguation_test.dart` (20 tests)
- [ ] Create `lexer_attribute_values_test.dart` (25 tests)

### Phase 3: Parser Edge Cases (Week 3)
- [ ] Create `parser_error_recovery_test.dart` (15 tests)
- [ ] Create `parser_nesting_limits_test.dart` (10 tests)
- [ ] Create `parser_expression_edge_cases_test.dart` (20 tests)

### Phase 4: Integration & Performance (Week 4)
- [ ] Create `real_world_templates_test.dart` (10 scenarios)
- [ ] Create `security_test.dart` (15 tests)
- [ ] Create `lexer_benchmark_test.dart` (5 benchmarks)
- [ ] Enhance `throughput_benchmark_test.dart` (4 new benchmarks)

### Phase 5: Code Quality (Week 5)
- [ ] Extract helper methods
- [ ] Add state validation assertions
- [ ] Improve error messages
- [ ] Add documentation comments
- [ ] Clean up linter warnings

---

## 📈 Success Metrics

**Current State:**
- 328 tests, 325 passing (99.1%)
- 4 known edge case failures
- Good performance (55K-833K lines/sec)

**Target State:**
- 450+ tests, 447+ passing (99.3%+)
- All critical bugs fixed
- Comprehensive edge case coverage
- Maintained performance (no regression)
- Production-ready for v1.1.0

**Code Quality:**
- Zero linter errors
- <50 linter warnings (down from 493)
- 100% public API documented
- All helper methods extracted

---

## 🚀 Release Plan

**v1.0.1** (Bug fix release)
- Fix `ParseResult.isSuccess` bug
- Fix `@@` token fragmentation
- Fix unquoted URL attributes

**v1.1.0** (Edge case release)
- All Phase 2 lexer tests
- All Phase 3 parser tests
- Improved `_isDirectiveContext()`

**v1.2.0** (Security & performance)
- Security test suite
- Performance benchmarks
- Code quality improvements

