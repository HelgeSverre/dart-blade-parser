# Phase 0: Research & Technical Decisions

## Research Context
This document captures technical research and decisions for implementing HTML element parsing in the Blade parser. All requirements are well-specified in spec.md with no ambiguities requiring clarification.

## Technical Decisions

### 1. HTML Tag Tokenization Strategy

**Decision**: Extend existing lexer with state-based HTML tag recognition

**Rationale**:
- Existing lexer already handles Blade directives with state machine approach
- HTML tags require similar lookahead: `<` could be HTML tag, component tag (`<x-`), or plain text
- State transitions: text → htmlTagOpen (`<tag`) → htmlTagName → htmlAttribute* → htmlTagClose (`>` or `/>`)
- Minimal changes to existing token stream architecture

**Alternatives Considered**:
- Separate HTML lexer: Rejected due to complexity of coordinating two lexers
- Regex-based parsing: Rejected per constitution (performance concerns, hard to maintain)
- Character-by-character parsing: Current approach (fits existing pattern)

**Implementation Notes**:
- Add token types: htmlTagOpen, htmlTagName, htmlTagClose, htmlSelfClose, htmlClosingTagStart
- Reuse existing attribute tokenization (already handles Alpine.js, Livewire patterns)
- Maintain position tracking for all tokens (existing Position class)

### 2. Void Element Recognition

**Decision**: Static Set<String> of HTML5 void elements in parser

**Rationale**:
- HTML5 spec defines exactly 14 void elements (area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr)
- List is stable (HTML5 spec frozen for these)
- Fast O(1) lookup during parsing
- Clear error messages when void element has closing tag or children

**Alternatives Considered**:
- Runtime configuration: Rejected (unnecessary complexity, spec is stable)
- Allow void elements to self-close: Accepted (HTML5 allows `<br>` and `<br />`)

**Implementation Notes**:
```dart
static const Set<String> _voidElements = {
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
  'link', 'meta', 'param', 'source', 'track', 'wbr'
};
```

### 3. Attribute Categorization

**Decision**: Pattern-based classification during attribute parsing

**Rationale**:
- AttributeNode types already exist (StandardAttribute, AlpineAttribute, LivewireAttribute)
- Patterns are deterministic:
  - Alpine.js: starts with `x-`, `@`, or `:`
  - Livewire: starts with `wire:`
  - Standard: everything else
- Classification happens at parse time, stored in AST type system

**Alternatives Considered**:
- Post-parse classification: Rejected (requires second pass, breaks single-pass architecture)
- Single AttributeNode type with category field: Rejected (loses type safety, visitor pattern benefits)

**Implementation Notes**:
- Alpine.js shorthand: `@click` → `x-on:click`, `:class` → `x-bind:class`
- Livewire modifiers: `wire:model.defer` → attribute name includes modifier
- Boolean attributes: `disabled` → value is empty string or null

### 4. Tag Matching & Error Recovery

**Decision**: Stack-based tag tracking with partial AST on error

