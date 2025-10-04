# Dart Blade Parser Constitution

## Core Principles

### I. Parser-First Architecture
- Core parsing logic must be framework-agnostic and independently testable
- Separate lexer, tokenizer, and AST builder as distinct, composable modules
- No UI/rendering concerns mixed with parsing logic
- Parser must be self-contained with clear boundaries
- Each module must have a single, well-defined responsibility

### II. Grammar Completeness
- Support full Blade syntax: directives (@if, @foreach, @section, @yield, etc.)
- Support Blade components with slots and attributes
- Support Alpine.js attribute parsing (x-data, x-show, x-bind, etc.)
- Provide clear, actionable error messages with line and column positioning
- Every syntax feature must be documented with examples

### III. Test-First Development (NON-NEGOTIABLE)
- TDD mandatory: Tests written → User approved → Tests fail → Then implement
- Every syntax feature requires test fixtures before implementation
- Test suite must include: valid Blade files, edge cases, malformed syntax
- Red-Green-Refactor cycle strictly enforced
- Performance benchmarks required for parsing operations

### IV. Zero Dependencies Philosophy
- Pure Dart implementation wherever possible
- Any external dependencies must be explicitly justified in design docs
- No platform-specific code (must support Flutter, Dart CLI, and web)
- Dependencies must not leak into public API surface
- Prefer standard library solutions over third-party packages

### V. Performance Standards
- Parse minimum 1,000 lines per second for typical Blade templates
- Memory usage under 100MB for typical template files
- Support incremental/streaming parsing for large files
- All performance-critical paths must be benchmarked
- Performance regressions require justification and mitigation plan

### VI. API Design & Interoperability
- Expose parse tree as traversable, visitable AST
- Support JSON serialization of AST for tooling integration
- Public API must be stable and follow semantic versioning
- CLI interface: stdin/args → stdout, errors → stderr
- Support both programmatic API and CLI usage

### VII. Tooling Ecosystem
- Core parser is a library; formatters/linters are independent consumers
- Each tool (formatter, linter, LSP) works standalone AND integrates with standard protocols
- No formatter or linting logic in the parser core
- Support Prettier plugin protocol via thin adapter layer
- Tools must not require parser modifications

## Testing Requirements

### Contract Testing
- Public API must have contract tests to prevent breaking changes
- All exported functions and classes must be covered
- Contract violations must fail CI/CD pipeline

### Integration Testing
- Complex nested Blade structures (components within loops within conditionals)
- Alpine.js integration scenarios (Alpine directives within Blade)
- Real-world Laravel Blade templates from popular packages
- Cross-module integration (lexer → parser → AST builder)

### Quality Gates
- Fuzzing tests for malformed and adversarial input
- Property-based testing for parser invariants
- Test coverage minimum: 90% for core parsing logic
- All tests must pass before merge

## Documentation Standards

- Every directive parser must include usage examples in dartdoc
- Public API fully documented with dartdoc comments
- README with quickstart guide and common use cases
- Architecture decision records (ADRs) for major design choices
- Performance characteristics documented for each major operation

## Development Workflow

### Feature Development
- All features follow: `/specify` → `/plan` → `/tasks` → `/implement` workflow
- Constitution compliance checked at planning phase
- Breaking changes require major version bump and migration guide

### Code Review
- All PRs must verify constitutional compliance
- Performance regression analysis required for parser changes
- Test-first approach verified (tests committed before implementation)

## Governance

This constitution supersedes all other development practices and patterns. Amendments require:
1. Documentation of rationale in constitution.md
2. Impact analysis on existing features
3. Migration plan for incompatible changes

All feature plans must reference this constitution for compliance verification. Complexity that violates principles must be justified in the Complexity Tracking section of plan.md.

**Version**: 1.0.0 | **Ratified**: 2025-10-04 | **Last Amended**: 2025-10-04
