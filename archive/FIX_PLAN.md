# Prioritized Fix Plan for Parser Failures

**Generated**: 2025-10-07
**Total Failures**: 65 tests across 7 categories
**Current Pass Rate**: 62% (106/171 tests)
**Target Pass Rate**: 100%

## Priority Matrix

| Priority | Category | Tests | Impact | Difficulty | Effort |
|----------|----------|-------|---------|-----------|--------|
| P0 | Raw Text Elements | 9 | CRITICAL | Medium | 2-3 days |
| P0 | HTML Comments | 10 | HIGH | Low | 1 day |
| P1 | Escaped Echo @{{ | 11 | HIGH | Medium | 2 days |
| P1 | Unquoted Attributes | 15 | HIGH | Medium | 2-3 days |
| P2 | Component Slots | 10 | MEDIUM | High | 3-4 days |
| P2 | Component Validation | 9 | MEDIUM | Low | 1 day |
| P3 | Streaming Incremental | 1 | LOW | High | 4-5 days |

---

## P0 - Critical Fixes (Week 1)

### ⚠️ BLOCKER DISCOVERED: HTML Element Parsing Not Implemented

**File**: `lib/src/parser/parser.dart:677-693`
**Status**: `_parseHtmlElement()` returns null - not implemented
**Impact**: Blocks P0.1, P1 (partial), and P2.1 fixes
**Estimated Effort**: 2-3 days to implement full HTML parsing

**What's Needed**:
1. Lexer must emit htmlTagOpen, htmlTagClose, htmlSelfClosing tokens
2. Parser must build HtmlElementNode tree
3. Handle void elements, self-closing, nesting
4. Parse attributes (quoted/unquoted/boolean)

**Decision Required**: Implement HTML parsing first, or focus on non-blocked fixes?

---

### 1. Raw Text Elements (script/style) - 9 failures ❌ BLOCKED
**Impact**: CRITICAL - Breaks JavaScript/CSS in templates
**Difficulty**: Medium → **Blocked by HTML parsing**
**Effort**: 2-3 days (after HTML parsing implemented)
**Tests Failing**: 9/10 tests
**Status**: ⚠️ **BLOCKED** - Cannot fix without HTML element parsing

**Why P0**:
- Every Laravel app with `<script>` or `<style>` tags breaks
- Comparison operators (`<`, `>`) cause parser to treat JS/CSS as HTML
- Common pattern: Alpine.js inline scripts, embedded styles
- Currently 100% broken for any non-trivial JS/CSS

**Technical Approach**:
```
Lexer changes:
1. Add state: inRawTextElement (script/style/textarea)
2. When entering <script> or <style>, switch to raw text mode
3. In raw mode, only look for closing tag (</script> or </style>)
4. Handle edge case: "</script>" in string literal
5. Exit raw mode on proper closing tag

Parser changes:
1. Recognize raw text element tokens
2. Create HtmlElementNode with single TextNode child
3. Do NOT parse content as HTML/Blade
```

**Files to Modify**:
- `lib/src/lexer/lexer.dart` - Add raw text state machine
- `lib/src/parser/parser.dart` - Handle raw text elements
- `lib/src/lexer/token_type.dart` - Add htmlRawText token type (maybe)

**Example**:
```blade
<script>
  if (x < 10 && y > 5) {
    alert('test');
  }
</script>
```
Currently: Parse error (tries to parse `< 10` as tag)
Expected: Single text node with raw content

---

### 2. HTML Comments - 10 failures ✅ COMPLETED
**Impact**: HIGH - Comments stripped from output
**Difficulty**: Low
**Effort**: 1 day → **Completed in 2 hours**
**Tests Passing**: 10/11 tests (91% - 1 test blocked on HTML parsing)
**Status**: ✅ **DONE** - Committed in `57978d7`

**Why P0**:
- HTML comments used for IE conditionals, debugging, documentation
- Blade comments already work, HTML comments didn't
- Simple fix with high impact

**What Was Done**:
- Added `<!-- ... -->` detection in lexer
- Emit `TokenType.htmlComment` tokens
- Fixed duplicate emission bug
- Parser creates `CommentNode` with `isBladeComment=false`
- Bonus: Blade comments also create nodes now (previously skipped)

**Results**:
- ✅ 10/11 tests passing
- ✅ 9 more tests passing overall (67% pass rate, up from 62%)
- ❌ 1 test blocked on HTML element parsing

**Technical Approach**:
```
Lexer changes:
1. Detect <!-- as start of HTML comment
2. Scan until --> found
3. Create token: TokenType.htmlComment
4. Value includes content between <!-- and -->

Parser changes:
1. Case TokenType.htmlComment:
2. Create CommentNode with isBladeComment=false
3. Add to AST
```

**Files to Modify**:
- `lib/src/lexer/lexer.dart` - Add `_scanHtmlComment()` method
- `lib/src/parser/parser.dart` - Add htmlComment case (if not exists)

**Example**:
```blade
<div>
  <!-- This is important -->
  <p>Content</p>
</div>
```
Currently: Comment lost or treated as text
Expected: CommentNode in AST

---

## P1 - High Priority (Week 2)

### 3. Escaped Echo @{{ - 11 failures
**Impact**: HIGH - Common pattern for showing Blade syntax as examples
**Difficulty**: Medium
**Effort**: 2 days
**Tests Failing**: 11/11 tests

**Why P1**:
- Used in documentation, tutorials, and meta-programming
- Laravel docs use @{{ to show examples
- Literal `@@` also needs to be normalized to `@`

**Technical Approach**:
```
Lexer changes:
1. When @ is encountered, peek ahead
2. If next char is {, check if it's {{
3. If @{{, treat entire @{{ as literal text (don't tokenize as echo)
4. If @@, emit single @ as text

Parser changes:
- Minimal (lexer handles it)
- Text tokens should contain @{{ literally
```

**Files to Modify**:
- `lib/src/lexer/lexer.dart` - Modify `_scanAt()` method
- Add escape handling before echo/directive detection

**Example**:
```blade
<p>Use @{{ $variable }} to display variables</p>
<p>Email: admin@@example.com</p>
```
Currently: Parses as echo
Expected: Literal text "@{{ $variable }}" and "admin@example.com"

---

### 4. Unquoted Attributes - 15 failures
**Impact**: HIGH - Common in HTML5, Alpine.js, Livewire
**Difficulty**: Medium
**Effort**: 2-3 days
**Tests Failing**: 15/15 tests

**Why P1**:
- HTML5 allows unquoted attribute values
- Alpine.js often uses: `x-data="{ open: false }"` but also `wire:poll=500ms`
- Livewire uses: `wire:poll=5s`, `wire:loading.delay=200ms`
- Common in modern Laravel development

**Technical Approach**:
```
Lexer changes:
1. In attribute value parsing, if no quote found
2. Scan until whitespace, >, or />
3. Value is everything up to terminator
4. Handle: alphanumeric, hyphen, underscore, period, colon

Valid unquoted chars:
- a-z, A-Z, 0-9
- - (hyphen)
- _ (underscore)
- . (period)
- : (colon for namespaced attrs)

Terminators:
- Whitespace
- >
- />
```

**Files to Modify**:
- `lib/src/lexer/lexer.dart` - Modify `_scanAttribute()` method
- Add unquoted value path after checking for quotes

**Example**:
```blade
<div class=container id=main>
<div wire:poll=500ms>
<input maxlength=100>
```
Currently: Values are null or error
Expected: Attributes with values "container", "main", "500ms", "100"

---

## P2 - Medium Priority (Week 3)

### 5. Component Slots - 10 failures
**Impact**: MEDIUM - Used in component libraries
**Difficulty**: High
**Effort**: 3-4 days
**Tests Failing**: 10/10 tests

**Why P2**:
- Important for component-based architecture
- But less common than P0/P1 features
- Requires new AST node type and special parsing logic

**Technical Approach**:
```
Add SlotNode to AST:
- lib/src/ast/slot_node.dart (new file)
- Properties: name, attributes, children

Lexer changes:
1. Recognize <x-slot:name> syntax
2. Token type: componentSlotTag
3. Extract slot name from colon syntax or name attribute

Parser changes:
1. When parsing component, check for slot children
2. Create SlotNode for each slot
3. Store slots in ComponentNode.slots map
4. Distinguish slots from regular children
```

**Files to Modify**:
- `lib/src/ast/slot_node.dart` - New SlotNode class
- `lib/src/ast/component_node.dart` - Add slots Map<String, SlotNode>
- `lib/src/lexer/lexer.dart` - Recognize slot syntax
- `lib/src/parser/parser.dart` - Parse slots in components

**Example**:
```blade
<x-card>
  <x-slot:header>
    <h2>Title</h2>
  </x-slot:header>

  Body content

  <x-slot:footer>
    <button>OK</button>
  </x-slot:footer>
</x-card>
```
Currently: Slots treated as nested components
Expected: ComponentNode with header/footer slots + default content

---

### 6. Component Validation - 9 failures
**Impact**: MEDIUM - Better error messages
**Difficulty**: Low
**Effort**: 1 day
**Tests Failing**: 9/13 tests (4 passing!)

**Why P2**:
- Improves DX with clear error messages
- Some tests already passing (baseline validation exists)
- Just needs enhancement for edge cases

**Technical Approach**:
```
Parser changes:
1. When parsing component closing tag, validate name matches
2. Track component stack: List<String> componentStack
3. On </x-foo>, check stack.last == 'foo'
4. If mismatch, generate ParseError with both names
5. Include position information for accurate error reporting

Edge cases:
- Nested mismatches
- Case sensitivity (normalize to lowercase)
- Self-closing vs paired
```

**Files to Modify**:
- `lib/src/parser/parser.dart` - Add validation in component parsing
- Enhance `_parseComponentTag()` method

**Example**:
```blade
<x-alert>
  Content
</x-button>
```
Currently: No error (silently accepts)
Expected: ParseError "Expected </x-alert>, found </x-button> at line X"

---

## P3 - Low Priority (Week 4+)

### 7. Streaming Incremental - 1 failure
**Impact**: LOW - Memory optimization for large files
**Difficulty**: High
**Effort**: 4-5 days
**Tests Failing**: 1/1 test

**Why P3**:
- Complex architectural change
- Only matters for very large files (>100KB)
- Current buffering approach works for 99% of use cases
- Requires rethinking parser state management

**Technical Approach**:
```
Architecture changes:
1. Parser must emit nodes ASAP (not at end)
2. StreamController to yield nodes incrementally
3. Maintain partial parse state across chunks
4. Handle chunks splitting mid-token/mid-tag

Challenges:
- Chunk boundary in middle of {{ expression }}
- Buffering strategy for incomplete nodes
- Error recovery with partial data
- State machine complexity

Alternative:
- Keep current buffering for simplicity
- Document memory limits in README
- Defer until real-world need emerges
```

**Files to Modify**:
- `lib/src/parser/streaming_parser.dart` - Major refactor
- `lib/src/lexer/lexer.dart` - Chunk-aware tokenization
- Potentially new classes for state management

**Decision**: Consider deprioritizing further if no user demand

---

## Implementation Schedule

### Week 1 (P0 - Critical)
- **Days 1-3**: Raw Text Elements (script/style)
  - Day 1: Lexer state machine for raw text
  - Day 2: Parser integration + edge cases
  - Day 3: Testing + bug fixes
- **Day 4**: HTML Comments
  - Lexer changes + parser integration
- **Day 5**: Testing, integration, documentation

### Week 2 (P1 - High Priority)
- **Days 1-2**: Escaped Echo @{{
  - Day 1: Lexer escape handling
  - Day 2: Edge cases + testing
- **Days 3-5**: Unquoted Attributes
  - Day 3: Lexer unquoted value scanning
  - Day 4: Parser integration
  - Day 5: Testing + Alpine.js/Livewire patterns

### Week 3 (P2 - Medium Priority)
- **Day 1**: Component Validation
  - Quick win with high DX impact
- **Days 2-5**: Component Slots
  - Day 2: SlotNode design + AST changes
  - Day 3: Lexer slot recognition
  - Day 4: Parser slot handling
  - Day 5: Testing + nested scenarios

### Week 4+ (P3 - Low Priority)
- **Streaming Incremental**: Evaluate need
  - Defer if no real-world requirements
  - Document current limitations
  - Revisit if performance issues reported

---

## Success Metrics

### After P0 (Week 1):
- Pass rate: 78% (133/171 tests)
- All script/style content works
- Comments preserved in output

### After P1 (Week 2):
- Pass rate: 93% (159/171 tests)
- All common Laravel patterns work
- Alpine.js/Livewire fully supported

### After P2 (Week 3):
- Pass rate: 99% (170/171 tests)
- Component-based architecture complete
- Professional-grade error messages

### After P3 (Week 4+):
- Pass rate: 100% (171/171 tests)
- Large file optimization
- Feature-complete parser

---

## Risk Mitigation

### High Risk Items:
1. **Raw Text Elements** - Complex state machine
   - Mitigation: Extensive testing with real-world JS/CSS
   - Add debug logging for state transitions

2. **Component Slots** - New AST node type
   - Mitigation: Design SlotNode carefully upfront
   - Ensure backward compatibility with existing ComponentNode

3. **Streaming** - Architectural complexity
   - Mitigation: Consider marking as "experimental"
   - Document limitations clearly

### Testing Strategy:
- Run full test suite after each category fix
- Add integration tests combining multiple features
- Test with real Laravel Blade templates from popular packages

---

## Notes

- **Block directives** (@unless, @php, @switch, @forelse) already work! ✅
- Some basic functionality exists (6 unexpected passes)
- Parser architecture is solid, just needs feature additions
- No breaking changes expected - only additions

---

## Quick Wins

If time is limited, prioritize these for maximum impact:

1. **HTML Comments** (1 day) - Simple, high visibility
2. **Raw Text Elements** (2-3 days) - Critical for JS/CSS
3. **Component Validation** (1 day) - Already partially working

These 3 fixes would bring pass rate to 84% (144/171) in just 4-5 days.
