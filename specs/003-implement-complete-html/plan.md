
# Implementation Plan: Complete HTML Element Parsing

**Branch**: `003-implement-complete-html` | **Date**: 2025-10-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-implement-complete-html/spec.md`

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
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code, or `AGENTS.md` for all other agents).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Implement complete HTML5-compliant element parsing in the Blade parser. Currently, HTML tags like `<div class="foo">` are incorrectly parsed as TextNode instead of proper HtmlElementNode instances. This feature will add full HTML element recognition with tag matching, attribute categorization (standard/Alpine/Livewire), void element handling, self-closing syntax support, comprehensive error reporting, and position tracking - all while maintaining ≥1000 lines/sec performance and zero new dependencies.

## Technical Context
**Language/Version**: Dart 3.0+ (SDK: '>=3.0.0 <4.0.0')
**Primary Dependencies**: Zero external parsing dependencies (pure Dart standard library per constitution)
**Storage**: N/A (parser operates in-memory on source text)
**Testing**: Dart test framework (contract, integration, unit, performance benchmarks)
**Target Platform**: Multi-platform (Flutter, Dart CLI, web) - pure Dart implementation
**Project Type**: Single library project
**Performance Goals**: ≥1000 lines/sec parsing speed (constitutional requirement)
**Constraints**: <100MB memory for typical files (<10k lines), streaming mode compatible, no performance degradation from current baseline
**Scale/Scope**: HTML5 element parsing (void elements, attributes, nesting, error recovery), Alpine.js/Livewire attribute categorization, maintain 100+ existing Blade directive tests

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Parser-First Architecture** ✅
- HTML parsing extends existing lexer/parser modules (lib/src/lexer, lib/src/parser)
- HtmlElementNode already exists in AST (lib/src/ast/node.dart)
- No UI/rendering concerns - pure parsing logic
- Clear separation: lexer tokenization → parser tag matching → AST generation

**II. Grammar Completeness** ✅
- HTML element support adds to existing Blade directive grammar
- All HTML5 void elements explicitly listed
- Alpine.js and Livewire attribute patterns defined
- Error messages specify format with line/column positioning
- Feature fully documented in spec with examples

**III. Test-First Development (NON-NEGOTIABLE)** ✅
- Plan includes contract test generation (Phase 1)
- 10 acceptance scenarios defined in spec → integration tests
- Edge cases documented → edge case tests
- TDD order enforced in task planning (Phase 2)
- Performance benchmarks required (existing infrastructure in test/performance/)

**IV. Zero Dependencies Philosophy** ✅
- Pure Dart implementation (spec FR-037)
- No new dependencies (pubspec.yaml remains dependency-free)
- Platform-agnostic (FR-036: Flutter, CLI, web)
- Only Dart standard library allowed

**V. Performance Standards** ✅
- ≥1000 lines/sec requirement (FR-032, constitutional mandate)
- <100MB memory for typical files (FR-033)
- No degradation from current baseline (FR-034)
- Streaming mode compatibility (FR-035)
- Existing benchmarks in test/performance/ will validate

**VI. API Design & Interoperability** ✅
- HtmlElementNode already implements visitor pattern (visitHtmlElement)
- JSON serialization required (FR-030, already in toJson())
- Public API stable (extends existing AST, no breaking changes)
- Backward compatibility: all 100+ existing tests must pass (FR-038)

**VII. Tooling Ecosystem** ✅
- Parser remains library; no formatter/linter logic added
- HTML parsing is core parser concern, not external tool
- AST consumers unchanged (visitor pattern maintained)

**GATE STATUS: PASS** ✅ - All constitutional requirements satisfied. No violations to document.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── blade_parser.dart           # Public API
└── src/
    ├── ast/
    │   ├── node.dart            # HtmlElementNode, AttributeNode (existing)
    │   ├── visitor.dart         # Visitor pattern (existing)
    │   └── json_serializer.dart # JSON export (existing)
    ├── lexer/
    │   ├── lexer.dart           # Will add HTML tag tokenization
    │   ├── token.dart           # Token structure (existing)
    │   ├── token_type.dart      # Will add HTML token types
    │   └── position.dart        # Position tracking (existing)
    ├── parser/
    │   ├── parser.dart          # Will add _parseHtmlElement()
    │   └── expression_parser.dart # Expression parsing (existing)
    ├── error/
    │   ├── parse_error.dart     # Error types (existing)
    │   └── parse_result.dart    # Result wrapper (existing)
    └── streaming/
        └── streaming_parser.dart # Streaming support (existing)

test/
├── contract/
│   ├── html_element_contract_test.dart    # NEW: HTML element API tests
│   └── html_attribute_contract_test.dart  # NEW: Attribute API tests
├── integration/
│   ├── html_parsing_test.dart             # NEW: HTML scenarios
│   └── mixed_blade_html_test.dart         # NEW: Blade+HTML integration
├── unit/
│   └── parser/
│       └── html_element_parser_test.dart  # NEW: HTML parsing unit tests
└── performance/
    └── html_parsing_benchmark_test.dart   # NEW: HTML performance tests
```

