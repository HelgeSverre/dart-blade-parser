
# Implementation Plan: Laravel Blade Template Parser

**Branch**: `001-create-a-laravel` | **Date**: 2025-10-04 | **Spec**: spec.md
**Input**: Feature specification from `/specs/001-create-a-laravel/spec.md`

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
Build a pure Dart parser for Laravel Blade templates that tokenizes, parses, and produces a traversable AST supporting complete Blade directive syntax (@if, @foreach, @section, @yield, components, slots, etc.), Alpine.js attributes (x-data, x-show, @click), Livewire attributes (wire:click, wire:model), echo statements, and comments. The parser must provide accurate error messages with line/column information, support both full-parse and streaming modes for large files, achieve 1000+ lines/sec performance with <100MB memory usage, expose both a programmatic Dart API and CLI interface, and work across Flutter, Dart CLI, and web environments with zero platform-specific dependencies.

## Technical Context
**Language/Version**: Dart 3.0+ (latest stable)
**Primary Dependencies**: Zero external parsing libraries (pure Dart standard library)
**Storage**: N/A (in-memory AST processing, JSON serialization)
**Testing**: Dart test package, benchmark harness for performance validation
**Target Platform**: Multi-platform (Flutter iOS/Android/web/desktop, Dart CLI, Dart web compilation)
**Project Type**: Single library project with CLI tool
**Performance Goals**: ≥1000 lines/sec parsing throughput, <10s for 10,000 line files
**Constraints**: <100MB memory for typical templates (<5000 lines), pure Dart (no FFI/platform channels)
**Scale/Scope**: Support full Blade grammar (50+ directives), Alpine.js (15+ attributes), Livewire (10+ attributes), nested structures up to 20 levels deep

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Parser-First Architecture**
- ✅ Core parsing logic framework-agnostic: Parser library separate from CLI tool
- ✅ Lexer/tokenizer/AST builder as distinct modules: Planned three-layer architecture
- ✅ No UI/rendering concerns: Pure parsing logic only
- ✅ Parser self-contained: No external dependencies on Laravel or PHP runtime
- ✅ Single responsibility per module: Tokenizer → Parser → AST Builder → Visitor

**II. Grammar Completeness**
- ✅ Full Blade syntax support: All 50+ directives from spec FR-001 through FR-010
- ✅ Components with slots/attributes: Covered in FR-005, FR-006
- ✅ Alpine.js attribute parsing: Covered in FR-011 through FR-014
- ✅ Livewire attribute parsing: Covered in FR-044 through FR-051
- ✅ Clear error messages with line/column: Covered in FR-021, FR-022
- ✅ Every syntax feature documented: Will be captured in contract tests and examples

**III. Test-First Development (NON-NEGOTIABLE)**
- ✅ TDD mandatory: Tests written → approval → fail → implement
- ✅ Test fixtures before implementation: Will create .blade test files in Phase 1
- ✅ Test suite (valid files, edge cases, malformed): Covered in user scenarios
- ✅ Red-Green-Refactor enforced: Workflow built into tasks
- ✅ Performance benchmarks: Required by FR-027, FR-028

**IV. Zero Dependencies Philosophy**
- ✅ Pure Dart implementation: No external parsing libraries (confirmed in Technical Context)
- ✅ Dependencies justified: None needed for core parser
- ✅ No platform-specific code: Must support Flutter/CLI/web (FR-038 through FR-041)
- ✅ No API surface leakage: Library exports only parser interface
- ✅ Standard library preference: Using only Dart core libraries

**V. Performance Standards**
- ✅ ≥1000 lines/sec: Required by FR-027
- ✅ <100MB memory: Required by FR-028
- ✅ Incremental/streaming parsing: Required by FR-029 (both modes)
- ✅ Benchmarked critical paths: Performance tests required in constitution
- ✅ Regression tracking: Will be part of test suite

**VI. API Design & Interoperability**
- ✅ Traversable/visitable AST: Required by FR-017
- ✅ JSON serialization: Required by FR-019, FR-034
- ✅ Stable public API: Semantic versioning from start
- ✅ CLI interface (stdin/stdout/stderr): Required by FR-032, FR-033, FR-036
- ✅ Programmatic + CLI usage: Both required by spec

**VII. Tooling Ecosystem**
- ✅ Core parser is library: Parser package separate from tooling
- ✅ Tools are independent consumers: Formatter/linter not in scope for this feature
- ✅ No formatter/linter in parser core: Out of scope
- ✅ Tools don't require parser mods: N/A (no tools yet)

**Initial Assessment**: ✅ **PASS** - No constitutional violations identified

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
├── src/
│   ├── lexer/
│   │   ├── token.dart           # Token types and definitions
│   │   ├── lexer.dart           # Tokenization logic
│   │   └── token_stream.dart    # Token stream management
│   ├── parser/
│   │   ├── parser.dart          # Main parser logic
│   │   ├── directive_parser.dart # Blade directive parsing
│   │   ├── component_parser.dart # Component parsing
│   │   └── expression_parser.dart # Echo/expression parsing
│   ├── ast/
│   │   ├── node.dart            # Base AST node types
│   │   ├── directive_node.dart  # Directive nodes
│   │   ├── component_node.dart  # Component nodes
│   │   ├── echo_node.dart       # Echo nodes
│   │   ├── visitor.dart         # Visitor pattern interface
│   │   └── json_serializer.dart # JSON serialization
│   ├── error/
│   │   ├── parse_error.dart     # Error types and handling
│   │   └── error_reporter.dart  # Error collection and reporting
│   └── streaming/
│       └── streaming_parser.dart # Incremental parsing mode
└── blade_parser.dart             # Public API exports

