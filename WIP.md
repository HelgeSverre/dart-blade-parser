# WIP

## Malformed Input Recovery Plan (2026-03-11)

### Goal

Handle malformed but real-world Blade templates with best-effort formatting instead of failing fast, while avoiding large semantic rewrites in regions the parser no longer understands confidently.

### Decision

Adopt a hybrid recovery model:

1. Always format when parsing still produces an AST.
2. Keep diagnostics separate from formatting success.
3. Prefer local repair at trusted boundaries.
4. Preserve damaged spans verbatim when confidence drops too far.

This matches the current architecture better than a full parser rewrite.

### Research Summary

The strongest adjacent approaches all converge on the same pattern:

- `CPCT+` and related LR recovery work show that bounded local repair reduces cascading syntax errors better than panic-skipping.
  - References:
    - https://soft-dev.org/pubs/html/diekmann_tratt__dont_panic/
    - https://arxiv.org/abs/2001.04001
- `PEG` recovery is a close fit for a handwritten recursive-descent parser.
  - References:
    - https://arxiv.org/abs/1905.02145
    - https://arxiv.org/abs/1806.11150
- `HTML5` parsing is the right model for broken nested markup: stack-based local repair, implied closes, and ancestor matching.
  - Reference:
    - https://html.spec.whatwg.org/multipage/parsing.html
- Modern tooling (`Tree-sitter`, `Lezer`, `Roslyn`, `rust-analyzer`, `Biome`) keeps malformed input in the tree using explicit error or bogus nodes, then formats valid regions normally and degraded regions conservatively.
  - References:
    - https://tree-sitter.github.io/tree-sitter/using-parsers/queries/1-syntax.html
    - https://lezer.codemirror.net/docs/guide/#error-recovery
    - https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/work-with-syntax
    - https://rust-analyzer.github.io/book/contributing/syntax.html
    - https://biomejs.dev/internals/architecture/
- Island grammar and bounded-seas work are especially relevant for Blade because malformed input often appears inside otherwise-valid HTML or directive structure.
  - References:
    - https://doi.org/10.1016/S0167-6423(00)00012-1
    - https://doi.org/10.1016/j.scico.2012.07.004

### Current Architectural Gap

The parser already advertises partial AST support:

- `lib/src/error/parse_result.dart`

But the formatter still treated any parse error as fatal:

- `lib/src/formatter/formatter.dart`

The repo already had useful pieces for a tolerant pipeline:

- `lib/src/ast/node.dart`
  - existing `ErrorNode`
- `lib/src/formatter/formatter_visitor.dart`
  - raw source output support via `_outputRaw(...)`

### Proposed Architecture

#### Phase 1

Relax the formatter contract:

- Format whenever parsing produced an AST.
- Report diagnostics through `FormatResult` instead of throwing by default.
- Preserve explicit error nodes as source text instead of emitting synthetic HTML comments.

This phase is intentionally small and low-risk. It does not attempt major parser repair yet.

#### Phase 2

Add local HTML and Blade recovery:

- HTML close-stack repair:
  - if `</tag>` matches an ancestor, auto-close locally and reprocess
- Blade closer recovery:
  - treat unexpected `@end...` tokens as synchronization points
- Tag-head fallback:
  - stop skipping malformed tag-head tokens individually
  - accumulate opaque malformed chunks until `>` or `/>`

#### Phase 3

Promote recovery into the tree:

- add explicit recovery-bearing nodes for malformed tag-head chunks, stray closers, and skipped regions
- format recovered nodes conservatively
- round-trip opaque regions verbatim

### Phase 1 Implementation

Implemented:

- `BladeFormatter.format(...)` now uses best-effort formatting whenever parsing returns an AST.
- `formatWithResult(...)` now returns formatted output plus parser diagnostics for malformed input.
- `formatRange(...)` and `formatWithCursor(...)` now follow the same best-effort contract instead of hard-failing on parse errors when an AST exists.
- `FormatterVisitor.visitError(...)` now preserves source-backed error content instead of inventing `<!-- ERROR: ... -->` output.

Files changed:

- `lib/src/formatter/formatter.dart`
- `lib/src/formatter/formatter_visitor.dart`

