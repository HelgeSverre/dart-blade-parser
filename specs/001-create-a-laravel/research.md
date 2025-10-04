# Research: Laravel Blade Template Parser

**Date**: 2025-10-04
**Feature**: Laravel Blade Template Parser
**Phase**: Phase 0 - Research

---

## Overview

This research document consolidates findings on Dart parser best practices and Laravel Blade template syntax to inform implementation decisions for the Blade parser project. All decisions align with the project constitution (Zero Dependencies, Parser-First Architecture, Test-First Development, Performance Standards).

---

## 1. Lexer/Tokenizer Architecture

### Decision: Hand-Written State Machine Lexer

**Rationale**:
- **Performance**: Meets ≥1000 lines/sec requirement without external dependencies
- **Control**: Enables context-sensitive lexing for `@` disambiguation (Blade directives vs Alpine.js event handlers vs email addresses)
- **Error Recovery**: Fine-grained control for FR-026 multi-error reporting
- **Streaming Support**: Natural fit for FR-029 incremental parsing mode

**Alternatives Considered**:
- ❌ **Regex-based** (like Laravel's BladeCompiler): Simple but poor performance, difficult error recovery
- ❌ **Parser Generators** (ANTLR/Lex): Violates constitution's Zero Dependencies principle
- ⚠️ **Parser Combinators** (PetitParser): Pure Dart but performance overhead for large files
- ✅ **Hand-Written State Machine**: Maximum control, best performance, constitutional compliance

**Implementation Pattern**: Rob Pike's Lexical Scanning approach (from Go)
- State functions return next state
- Context-sensitive state transitions
- Zero-copy token emission (store indices, defer string extraction)
- Line/column tracking for error reporting (FR-021, FR-022)

**Reference Projects**:
- Dart Analyzer lexer (sdk/pkg/analyzer/lib/src/dart/scanner/scanner.dart)
- TokenParser-dart (GitHub: DrafaKiller/TokenParser-dart)
- json_lexer (GitHub: jimsimon/json_lexer)

---

## 2. Parser Architecture

### Decision: Recursive Descent + Pratt Parsing Hybrid

**Rationale**:
- **Recursive Descent**: Natural fit for Blade's context-free structure (directives, components, nesting)
- **Pratt Parsing**: Optimal for PHP expressions within `{{ }}` and directive conditions
- **Proven**: Used by Dart analyzer itself
- **Maintainability**: Clear mapping from grammar to code
- **Error Recovery**: Easy to implement panic-mode and synchronization points (FR-026)

**Alternatives Considered**:
- ❌ **Pure Recursive Descent**: Awkward for expression operator precedence
- ❌ **Parser Combinators**: Performance overhead (PetitParser benchmarks show slower than hand-written)
- ❌ **Table-Driven LR Parser**: Too complex, harder to debug, harder to provide good error messages

**Architecture Layers**:
```
CLI (bin/blade_parser.dart)
  ↓
Public API (lib/blade_parser.dart)
  ↓
┌────────────┬────────────┐
│   Lexer    │   Parser   │
│ (Tokens)   │ (AST)      │
└────────────┴────────────┘
  ↓              ↓
Token Types   AST Nodes
                ↓
            Visitors (JSON, Traversal)
```

**Reference Implementations**:
- Dart Analyzer parser (production-quality recursive descent)
- PetitParser examples (JSON, LISP parsers - architecture study only, not dependency)
- Bob Nystrom's Pratt parser tutorial

---

## 3. AST Design

### Decision: Sealed Classes + Visitor Pattern (Dart 3.0+)

**Rationale**:
- **Type Safety**: Sealed classes enable exhaustive checking in switch expressions
- **Modern Dart**: Leverages Dart 3.0+ pattern matching capabilities
- **Visitor Pattern**: Required by constitution (FR-017)
- **JSON Serialization**: Natural fit for FR-019, FR-034
- **Maintainability**: Compiler enforces handling all node types during refactoring

**Alternatives Considered**:
- ❌ **Simple Inheritance**: No exhaustive checking, error-prone
- ❌ **Sum Types Library**: External dependency (constitutional violation)
- ❌ **Manual instanceof Checks**: No compile-time safety

**Node Hierarchy**:
```dart
sealed class AstNode {
  Position startPosition;
  Position endPosition;
  T accept<T>(AstVisitor<T> visitor);
  AstNode? parent;
  List<AstNode> children;
  Map<String, dynamic> toJson();
}

final class DocumentNode extends AstNode { ... }
final class DirectiveNode extends AstNode { ... }
final class ComponentNode extends AstNode { ... }
final class EchoNode extends AstNode { ... }
final class TextNode extends AstNode { ... }
final class HtmlElementNode extends AstNode { ... }
```

**Visitor Implementations**:
- `JsonSerializerVisitor` - FR-019 JSON serialization
- `RecursiveAstVisitor` - Tree traversal base class
- `ValidationVisitor` - Error checking (future)

**Reference**:
- Dart Analyzer AST (pkg/analyzer/lib/dart/ast/)
- Sealed classes documentation (dart.dev/language/class-modifiers#sealed)

---

## 4. Error Recovery Strategy

### Decision: Multi-Level Recovery (Panic Mode + Phrase-Level + Synchronization)

**Rationale**:
- **FR-026 Requirement**: Continue parsing after errors to find all issues
- **FR-026a Requirement**: Support Error and Warning severity levels
- **FR-026b Requirement**: Produce partial AST with error markers
- **IDE Use Case**: Tooling needs best-effort parsing even with syntax errors

**Recovery Techniques**:

| Technique | Use Case | Implementation |
|-----------|----------|----------------|
| **Panic Mode** | Unexpected tokens | Skip to synchronization point (next directive start) |
| **Phrase-Level** | Missing delimiters | Insert/report missing `@endif`, continue parsing |
| **Error Productions** | Known patterns | Detect deprecated syntax, emit warnings |
| **Synchronization Points** | Major errors | Directive starts, component tags prevent cascading errors |

**Error Message Quality** (FR-022):
```
❌ Bad: "Unexpected token"
✅ Good: "Unclosed @if directive starting at line 15, column 3. Expected @endif before end of file."
✅ Better: Include hints for common fixes
```

**Reference**:
- Compiler Design Error Recovery (tutorialspoint.com)
- Dart YAML parser error recovery discussion (GitHub issue #102)

---

## 5. Performance Optimization

### Decision: Zero-Copy Tokenization + Static Typing + Benchmarking

**Rationale**:
- **FR-027**: ≥1000 lines/sec throughput
- **FR-028**: <100MB memory for <5000 line files
- **FR-030**: No degradation up to 20 nesting levels

**Optimization Techniques**:

1. **String Handling**: Store indices instead of substrings
   - Dart's `String.substring()` is O(n) with allocation
   - Defer string extraction until needed
   - Use `StringBuffer` for accumulation

2. **Avoid Dynamic Types**: Use static types everywhere
   - `dynamic` incurs runtime type checking overhead
   - Enables compile-time optimizations

3. **List Pre-Sizing**: Pre-allocate when size is known
   - Avoid repeated reallocation during growth

4. **Constant Folding**: Pre-compute constants outside loops

**Benchmarking Tools**:
- Dart `benchmarking` package
- Dart Observatory for heap snapshots
- DevTools for CPU/memory profiling

**Performance Targets**:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Lines/sec | ≥1000 | `lines / parseTime` |
| Memory | <100MB for 5k lines | Observatory heap snapshot |
| Latency (10k lines) | <10s | Wall-clock time |
| Nesting (20 levels) | <10% slowdown | Flat vs nested comparison |

**Reference**:
- "Adventures in Substrings" (mrale.ph - Dart performance)
- Dart Performance Optimization (medium.com/@jigejiaoxue)

---

## 6. Streaming/Incremental Parsing

### Decision: Dual-Mode Parser (Full + Streaming)

**Rationale**:
- **FR-029 Requirement**: Support both full-parse and opt-in streaming mode
- **Use Cases**: Full parse for IDE features, streaming for large files
- **Memory**: Streaming reduces footprint for >10k line files

**Implementation Approaches**:

**Full Parse Mode** (default):
```dart
ParseResult parse(String input);
```
- Entire file tokenized and parsed into memory
- Complete AST available for traversal

**Streaming Mode** (opt-in):
```dart
Stream<AstNode> parseStreaming(Stream<String> chunks);
```
- Process file incrementally
- Emit complete AST nodes as soon as parseable
- Buffer incomplete constructs (e.g., @if...@endif)

**Challenges for Blade**:
1. **Cross-Section Dependencies**: `@section` in one file, `@yield` in another
2. **Component Resolution**: Need full template graph
3. **Expression Boundaries**: Don't break mid-expression

**Solution**: Emit independent nodes immediately (text, closed directives), buffer cross-references for later resolution

**Reference**:
- Dart Streams documentation (dart.dev/libraries/async/using-streams)
- File streaming patterns (Stack Overflow: dart async file processing)
- XML package SAX-style events (pub.dev/packages/xml)

---

## 7. Blade Grammar Coverage

### Complete Directive List (75+ directives)

**✅ Already in Spec (45 directives)**:
- Control: @if, @elseif, @else, @endif, @unless, @endunless, @isset, @empty, @switch, @case, @break, @default, @endswitch
- Loops: @for, @endfor, @foreach, @endforeach, @forelse, @endforelse, @while, @endwhile, @continue, @break
- Inheritance: @extends, @section, @endsection, @yield, @parent, @show, @overwrite
- Stacks: @push, @endpush, @prepend, @endprepend, @stack
- Components: @component, @endcomponent, @slot, @endslot, @props, @aware, @once, @endonce
- Includes: @include, @includeIf, @includeWhen, @includeUnless, @includeFirst, @each
- Special: @php, @endphp, @verbatim, @endverbatim

**❌ Missing from Spec (30+ directives)**:

**Authentication & Authorization**:
- @auth / @endauth, @guest / @endguest
- @can / @endcan, @cannot / @endcannot, @canany / @endcanany

**Environment & Debugging**:
- @env / @endenv, @production / @endproduction
- @session / @endsession (Laravel 10.38+)
- @dd, @dump

**Validation**:
- @error / @enderror

**Section Conditionals**:
- @hasSection / @endif, @sectionMissing / @endif

**HTML Attributes (Laravel 8.35+)**:
- @class, @style, @checked, @selected, @disabled, @readonly, @required

**Assets & Data**:
- @json, @method, @csrf, @vite (Laravel 9.19+)

**Advanced Stacks**:
- @pushOnce / @endPushOnce, @pushIf, @prependOnce / @endPrependOnce

**Translation** (deprecated but functional):
- @lang, @choice

**Modern Features**:
- @inject (service injection)
- @fragment / @endfragment (Laravel 11+)
- @use (Laravel 11.30+)

**Recommendation**: Extend spec to include these directives or mark as out-of-scope for initial release.

---

## 8. Blade Syntax Edge Cases

### Critical Parsing Edge Cases

**1. @ Symbol Disambiguation**:
- **@ at line start or after whitespace** → Blade directive
- **@ within HTML attribute** → Alpine.js event listener (e.g., `@click`)
- **@ in email addresses** → Literal text (e.g., `user@example.com`)
- **Historical bug** (Laravel <5.4): Email addresses incorrectly parsed as directives

**2. @verbatim Blocks**:
- Content is literal text, NOT parsed as Blade
- Cannot be nested: `@verbatim @verbatim @endverbatim @endverbatim` is invalid
- May contain `{{ }}` that should NOT be interpreted as echo
- Edge case: Unpaired @verbatim/@endverbatim causes errors

**3. Blade Comments**:
- Syntax: `{{-- comment --}}`
- Cannot be nested
- **Bug**: PHP code inside comments (e.g., `{{-- ?> --}}`) can break compilation
- **Bug**: Long comments without PHP/Blade cause length calculation errors
- Different from HTML comments `<!-- -->` (client-side vs server-side)

**4. Echo Statement Edge Cases**:
- Three types: `{{ }}` (escaped), `{{{ }}}` (escaped legacy, deprecated), `{!! !!}` (unescaped)
- **Bug**: Ternary with 'or' keyword breaks regex: `{{ $x ? 'or' : 'other' }}`
- Workaround: Use parentheses: `{{ ($x ? 'or' : 'other') }}`

**5. Directive Syntax Variants**:
- Inline conditions: `@continue($user->type == 1)`, `@break($user->id == 5)`
- No space required after directive name if followed by `(`
- Spacing required if next char is not `(`, line break, or null

**6. Component Slots**:
- Modern syntax: `<x-slot:name>` (Laravel 7+)
- Legacy syntax: `<x-slot name="name">` (still supported)
- Default slot: Named "default" in AST (per spec clarification)
- Slots can have attributes: `<x-slot:header class="bold">`

**7. Alpine.js Integration**:
- Double colon escape: `::href` tells Blade to skip processing
- `@click` vs `@directive` disambiguation by context (attribute vs line start)

**8. Complex Expression Limitations**:
- Laravel docs: "Blade attempts to pass a complex expression to the directive may cause unexpected failures"
- Nested function calls with array parameters can break regex parser
- Recommendation: Keep directive expressions simple

---

## 9. Testing Strategy

### Test Categories (per Constitution)

**Contract Tests** (test/contract/):
- Token types and structure
- Parser API contracts
- AST node interfaces
- Prevent breaking changes

**Unit Tests** (test/unit/):
- Lexer state transitions
- Parser directive handling
- AST node construction
- Visitor implementations

**Integration Tests** (test/integration/):
- Full parse workflow
- Streaming parse workflow
- CLI interface
- Real-world Blade templates

**Performance Tests** (test/performance/):
- Lines/sec benchmarks
- Memory usage profiling
- Nesting depth impact
- Large file handling

**Test Fixtures** (test/fixtures/):
- **valid/**: Correct Blade syntax for all directives
- **invalid/**: Malformed templates for error recovery testing
- **edge_cases/**: @ disambiguation, @verbatim edge cases, comment bugs, etc.

### Coverage Requirements (Constitution)
- Minimum 90% coverage for core parsing logic
- All 75+ directives covered
- All edge cases from research covered
- Performance benchmarks for typical and large files

---

## 10. Implementation Recommendations

### Architectural Decisions

**ADR-001: Hand-Written Lexer over Parser Generators**
- Decision: Hand-written state machine
- Rationale: Performance, zero dependencies, context-sensitive lexing
- Trade-off: More code to maintain vs full control

**ADR-002: Sealed Classes + Visitor Pattern for AST**
- Decision: Dart 3.0+ sealed classes with visitor pattern
- Rationale: Type safety, exhaustive checking, maintainability
- Trade-off: Requires Dart 3.0+ (not a constraint)

**ADR-003: Recursive Descent + Pratt Parsing Hybrid**
- Decision: RD for structure, Pratt for expressions
- Rationale: Natural fit for Blade grammar, proven pattern
- Trade-off: Two parsing techniques vs optimal handling of each construct

**ADR-004: Dual-Mode Parsing (Full + Streaming)**
- Decision: Two parse methods with different memory/performance characteristics
- Rationale: FR-029 requirement, different use cases
- Trade-off: Two code paths to maintain vs optimal performance for each case

### Common Pitfalls to Avoid

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Regex-based lexing | Poor performance | Hand-written state machine |
| Not tracking positions | No error locations | Track line/column in lexer |
| String allocations | Memory bloat | Store indices, lazy extraction |
| Dynamic types | Runtime overhead | Static types everywhere |
| No error recovery | First error stops | Panic mode + synchronization |
| Ignoring UTF-8 | International content breaks | Proper UTF-8 handling (FR-042) |
| Single-pass parsing | Forward references break | Two-pass or symbol table (if needed) |
| Cascading errors | Hundreds of errors from one mistake | Synchronization points |
| Premature optimization | Wasted effort | Benchmark first, optimize hot paths |

---

## 11. Reference Projects

### Primary References

**Study for Architecture** (not dependencies):
1. **Dart Analyzer** (dart-lang/sdk/pkg/analyzer)
   - Focus: AST design, visitors, error recovery, production quality
   - Key files: ast.dart, visitor.dart, scanner.dart, token.dart

2. **PetitParser** (petitparser/dart-petitparser)
   - Focus: Profiling tools, composable design, examples
   - Note: Study architecture only, do not use as dependency

3. **TokenParser-dart** (DrafaKiller/TokenParser-dart)
   - Focus: Grammar definition, error reporting, debugging

**Study for Patterns**:
4. **Laravel BladeCompiler** (laravel/framework - PHP)
   - Focus: Comprehensive directive coverage, edge case handling
   - Note: Regex-based approach (avoid), but good directive reference

5. **Stillat Blade Parser** (stillat/blade-parser - PHP and TypeScript)
   - Focus: Error recovery, real-world edge cases
   - Note: TypeScript version may inform Dart patterns

### Documentation References

**Dart**:
- Dart Language Tour (dart.dev/language)
- Dart Streams (dart.dev/libraries/async/using-streams)
- Sealed Classes (dart.dev/language/class-modifiers#sealed)

**Parser Theory**:
- Rob Pike - Lexical Scanning in Go
- Bob Nystrom - Pratt Parsers (stuffwithstuff.com)
- matklad - Simple but Powerful Pratt Parsing

**Laravel Blade**:
- Laravel 12.x Blade Docs (laravel.com/docs/12.x/blade)
- Laravel 11.x Blade Docs (laravel.com/docs/11.x/blade)
- Blade Directives Reference (blade-directives.vercel.app)

**Performance**:
- Adventures in Substrings (mrale.ph/blog/2016/11/23/making-less-dart-faster.html)
- Dart Performance Optimization (medium.com/@jigejiaoxue)

---

## 12. Next Steps (Phase 1)

Based on this research, proceed to Phase 1:

1. **Create data-model.md**: Define entity models for Token, AstNode, ParseError, ParseResult
2. **Generate contracts/**: OpenAPI-style contracts for parser API (if applicable for library)
3. **Create contract tests**: Failing tests for token types, parser API, AST node types
4. **Create quickstart.md**: Example usage and integration test scenarios
5. **Update CLAUDE.md**: Add tech stack decisions, architecture, recent changes

All Phase 1 outputs should reference this research document for rationale.

---

**Research Status**: ✅ Complete
**All NEEDS CLARIFICATION Resolved**: ✅ Yes
**Ready for Phase 1**: ✅ Yes