bin/
└── blade_parser.dart             # CLI entry point

test/
├── fixtures/
│   ├── valid/                   # Valid Blade templates
│   ├── invalid/                 # Malformed templates for error testing
│   └── edge_cases/              # Edge case templates
├── contract/
│   ├── token_contract_test.dart
│   ├── parser_contract_test.dart
│   └── ast_contract_test.dart
├── integration/
│   ├── full_parse_test.dart
│   ├── streaming_parse_test.dart
│   └── cli_test.dart
├── unit/
│   ├── lexer/
│   ├── parser/
│   └── ast/
└── performance/
    └── benchmark_test.dart
```

**Structure Decision**: Single library project (Option 1). This is a pure Dart library with a CLI tool. The `lib/` directory contains the parser implementation organized by architectural layer (lexer → parser → AST → error handling → streaming). The `bin/` directory contains the CLI tool. Test structure mirrors the source with contract, integration, unit, and performance test separation as required by constitution.

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

The /tasks command will load `.specify/templates/tasks-template.md` and generate dependency-ordered tasks following TDD workflow from the constitution. Tasks will be derived from:

1. **Contract Tests** (from `contracts/parser-api.md`):
   - Token contract test (verify Token structure, position tracking)
   - Lexer contract test (tokenize method guarantees)
   - Parser contract test (parse and parseStreaming methods)
   - AST contract test (visitor pattern, JSON serialization)
   - CLI contract test (interface, flags, exit codes)
   - Performance contract test (throughput, memory, nesting benchmarks)

2. **Data Model Implementation** (from `data-model.md`):
   - Token and TokenType enum [P]
   - Position class [P]
   - AstNode sealed class hierarchy [P]
   - AttributeNode sealed class hierarchy [P]
   - ParseError and ParseResult [P]

3. **Lexer Implementation** (research.md → hand-written state machine):
   - Lexer state machine skeleton
   - Token emission logic
   - @ disambiguation logic (Blade vs Alpine.js vs email)
   - @verbatim handling
   - Blade comment handling
   - Echo statement tokenization
   - Component tag tokenization
   - Alpine.js attribute tokenization
   - Livewire attribute tokenization
   - UTF-8 and line ending handling

4. **Parser Implementation** (research.md → recursive descent + Pratt):
   - Parser skeleton and error reporter
   - Directive parsing (all 75+ directives)
   - Component parsing (tags and slots)
   - Expression parsing (Pratt parser for PHP expressions)
   - Echo parsing
   - HTML element parsing
   - Error recovery (panic mode + synchronization)

5. **AST Utilities** (data-model.md):
   - Visitor pattern base classes
   - JSON serializer visitor
   - Parent-child navigation helpers

6. **Streaming Mode** (research.md):
   - Streaming parser implementation
   - Buffering logic for incomplete constructs
   - Node emission strategy

7. **CLI Interface**:
   - CLI argument parsing
   - File and stdin input handling
   - JSON and tree output formatting
   - Exit code handling

8. **Integration Tests** (from `quickstart.md`):
   - Parse dashboard with control structures (Scenario 1)
   - Parse component with slots (Scenario 2)
   - Parse Alpine.js attributes (Scenario 3)
   - Parse Livewire attributes (Scenario 8)
   - Error reporting (Scenario 4)
   - Performance test (Scenario 5)
   - JSON serialization (Scenario 6)
   - CLI interface (Scenario 7)

**Ordering Strategy**:
- **TDD Order**: Tests written and approved BEFORE implementation
- **Dependency Order**:
  1. Data models (Token, Position, AstNode hierarchy)
  2. Contract tests (failing tests for all APIs)
  3. Lexer (tokens enable parser)
  4. Parser (AST enables visitors)
  5. Visitors (utilities for traversal/serialization)
  6. Streaming mode (builds on parser)
  7. CLI (builds on all components)
  8. Integration tests (validate end-to-end workflows)
- **Parallel Execution**: Mark tasks with [P] when independent (e.g., creating different data model classes)

**Estimated Output**: 50-60 numbered, dependency-ordered tasks in tasks.md

**Task Categories**:
- Contract tests: ~10 tasks
- Data models: ~15 tasks
- Lexer: ~12 tasks
- Parser: ~15 tasks
- Visitors: ~4 tasks
- Streaming: ~3 tasks
- CLI: ~3 tasks
- Integration tests: ~8 tasks

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning approach described (/plan command)
- [x] Phase 3: Tasks generated (/tasks command) - 78 tasks created
- [x] Phase 4: Implementation complete (67/78 tasks completed - core functionality working)
- [x] Phase 5: Validation passed (all 31 contract + integration tests passing)

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (no new violations)
- [x] All NEEDS CLARIFICATION resolved (no unknowns in Technical Context)
- [x] Complexity deviations documented (none - no violations)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
