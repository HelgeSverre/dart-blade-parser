# Implementation Plan: Enhanced HTML Element Parsing

**Branch**: `002-enhanced-html-parsing` | **Date**: 2025-10-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-enhanced-html-parsing/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 8. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

Enhance the existing Blade parser to properly parse HTML elements into HtmlElementNode instances instead of treating them as plain text. This includes full HTML tag tokenization in the lexer, HTML element parsing in the parser with attribute support (standard, Alpine.js, Livewire), void element recognition, self-closing syntax, and proper nesting validation. The implementation builds on the existing lexer/parser infrastructure from 001-create-a-laravel with zero new dependencies.

## Technical Context

**Language/Version**: Dart 3.0+ (latest stable) - from 001-create-a-laravel
**Primary Dependencies**: Zero external parsing libraries (pure Dart) - from 001-create-a-laravel
**Storage**: N/A (parser only)
**Testing**: Dart test package (already in use)
**Target Platform**: Pure Dart - Flutter, CLI, web compatible
**Project Type**: Single (library project)
**Performance Goals**: ≥1000 lines/sec (maintain existing), <100MB memory
**Constraints**: Zero new dependencies, backward compatibility (100 existing tests must pass)
**Scale/Scope**: Extends existing parser with HTML support - estimated 20+ new tests, ~500 LOC

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Parser-First Architecture
- ✅ Core parsing logic framework-agnostic: Extends existing lexer/parser modules
- ✅ Lexer/parser/AST as distinct modules: HTML tokenization in lexer, parsing in parser
- ✅ No UI/rendering concerns: Pure parsing logic only
- ✅ Parser self-contained: Uses existing infrastructure, no new external dependencies
- ✅ Single responsibility: Lexer tokenizes HTML, parser creates HtmlElementNode

### II. Grammar Completeness
- ✅ HTML syntax support: All standard HTML elements + void elements
- ✅ Attribute parsing: Standard, Alpine.js, Livewire (reuses existing attribute tokenization)
- ✅ Error messages: Line/column positioning for unclosed tags, mismatched tags
- ✅ Documentation: Will document HTML parsing in contracts and examples

### III. Test-First Development (NON-NEGOTIABLE)
- ✅ TDD mandatory: Contract tests → integration tests → implementation
- ✅ Test fixtures: Valid HTML, edge cases (void, self-closing, nested), malformed
- ✅ Test suite: 20+ HTML-specific tests planned
- ✅ Red-Green-Refactor: Enforce via task ordering
- ✅ Performance benchmarks: Verify no regression

### IV. Zero Dependencies Philosophy
- ✅ Pure Dart: No external libraries needed
- ✅ No new dependencies: Uses existing lexer/parser infrastructure
- ✅ Platform-agnostic: Works on Flutter, CLI, web
- ✅ No API leakage: HtmlElementNode already in public API
- ✅ Standard library: Only Dart core libraries

### V. Performance Standards
- ✅ ≥1000 lines/sec: Must maintain existing throughput
- ✅ <100MB memory: Must maintain existing limits
- ✅ Streaming support: Existing StreamingParser handles HTML nodes
- ✅ Benchmarked paths: HTML parsing will be benchmarked
- ✅ Regression tracking: Performance tests will verify no degradation

### VI. API Design & Interoperability
- ✅ Traversable AST: HtmlElementNode implements AstNode with visitor pattern
- ✅ JSON serialization: HtmlElementNode.toJson() already implemented
- ✅ Stable API: No breaking changes to existing API
- ✅ CLI interface: Existing CLI will output HTML nodes
- ✅ Programmatic + CLI: Both supported via existing infrastructure

### VII. Tooling Ecosystem
- ✅ Core parser is library: HTML parsing in core, not separate tool
- ✅ Tools are independent: Formatter (next feature) will consume HTML nodes
- ✅ No formatter logic: Pure parsing only
- ✅ No parser modifications needed: Extends existing infrastructure

**Initial Assessment**: ✅ **PASS** - No constitutional violations identified

## Project Structure

### Documentation (this feature)
```
specs/002-enhanced-html-parsing/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/src/
├── lexer/
│   ├── lexer.dart       # MODIFY: Add HTML tag tokenization
│   └── token_type.dart  # MODIFY: Add HTML token types
├── parser/
│   └── parser.dart      # MODIFY: Implement _parseHtmlElement()
└── ast/
    └── node.dart        # EXISTS: HtmlElementNode already defined

test/
├── contract/
│   └── html_contract_test.dart      # NEW: HTML API contracts
├── integration/
│   └── html_parsing_test.dart       # NEW: HTML integration tests
└── unit/
    ├── lexer/
    │   └── html_lexer_test.dart     # NEW: HTML tokenization tests
    └── parser/
        └── html_parser_test.dart    # NEW: HTML parsing tests
```

**Structure Decision**: Single project structure (library). HTML parsing extends existing lexer/parser modules without adding new directories. All HTML-specific tests follow existing test organization pattern.

## Phase 0: Outline & Research

### Research Tasks

1. **HTML Tag Tokenization Strategy**
   - Decision: State-based tokenization in existing `_LexerState` enum
   - Rationale: Consistent with existing directive/component tokenization, minimal code churn
   - Alternatives: Separate HTML lexer (rejected - unnecessary complexity)