**Rationale**:
- Stack tracks open tags during parsing: push on `<tag>`, pop on `</tag>`
- On mismatch: generate error, return partial AST to that point
- Multiple errors collected (don't stop at first)
- Enables syntax highlighting/LSP to work on invalid documents

**Alternatives Considered**:
- Panic mode recovery: Too aggressive, loses too much context
- Stop at first error: Rejected (poor developer experience)
- Error node injection: Accepted (ErrorNode already exists in AST)

**Implementation Notes**:
```dart
// Tag stack entry
class _TagStackEntry {
  final String tagName;
  final Position startPosition;
  _TagStackEntry(this.tagName, this.startPosition);
}

// Error collection
final errors = <ParseError>[];
```

### 5. HTML vs Blade Component Distinction

**Decision**: Check for `x-` prefix followed by hyphen during tag name parsing

**Rationale**:
- Blade component convention: `<x-component-name>`
- HTML elements: never start with `x-` followed by hyphen
- Simple prefix check during tag name scanning
- Existing ComponentNode handles Blade components

**Alternatives Considered**:
- Registry of known HTML elements: Rejected (maintenance burden, doesn't handle custom elements)
- Case-sensitive check: Rejected (HTML is case-insensitive)

**Implementation Notes**:
- Tag name `x-button` → ComponentNode
- Tag name `div`, `Div`, `DIV` → HtmlElementNode (normalize to lowercase)
- Custom elements (`my-element`) → HtmlElementNode (HTML5 allows this)

### 6. Self-Closing Syntax

**Decision**: Support `<tag />` for all elements, track via isSelfClosing flag

**Rationale**:
- JSX/React developers expect self-closing syntax
- HTML5 allows `<br />` (optional for void elements)
- Framework components commonly use self-closing: `<Component />`
- Parser tracks intent: `<div />` (self-closed) vs `<div></div>` (explicit close)

**Alternatives Considered**:
- Restrict to void elements: Rejected (too restrictive, JSX compatibility)
- Treat as parse error: Rejected (valid HTML5)

**Implementation Notes**:
- Self-closing void element: `<br />` → isVoid=true, isSelfClosing=true, children=[]
- Self-closing normal element: `<div />` → isVoid=false, isSelfClosing=true, children=[]
- Normal element: `<div></div>` → isVoid=false, isSelfClosing=false, children=[...]

### 7. Performance Strategy

**Decision**: Maintain single-pass parsing with minimal allocations

**Rationale**:
- Constitution mandates ≥1000 lines/sec
- Current parser already achieves this for Blade directives
- HTML parsing integrates into existing parse loop (no additional passes)
- Reuse existing Position, Token, AstNode allocations where possible

**Alternatives Considered**:
- Two-pass parsing: Rejected (performance hit)
- Lazy parsing: Not applicable (need full AST immediately)

**Implementation Notes**:
- Benchmark: test/performance/html_parsing_benchmark_test.dart
- Target: 1000+ lines/sec for mixed Blade/HTML templates
- Memory: Use const for static data (_voidElements Set)
- String interning: Dart runtime handles this

### 8. Position Tracking

**Decision**: Track opening `<` and closing `>` or `/>` positions

**Rationale**:
- Existing Position class tracks line, column, offset
- HtmlElementNode.startPosition → opening `<` location
- HtmlElementNode.endPosition → closing `>` or `/>` location
- Enables precise error messages and source mapping

**Implementation Notes**:
- Opening tag: capture position before consuming `<`
- Closing tag: capture position after consuming `>`
- Self-closing: endPosition is after `/>`

### 9. Streaming Mode Compatibility

**Decision**: HTML parsing integrates into existing streaming parser

**Rationale**:
- StreamingParser already exists (lib/src/streaming/streaming_parser.dart)
- HTML elements parsed same way as Blade directives (token-based)
- No lookahead beyond current token (streaming-compatible)
- Partial results emitted as tokens arrive

**Implementation Notes**:
- Streaming parser calls same _parseHtmlElement() method
- Tag stack maintained across chunks
- Errors collected and emitted with partial AST

## Best Practices Applied

### Dart 3.0+ Patterns
- Sealed class hierarchy for AttributeNode (type exhaustiveness)
- Final classes for concrete nodes (optimization)
- Const constructors where applicable (performance)
- Null safety throughout (required by Dart 3.0)

### Testing Strategy (TDD)
1. Contract tests: HtmlElementNode API, AttributeNode types
2. Integration tests: Full HTML documents, mixed Blade/HTML
3. Unit tests: Tag matching, attribute parsing, error cases
4. Performance tests: Throughput benchmarks, memory profiling

### Error Message Clarity
- Format: "Unclosed <tag> at line X, column Y"
- Format: "Expected </expected>, found </actual> at line X, column Y"
- Format: "Invalid tag name: <name> at line X, column Y"
- Include context: show surrounding code snippet where applicable

## Open Questions
None - all requirements fully specified in spec.md.

## References
- HTML5 Specification: https://html.spec.whatwg.org/multipage/syntax.html#void-elements
- Alpine.js Directives: https://alpinejs.dev/directives
- Livewire Directives: https://livewire.laravel.com/docs/wire-navigate
- Dart 3.0 Language Features: https://dart.dev/language
- Existing Blade Parser: lib/src/parser/parser.dart (reference implementation)

## Summary
All technical decisions support constitutional requirements:
- ✅ Zero new dependencies (pure Dart)
- ✅ Performance targets (≥1000 lines/sec)
- ✅ Single-pass architecture
- ✅ Existing AST/visitor patterns maintained
- ✅ TDD-compatible design
- ✅ Platform-agnostic implementation