**Structure Decision**: Single library project. All HTML parsing logic integrates into existing lexer/parser modules. AST nodes (HtmlElementNode, AttributeNode types) already exist. New test files focus on HTML-specific scenarios while maintaining existing Blade directive test coverage.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
1. Load `.specify/templates/tasks-template.md` as base template
2. Generate contract test tasks from `contracts/html_element_api.md`:
   - HtmlElementNode constructor test [P]
   - HtmlElementNode visitor pattern test [P]
   - HtmlElementNode JSON serialization test [P]
   - Parser integration tests for HTML recognition [P]
   - Error handling contract tests [P]
   - Performance contract tests [P]
3. Generate implementation tasks from `research.md` decisions:
   - Extend TokenType enum with HTML token types
   - Add void elements Set to parser
   - Implement HTML tag tokenization in lexer
   - Implement _parseHtmlElement() in parser
   - Implement tag matching/stack tracking
   - Implement attribute categorization logic
   - Implement error generation for HTML violations
4. Generate integration tests from `quickstart.md` scenarios:
   - Simple HTML element parsing test
   - Void element test
   - Self-closing element test
   - Alpine.js attributes test
   - Livewire attributes test
   - Nested HTML test
   - Mixed Blade/HTML test
   - Boolean attributes test
   - Error scenarios test
5. Generate unit tests for edge cases from spec.md:
   - Tag name normalization
   - Case-insensitive matching
   - Multiple error collection
   - Partial AST on error
   - Streaming mode compatibility

**Ordering Strategy**:
1. **Phase 1: Contract Tests** (must fail initially per TDD)
   - All contract tests in parallel [P]
   - Validates API surface before implementation
2. **Phase 2: Token Extension** (foundation)
   - Add HTML TokenType values
   - Update lexer state machine
3. **Phase 3: Lexer Implementation** (tokenization)
   - HTML tag open/close recognition
   - Tag name scanning
   - Attribute tokenization (reuse existing)
4. **Phase 4: Parser Implementation** (parsing)
   - _parseHtmlElement() method
   - Tag stack tracking
   - Tag matching logic
   - Attribute categorization
   - Void element validation
5. **Phase 5: Error Handling** (robustness)
   - Unclosed tag errors
   - Mismatched tag errors
   - Void element errors
   - Invalid tag name errors
   - Partial AST generation
6. **Phase 6: Integration Tests** (TDD verification)
   - Run all contract tests (should pass now)
   - Run quickstart scenarios
   - Run edge case tests
7. **Phase 7: Performance Validation** (constitutional requirement)
   - Throughput benchmarks
   - Memory profiling
   - Streaming mode tests
8. **Phase 8: Backward Compatibility** (safety)
   - Run existing 100+ Blade tests
   - Verify no regressions

**Parallelization Opportunities**:
- All contract test tasks can run in parallel [P]
- Lexer and parser changes are sequential (dependency chain)
- Integration test execution can be parallel [P]
- Unit test execution can be parallel [P]

**Estimated Output**: 35-40 numbered tasks in tasks.md
- ~6 contract test tasks
- ~8 implementation tasks
- ~10 integration test tasks
- ~8 unit test tasks
- ~4 performance/validation tasks
- ~2 documentation/cleanup tasks

**Task Complexity**:
- Small tasks: Token enum addition, Set creation (~15 min)
- Medium tasks: Lexer state changes, test writing (~30-60 min)
- Large tasks: _parseHtmlElement() implementation (~2-3 hours)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No constitutional violations. This section is not applicable.


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [x] Phase 3: Tasks generated (/tasks command) ✅
- [x] Phase 4: Implementation complete (/implement command) ✅
- [x] Phase 5: Validation passed (100 tests passing) ✅

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅ (none existed)
- [x] Complexity deviations documented ✅ (none exist)

**Artifacts Generated**:
- [x] research.md (Phase 0) ✅
- [x] data-model.md (Phase 1) ✅
- [x] contracts/html_element_api.md (Phase 1) ✅
- [x] quickstart.md (Phase 1) ✅
- [x] CLAUDE.md updated (Phase 1) ✅
- [x] tasks.md (Phase 3) ✅

**Ready for /implement command** ✅

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