### Phase 1 Test Coverage

Added or updated tests to lock in the new contract:

- malformed full-document formatting is best-effort rather than exception-based
- malformed range formatting returns diagnostics instead of throwing
- malformed cursor formatting returns diagnostics and a valid cursor position
- stress cases for unclosed and mismatched HTML tags now assert recovered formatted output

Relevant files:

- `test/formatter/formatter_test.dart`
- `test/formatter/formatter_stress_test.dart`
- `test/unit/formatter/range_test.dart`
- `test/unit/formatter/cursor_test.dart`

### Expected Immediate Payoff

- real malformed files no longer fail the formatter outright
- intentionally-invalid stress fixtures can still be formatted and re-formatted idempotently
- editor integrations can choose between plain formatting output and diagnostics via `FormatResult`

### Remaining Risks

- some malformed structures still recover by inference rather than source-preserving fallback
- tag-head recovery is still weak because malformed attribute regions are skipped structurally rather than captured explicitly
- directive recovery is still broader than ideal and can still cascade in nested mixed HTML/Blade cases

### Phase 2 Slice 1 Implementation

Implemented:

- HTML closing-tag recovery in `lib/src/parser/parser.dart`
  - ancestor closing tags now auto-close the current element locally instead of collapsing the whole subtree
  - stray closing tags inside an element are consumed as local errors so later valid siblings can still parse
  - top-level stray closing tags now produce explicit diagnostics

Tests added:

- `test/unit/parser/html_element_parser_test.dart`
  - ancestor closer auto-close recovery
  - stray closer consumption without subtree collapse
- `test/formatter/formatter_stress_test.dart`
  - formatter preserves best-effort output when stray closing tags appear inside otherwise-valid HTML

Deferred:

- malformed tag-head raw capture
  - this was deferred until lexer support existed for opaque malformed tag-head spans

### Phase 2 Slice 2 Implementation

Implemented:

- lexer-backed malformed tag-head preservation
  - added an opaque `tagHeadRaw` token for malformed tag-head spans that cannot be classified safely as attributes or directives
  - fixed attribute token start offsets so malformed spans no longer smear position data onto following valid attributes
- parser/AST preservation
  - added `TagHeadRaw` so malformed chunks survive parsing in source order
  - broadened tag-head preservation from "structural directives only" to "any source-order/recovery-sensitive tag-head content"
- formatter preservation
  - malformed tag-head chunks now round-trip verbatim in best-effort formatting instead of being dropped

Tests added:

- lexer regression for malformed raw chunks and correct following-attribute offsets
- parser regressions for HTML and component tag heads containing malformed raw chunks
- formatter regression asserting malformed tag-head chunks survive best-effort output

### Phase 3 Implementation (Recovery Nodes)

Implemented:

- `RecoveryNode` AST node for explicit recovery spans
  - stores verbatim `content` and human-readable `reason`
  - accepted by `visitRecovery` on `AstVisitor`
- Parser emits `RecoveryNode` at three recovery sites:
  - stray HTML closing tags (e.g. `</bogus>` inside `<span>`)
  - top-level stray closing tags and void-element closers
  - unclosed directive boundaries (`@if` without `@endif`, etc.)
- Formatter outputs `RecoveryNode` content verbatim
- All recovery sites are idempotent under re-formatting

Files changed:

- `lib/src/ast/node.dart`
- `lib/src/ast/visitor.dart`
- `lib/src/parser/parser.dart`
- `lib/src/formatter/formatter_visitor.dart`
- `test/unit/ast/recovery_node_test.dart` (new)
- `test/unit/parser/recovery_node_parser_test.dart` (new)
- `test/unit/formatter/recovery_node_formatter_test.dart` (new)

### Next Recommended Work

1. Add explicit recovery nodes for ancestor-close auto-repair (currently emits error + returns partial node, but no `RecoveryNode` in the tree marking the implied close).
2. Promote `TagHeadRaw` malformed chunks to use `RecoveryNode` for consistency.
3. Add confidence levels to `RecoveryNode` so the formatter can choose between verbatim and conservative reformatting.
