# Research: Enhanced HTML Element Parsing

**Feature**: 002-enhanced-html-parsing  
**Date**: 2025-10-05

---

## HTML Tag Tokenization Strategy

**Decision**: State-based tokenization in existing `_LexerState` enum

**Rationale**:
- Consistent with existing directive/component tokenization approach
- Minimal code churn - extends existing state machine
- Reuses existing position tracking and error handling
- Clear state transitions: text → htmlTag → attributes → text

**Implementation Details**:
1. Add `htmlTag` state to `_LexerState` enum
2. Detect `<` + letter (not `@`, not `x-`) → transition to htmlTag state  
3. Scan tag name until whitespace or `>` or `/>`
4. Emit `htmlTagOpen` token with tag name
5. If attributes present → lex attributes (reuse `_lexAttribute()`)
6. If `/>`→ emit `htmlTagSelfClose`, else emit `htmlTagEnd`
7. Track closing tags: `</` + tagName + `>` → emit `htmlTagClose`

**Alternatives Considered**:
- **Separate HTML lexer**: Rejected - unnecessary complexity, code duplication
- **Regex-based parsing**: Rejected - slower, harder to maintain, poor error messages

---

## Void Element Handling

**Decision**: Static set of void elements checked in parser

**Rationale**:
- Fixed HTML5 void element list (14 elements total)
- No runtime overhead - simple set lookup
- Clear validation: void elements cannot have children or closing tags
- Consistent with HTML5 spec

**Void Elements List**:
```
area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr
```

**Implementation**:
```dart
static const _voidElements = {
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img',
  'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'
};

bool _isVoidElement(String tagName) =>
    _voidElements.contains(tagName.toLowerCase());
```

**Validation Rules**:
1. Void elements MUST NOT have closing tags
2. Void elements MUST NOT have children
3. Void elements MAY use self-closing `/>` (optional)
4. Error if closing tag found for void element

**Alternatives Considered**:
- **Dynamic detection from DOM**: Rejected - slower, needs external data
- **Parser-level detection**: Accepted - compile-time constant, O(1) lookup

---

## HTML vs Component Detection

**Decision**: `<x-` prefix indicates component, all others are HTML

**Rationale**:
- Already implemented and working in feature 001
- Unambiguous distinction at lexer level
- No lookahead needed - immediate decision
- Consistent with Laravel Blade conventions

**Detection Logic**:
```dart
if (ch == '<') {
  if (_peekNext() == 'x' && _peekAhead(2) == '-') {
    return _lexComponentTag();  // <x-component>
  } else if (_isAlpha(_peekNext())) {
    return _lexHtmlTag();       // <div>, <p>, etc.
  }
}
```

**Edge Cases**:
- `<xray>` → HTML (no hyphen after x)
- `<X-Alert>` → Component (case-insensitive)
- `<x->` → Error (invalid component name)

**Alternatives Considered**:
- **Parse tree analysis**: Rejected - too late, creates ambiguity
- **Registered component list**: Rejected - runtime dependency, breaks parsing

---

## Self-Closing Syntax

**Decision**: Accept `/>` for all HTML elements (not just void)

**Rationale**:
- Common in JSX/React - developers expect it to work
- No harm in accepting - clear intent (no children)
- Simplifies parser logic - uniform handling
- Explicit marker for "no children expected"

**Implementation**:
```dart
// Both valid:
<div class="foo" />      // Self-closing (no children)
<div class="foo"></div>  // Explicit close (may have children)

// Void elements (both valid):
<br>       // No closing tag
<br />     // Self-closing (equivalent)
```

**Validation**:
- Self-closing elements MUST NOT have closing tag
- Self-closing elements MUST NOT have children  
- Error if both self-close and closing tag found

**Alternatives Considered**:
- **Strict void-only**: Rejected - too restrictive, breaks JSX patterns
- **Warning for non-void self-close**: Rejected - not helpful, common pattern

---

## Attribute Parsing on HTML

**Decision**: Reuse existing attribute tokenization from feature 001

**Rationale**:
- Already handles Alpine.js (`x-data`, `@click`, `:bind`)
- Already handles Livewire (`wire:click`, `wire:model.live`)
- Already handles standard attributes (`class`, `id`, `data-*`)
- Zero code duplication
- Consistent attribute handling across components and HTML

**Implementation**:
```dart
// In _lexHtmlTag():
_emitToken(TokenType.htmlTagOpen, '<$tagName');

// Lex attributes (existing code):
while (_peek() != '>' && _peek() != '/' && !_isAtEnd()) {
  _skipWhitespace();
  _lexAttribute();  // Reuses component attribute lexer
}
```

**Attribute Type Detection** (existing logic):
- `x-*` → Alpine.js attribute → `AlpineAttribute`
- `wire:*` → Livewire attribute → `LivewireAttribute`  
- `@*` → Alpine.js shorthand → `AlpineAttribute`
- `:*` → Alpine.js bind shorthand → `AlpineAttribute`
- Others → Standard attribute → `StandardAttribute`

**Alternatives Considered**:
- **Separate HTML attribute lexer**: Rejected - code duplication, inconsistent
- **Different attribute node types for HTML**: Rejected - unnecessary complexity

---

## Error Recovery Strategy

**Decision**: Unclosed tag → error + include partial node in AST

**Rationale**:
- Consistent with existing directive error handling (001)
- Partial AST allows formatters/linters to work with broken code
- Multiple errors can be reported (don't stop at first error)
- Synchronization point: next recognized token

**Error Scenarios**:

1. **Unclosed HTML Tag**:
```blade
<div class="foo">
  <p>Content
<!-- Missing </p> and </div> -->
```
→ Error: "Unclosed tag <p> at line 2"
→ Error: "Unclosed tag <div> at line 1"
→ AST: Partial HtmlElementNode with children

2. **Mismatched Tags**:
```blade
<div>
  <span>Content</div>
</span>
```
→ Error: "Expected </span>, found </div> at line 3"
→ Synchronize: Skip to next valid token

3. **Invalid Tag Name**:
```blade
<123invalid>
```
→ Error: "Invalid tag name '123invalid' at line 1"
→ Skip token, continue parsing

**Synchronization Points**:
- Blade directive (`@if`, `@foreach`, etc.)
- Component tag (`<x-component>`)
- Next HTML tag (`<div>`, `<p>`, etc.)
- End of file

**Alternatives Considered**:
- **Discard malformed nodes**: Rejected - loses information for tooling
- **Stop at first error**: Rejected - multiple errors more helpful

---

## Implementation Checklist

✅ HTML tag tokenization strategy defined
✅ Void element handling specified  
✅ HTML/Component distinction clarified
✅ Self-closing syntax rules established
✅ Attribute parsing reuse confirmed
✅ Error recovery approach designed

**Ready for Phase 1: Design & Contracts**