2. **Void Element Handling**
   - Decision: Static set of void elements checked in parser
   - Rationale: Fixed HTML5 void element list, no runtime overhead
   - List: `area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr`
   - Alternatives: Dynamic detection (rejected - slower, unnecessary)

3. **HTML vs Component Detection**
   - Decision: `<x-` prefix indicates component, all others are HTML
   - Rationale: Already implemented in feature 001, unambiguous
   - Alternatives: Parse tree analysis (rejected - too late, ambiguous)

4. **Self-Closing Syntax**
   - Decision: Accept `/>` for all HTML elements (not just void)
   - Rationale: Common in JSX/React, no harm to accept
   - Alternatives: Strict void-only (rejected - too restrictive)

5. **Attribute Parsing on HTML**
   - Decision: Reuse existing attribute tokenization from feature 001
   - Rationale: Already handles Alpine.js, Livewire, standard attributes
   - Implementation: HTML parser calls existing `_lexAttribute()` method
   - Alternatives: Separate HTML attribute lexer (rejected - code duplication)

6. **Error Recovery Strategy**
   - Decision: Unclosed tag → error + include partial node in AST
   - Rationale: Consistent with existing directive error handling
   - Synchronization: Skip to next recognized token (directive, component, or HTML tag)
   - Alternatives: Discard malformed nodes (rejected - loses information)

### Output: research.md

Created at `/Users/helge/code/dart-blade-parser/specs/002-enhanced-html-parsing/research.md`

## Phase 1: Design & Contracts

### Entities (data-model.md)

**HtmlElementNode** (already exists in 001, will be populated):
- `tagName: String` - HTML element name (div, p, span, etc.)
- `attributes: Map<String, AttributeNode>` - Parsed attributes
- `children: List<AstNode>` - Child nodes
- `isSelfClosing: bool` - Used self-closing `/>` syntax
- `isVoid: bool` - Is void element (computed from tagName)
- `startPosition: Position` - Opening tag start
- `endPosition: Position` - Closing tag end (or self-close)

**Token Types** (extend existing TokenType enum):
- `htmlTagOpen` - Opening tag start: `<div`
- `htmlTagClose` - Closing tag: `</div>`
- `htmlTagSelfClose` - Self-closing: `/>`
- `htmlTagEnd` - End of opening tag: `>`

### API Contracts (contracts/)

**HTML Element Parsing Contract** (`contracts/html-parser-api.md`):

```dart
// Parse HTML element
HtmlElementNode node = parser.parse('<div class="foo">content</div>');
assert(node.tagName == 'div');
assert(node.attributes['class'].value == 'foo');
assert(node.children.length == 1);
assert(!node.isSelfClosing);
assert(!node.isVoid);

// Parse void element
HtmlElementNode br = parser.parse('<br>');
assert(br.tagName == 'br');
assert(br.isVoid == true);
assert(br.children.isEmpty);

// Parse self-closing
HtmlElementNode div = parser.parse('<div class="foo" />');
assert(div.isSelfClosing == true);
assert(div.children.isEmpty);

// Mixed attributes
HtmlElementNode mixed = parser.parse('<div class="card" x-data="{}" wire:loading>');
assert(mixed.attributes['class'] is StandardAttribute);
assert(mixed.attributes['x-data'] is AlpineAttribute);
assert(mixed.attributes['wire:loading'] is LivewireAttribute);
```

### Integration Test Scenarios (quickstart.md)

1. **Parse standard HTML with attributes** → HtmlElementNode with attributes
2. **Parse nested HTML elements** → Proper parent-child tree
3. **Parse void elements** → Void flag set, no children
4. **Parse HTML with Blade directives inside** → Mixed AST
5. **Parse self-closing HTML** → Self-closing flag set
6. **Error: unclosed HTML tag** → Error + partial AST
7. **Performance: HTML parsing throughput** → ≥1000 lines/sec

### Outputs

- `/specs/002-enhanced-html-parsing/data-model.md` - HtmlElementNode structure
- `/specs/002-enhanced-html-parsing/contracts/html-parser-api.md` - Parsing contracts
- `/specs/002-enhanced-html-parsing/quickstart.md` - Integration test scenarios
- `/CLAUDE.md` - Updated with HTML parsing tech (incremental)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
1. Load contract tests from Phase 1 → Create contract test tasks [P]
2. Load integration scenarios from quickstart.md → Create integration test tasks
3. Lexer modifications → HTML token type task, HTML tokenization task
4. Parser modifications → HTML element parsing task
5. Error handling → HTML error recovery task
6. Performance → HTML performance benchmark task

**Ordering Strategy** (TDD):
1. **Setup Phase**: Extend TokenType enum (T001)
2. **Test Phase**: Contract tests [P], Integration tests [P]
3. **Lexer Phase**: HTML tokenization in lexer (T010-T015)
4. **Parser Phase**: HTML element parsing (T016-T020)
5. **Validation Phase**: Performance benchmarks, backward compat tests (T021-T025)

**Estimated Output**: 20-25 tasks in dependency order

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following TDD cycle)
**Phase 5**: Validation (run tests, verify performance, check backward compatibility)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No violations - table empty.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning approach described (/plan command)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (no new violations)
- [x] All NEEDS CLARIFICATION resolved (none existed)
- [x] Complexity deviations documented (none - no violations)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
