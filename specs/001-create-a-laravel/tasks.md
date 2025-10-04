# Tasks: Laravel Blade Template Parser

**Input**: Design documents from `/Users/helge/code/dart-blade-parser/specs/001-create-a-laravel/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/parser-api.md, quickstart.md
**Branch**: `001-create-a-laravel`
**Tech Stack**: Dart 3.0+, zero external parsing dependencies, Dart test package

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- **TDD MANDATORY**: Tests written and failing before implementation

---

## Phase 3.1: Setup

### T001: Initialize Dart project structure
**File**: Repository root
**Description**: Create Dart project with `pubspec.yaml`, configure package name `blade_parser`, set SDK constraints `>=3.0.0 <4.0.0`, add `test` dependency

**Actions**:
```bash
dart create -t package blade_parser
cd blade_parser
# Update pubspec.yaml with correct metadata
```

**Deliverable**:
- `pubspec.yaml` with project metadata
- `README.md` stub
- Basic directory structure (`lib/`, `test/`, `bin/`)

---

### T002: Create directory structure per plan.md
**Files**: Multiple directories
**Description**: Create the complete directory structure defined in plan.md

**Actions**:
```bash
mkdir -p lib/src/{lexer,parser,ast,error,streaming}
mkdir -p bin
mkdir -p test/{fixtures/{valid,invalid,edge_cases},contract,integration,unit/{lexer,parser,ast},performance}
```

**Deliverable**:
- All directories from plan.md created
- Empty `.gitkeep` files if needed

---

### T003 [P]: Configure linting and code formatting
**File**: `analysis_options.yaml`
**Description**: Set up Dart linter with strict rules for code quality

**Actions**:
- Create `analysis_options.yaml` with `package:lints/recommended.yaml`
- Enable strict type checking
- Configure formatting rules

**Deliverable**: `analysis_options.yaml` with linter configuration

---

### T004: Create test fixtures for valid Blade templates
**Files**: `test/fixtures/valid/*.blade.php`
**Description**: Create .blade template files covering all directive types for testing

**Test Fixtures Needed**:
1. `simple_echo.blade.php` - Basic {{ }} echo
2. `control_structures.blade.php` - @if, @foreach, @while
3. `components.blade.php` - <x-component> with slots
4. `alpine_js.blade.php` - x-data, @click, :bind
5. `livewire.blade.php` - wire:click, wire:model
6. `template_inheritance.blade.php` - @extends, @section, @yield
7. `nested_directives.blade.php` - 20-level deep nesting
8. `large_template.blade.php` - 10,000+ lines for performance testing

**Deliverable**: 8+ .blade.php fixture files

---

### T005 [P]: Create test fixtures for invalid Blade templates
**Files**: `test/fixtures/invalid/*.blade.php`
**Description**: Create malformed templates for error recovery testing

**Test Fixtures Needed**:
1. `unclosed_if.blade.php` - @if without @endif
2. `unclosed_foreach.blade.php` - @foreach without @endforeach
3. `malformed_echo.blade.php` - Unclosed {{ or {!!
4. `invalid_component.blade.php` - Unclosed component tag
5. `multiple_errors.blade.php` - Multiple syntax errors

**Deliverable**: 5+ invalid .blade.php fixture files

---

### T006 [P]: Create edge case test fixtures
**Files**: `test/fixtures/edge_cases/*.blade.php`
**Description**: Create templates testing edge cases from research.md

**Test Fixtures Needed**:
1. `email_addresses.blade.php` - user@example.com (@ disambiguation)
2. `verbatim_blocks.blade.php` - @verbatim with {{ }} inside
3. `blade_comments.blade.php` - {{-- comments --}}
4. `alpine_shorthand.blade.php` - @click vs @directive disambiguation
5. `ternary_or.blade.php` - {{ $x ? 'or' : 'other' }} edge case
6. `utf8_content.blade.php` - UTF-8 characters (你好, Héllo)
7. `crlf_line_endings.blade.php` - CRLF line endings

**Deliverable**: 7+ edge case .blade.php fixture files

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL**: These tests MUST be written and MUST FAIL before ANY implementation of Phase 3.3

---

### T007 [P]: Contract test for Token structure
**File**: `test/contract/token_contract_test.dart`
**Description**: Test Token class contract from parser-api.md

**Test Cases**:
- Token has all required fields (type, value, positions)
- Position validation (line ≥ 1, column ≥ 1)
- Offset validation (endOffset > startOffset)
- TokenType enum includes all 100+ token types

**Expected**: Tests FAIL (Token class doesn't exist yet)

---

### T008 [P]: Contract test for Lexer API
**File**: `test/contract/lexer_contract_test.dart`
**Description**: Test BladeLexer.tokenize() contract from parser-api.md

**Test Cases**:
- `tokenize(String)` returns `List<Token>`
- Always includes EOF token as last
- All tokens have position information
- Handles UTF-8 correctly
- Handles LF and CRLF line endings

**Expected**: Tests FAIL (BladeLexer doesn't exist yet)

---

### T009 [P]: Contract test for Parser API
**File**: `test/contract/parser_contract_test.dart`
**Description**: Test BladeParser.parse() and parseStreaming() contracts

**Test Cases**:
- `parse(String)` returns `ParseResult`
- Never throws for syntax errors
- Multiple errors reported (FR-026)
- Partial AST produced with errors (FR-026b)
- `parseStreaming(Stream<String>)` returns `Stream<AstNode>`

**Expected**: Tests FAIL (BladeParser doesn't exist yet)

---

### T010 [P]: Contract test for AST visitor pattern
**File**: `test/contract/ast_contract_test.dart`
**Description**: Test AstNode.accept() and toJson() contracts

**Test Cases**:
- All AstNode subtypes implement accept()
- Visitor pattern traverses entire tree
- toJson() serializes all node types
- JSON round-trip preserves structure

**Expected**: Tests FAIL (AstNode classes don't exist yet)

---

### T011 [P]: Contract test for CLI interface
**File**: `test/contract/cli_contract_test.dart`
**Description**: Test CLI flags and exit codes from parser-api.md

**Test Cases**:
- `--json` flag outputs JSON to stdout
- `--tree` flag outputs tree to stdout
- `--stdin` reads from stdin
- Exit code 0 on success, non-zero on error
- Errors go to stderr

**Expected**: Tests FAIL (CLI doesn't exist yet)

---

### T012 [P]: Performance contract test (throughput)
**File**: `test/performance/throughput_benchmark_test.dart`
**Description**: Benchmark parser throughput (FR-027: ≥1000 lines/sec)

**Test Cases**:
- Parse 1000-line template in ≤1 second
- Parse 10,000-line template in ≤10 seconds
- Measure tokens/sec and lines/sec

**Expected**: Tests FAIL (no parser implementation yet)

---

### T013 [P]: Performance contract test (memory)
**File**: `test/performance/memory_benchmark_test.dart`
**Description**: Benchmark memory usage (FR-028: <100MB for 5k lines)

**Test Cases**:
- Parse 5000-line template with <100MB peak memory
- Streaming mode uses O(buffered nodes) not O(file size)

**Expected**: Tests FAIL (no parser implementation yet)

**Note**: Requires Dart Observatory heap snapshot analysis

---

### T014 [P]: Performance contract test (nesting)
**File**: `test/performance/nesting_benchmark_test.dart`
**Description**: Benchmark nesting depth impact (FR-030: <10% slowdown at 20 levels)

**Test Cases**:
- Parse flat template (baseline)
- Parse 20-level nested template
- Assert nested time < 1.10 × flat time

**Expected**: Tests FAIL (no parser implementation yet)

---

### T015 [P]: Integration test - Parse dashboard (Scenario 1)
**File**: `test/integration/parse_dashboard_test.dart`
**Description**: Test parsing dashboard template with @if/@foreach from quickstart.md Scenario 1

**Test Cases**:
- Parse succeeds (no errors)
- AST contains @foreach with correct expression
- AST contains nested @if
- AST contains echo statements

**Fixture**: `test/fixtures/valid/control_structures.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T016 [P]: Integration test - Parse component with slots (Scenario 2)
**File**: `test/integration/parse_component_test.dart`
**Description**: Test parsing component with named slots from quickstart.md Scenario 2

**Test Cases**:
- ComponentNode has correct name
- Component has attributes
- Slots include header, default, footer
- Each slot has correct content

**Fixture**: `test/fixtures/valid/components.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T017 [P]: Integration test - Parse Alpine.js attributes (Scenario 3)
**File**: `test/integration/parse_alpine_test.dart`
**Description**: Test parsing Alpine.js attributes from quickstart.md Scenario 3

**Test Cases**:
- AlpineAttribute nodes created for x-data, x-show
- Standard attributes separate from Alpine.js
- Shorthand @click and :bind recognized

**Fixture**: `test/fixtures/valid/alpine_js.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T018 [P]: Integration test - Parse Livewire attributes (Scenario 8)
**File**: `test/integration/parse_livewire_test.dart`
**Description**: Test parsing Livewire attributes with modifiers from quickstart.md Scenario 8

**Test Cases**:
- LivewireAttribute nodes with action and modifiers
- wire:poll.5s → action="poll", modifiers=["5s"]
- wire:submit.prevent → modifiers include "prevent"

**Fixture**: `test/fixtures/valid/livewire.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T019 [P]: Integration test - Error reporting (Scenario 4)
**File**: `test/integration/error_reporting_test.dart`
**Description**: Test error messages with line/column from quickstart.md Scenario 4

**Test Cases**:
- Multiple errors reported without stopping
- Error includes line and column numbers
- Error message is descriptive
- Hint provided for common errors

**Fixture**: `test/fixtures/invalid/multiple_errors.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T020 [P]: Integration test - Large file performance (Scenario 5)
**File**: `test/integration/large_file_test.dart`
**Description**: Test parsing large file from quickstart.md Scenario 5

**Test Cases**:
- 10,000-line file parses in <10 seconds
- Memory usage <100MB

**Fixture**: `test/fixtures/valid/large_template.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T021 [P]: Integration test - JSON serialization (Scenario 6)
**File**: `test/integration/json_serialization_test.dart`
**Description**: Test AST JSON serialization from quickstart.md Scenario 6

**Test Cases**:
- toJson() produces valid JSON
- All node types serialized
- Can encode to JSON string
- Structure preserved after decode

**Fixture**: `test/fixtures/valid/simple_echo.blade.php`

**Expected**: Tests FAIL (no parser implementation yet)

---

### T022 [P]: Integration test - CLI interface (Scenario 7)
**File**: `test/integration/cli_interface_test.dart`
**Description**: Test CLI file and stdin input from quickstart.md Scenario 7

**Test Cases**:
- Parse file to JSON output
- Parse file to tree output
- Parse from stdin
- Error exit code on invalid template

**Expected**: Tests FAIL (no CLI implementation yet)

---

### T023 [P]: Integration test - Streaming mode
**File**: `test/integration/streaming_parse_test.dart`
**Description**: Test streaming parser for large files

**Test Cases**:
- Nodes emitted incrementally
- Memory usage bounded (not proportional to file size)
- Complete nodes only (buffering incomplete constructs)

**Fixture**: `test/fixtures/valid/large_template.blade.php`

**Expected**: Tests FAIL (no streaming parser yet)

---

## Phase 3.3: Core Implementation (ONLY after tests T007-T023 are failing)

**GATE**: Verify all tests in Phase 3.2 are written and failing before proceeding

---

### T024 [P]: Implement Position class
**File**: `lib/src/lexer/position.dart`
**Description**: Create Position class from data-model.md

**Implementation**:
- Fields: line, column, offset (all int)
- Validation: line ≥ 1, column ≥ 1, offset ≥ 0
- Equality and hashCode overrides
- toString() for debugging

**Validates**: T007 contract test passes (partial)

---

### T025 [P]: Implement TokenType enum
**File**: `lib/src/lexer/token_type.dart`
**Description**: Create TokenType enum with all 100+ token types from data-model.md

**Implementation**:
- All Blade directive types (75+ directives)
- Echo types (echoOpen, echoClose, rawEchoOpen, etc.)
- Component types
- Alpine.js types
- Livewire types
- Structural types (text, whitespace, eof, error)

**Validates**: T007 contract test passes (partial)

---

### T026 [P]: Implement Token class
**File**: `lib/src/lexer/token.dart`
**Description**: Create Token class from data-model.md

**Implementation**:
- Fields: type, value, startLine, startColumn, endLine, endColumn, startOffset, endOffset
- Import Position class
- Factory constructor for convenience
- toString() for debugging

**Validates**: T007 contract test passes (complete)

---

### T027 [P]: Implement base AstNode sealed class
**File**: `lib/src/ast/node.dart`
**Description**: Create AstNode sealed class hierarchy base from data-model.md

**Implementation**:
- Sealed class with abstract methods
- Fields: startPosition, endPosition, parent, children
- Methods: accept<T>(), toJson()
- Subclass declarations (DocumentNode, DirectiveNode, etc.)

**Validates**: T010 contract test passes (partial)

---

### T028 [P]: Implement DocumentNode
**File**: `lib/src/ast/document_node.dart`
**Description**: Create DocumentNode (root AST node)

**Implementation**:
- Extends AstNode
- accept() implementation calling visitor.visitDocument()
- toJson() implementation
- parent must be null

**Validates**: T010 contract test passes (partial)

---

### T029 [P]: Implement DirectiveNode
**File**: `lib/src/ast/directive_node.dart`
**Description**: Create DirectiveNode for Blade directives

**Implementation**:
- Extends AstNode
- Fields: name, expression, hasClosingTag, closingTagPosition, elseBranch, hasError
- accept() implementation
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T030 [P]: Implement ComponentNode
**File**: `lib/src/ast/component_node.dart`
**Description**: Create ComponentNode for Blade components

**Implementation**:
- Extends AstNode
- Fields: name, attributes, slots, isSelfClosing
- accept() implementation
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T031 [P]: Implement EchoNode
**File**: `lib/src/ast/echo_node.dart`
**Description**: Create EchoNode for echo statements

**Implementation**:
- Extends AstNode
- Fields: expression, isRaw, isLegacy
- accept() implementation (leaf node, no children)
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T032 [P]: Implement TextNode
**File**: `lib/src/ast/text_node.dart`
**Description**: Create TextNode for plain text

**Implementation**:
- Extends AstNode
- Fields: content
- accept() implementation (leaf node)
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T033 [P]: Implement HtmlElementNode
**File**: `lib/src/ast/html_element_node.dart`
**Description**: Create HtmlElementNode for HTML tags

**Implementation**:
- Extends AstNode
- Fields: tagName, attributes, isSelfClosing, isVoid
- accept() implementation
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T034 [P]: Implement CommentNode
**File**: `lib/src/ast/comment_node.dart`
**Description**: Create CommentNode for Blade and HTML comments

**Implementation**:
- Extends AstNode
- Fields: content, isBladeComment
- accept() implementation (leaf node)
- toJson() implementation

**Validates**: T010 contract test passes (partial)

---

### T035 [P]: Implement ErrorNode
**File**: `lib/src/ast/error_node.dart`
**Description**: Create ErrorNode for parse error markers

**Implementation**:
- Extends AstNode
- Fields: error, partialContent
- accept() implementation
- toJson() implementation

**Validates**: T019 integration test passes (partial)

---

### T036 [P]: Implement AttributeNode sealed class hierarchy
**File**: `lib/src/ast/attribute_node.dart`
**Description**: Create AttributeNode sealed class with StandardAttribute, AlpineAttribute, LivewireAttribute

**Implementation**:
- Base sealed class with name, value fields
- StandardAttribute subclass
- AlpineAttribute with directive field
- LivewireAttribute with action, modifiers fields

**Validates**: T016, T017, T018 integration tests pass (partial)

---

### T037 [P]: Implement SlotNode
**File**: `lib/src/ast/slot_node.dart`
**Description**: Create SlotNode for component slots

**Implementation**:
- Extends AstNode
- Fields: name, attributes
- Default slot has name "default"
- accept() and toJson() implementations

**Validates**: T016 integration test passes (partial)

---

### T038 [P]: Implement ParseError class
**File**: `lib/src/error/parse_error.dart`
**Description**: Create ParseError and ErrorSeverity from data-model.md

**Implementation**:
- ErrorSeverity enum (error, warning)
- ParseError class with message, position, severity, hint, sourceContext
- toString() for debugging

**Validates**: T019 integration test passes (partial)

---

### T039 [P]: Implement ParseResult class
**File**: `lib/src/error/parse_result.dart`
**Description**: Create ParseResult container from data-model.md

**Implementation**:
- Fields: ast, errors, warnings, isSuccess
- Validation: if ast is null, errors must not be empty
- Computed isSuccess property

**Validates**: T009 contract test passes (partial)

---

### T040: Implement AstVisitor interface
**File**: `lib/src/ast/visitor.dart`
**Description**: Create visitor pattern base classes

**Implementation**:
- Abstract AstVisitor<T> with visit methods for each node type
- RecursiveAstVisitor<T> base class with default traversal
- defaultVisit() method for common logic

**Validates**: T010 contract test passes (partial)

---

### T041 [P]: Implement JsonSerializerVisitor
**File**: `lib/src/ast/json_serializer.dart`
**Description**: Create JSON serialization visitor

**Implementation**:
- Extends RecursiveAstVisitor<Map<String, dynamic>>
- Implements visit methods for all node types
- Produces JSON-serializable maps

**Validates**: T010, T021 contract and integration tests pass (partial)

---

### T042: Implement BladeLexer - State machine skeleton
**File**: `lib/src/lexer/lexer.dart`
**Description**: Create BladeLexer with Rob Pike state machine pattern from research.md

**Implementation**:
- State function typedef: `StateFunction? Function()`
- Lexer class with input, position, line, column, tokens list
- run() method executing state machine
- Helper methods: _peek(), _advance(), _emit(), _isAtEnd()
- Initial states: _lexText() skeleton

**Validates**: T008 contract test passes (partial)

---

### T043: Implement BladeLexer - Text and whitespace states
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement _lexText() and _lexWhitespace() states

**Implementation**:
- _lexText(): Scan plain text, detect @ and { transitions
- _lexWhitespace(): Track whitespace (may be significant)
- Emit text and whitespace tokens

**Validates**: T008 contract test passes (partial)

---

### T044: Implement BladeLexer - Directive tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement _lexDirective() state for @ directives

**Implementation**:
- Detect @ symbol
- Distinguish @directive vs @{{ vs Alpine.js @event (context-sensitive)
- Scan directive name (alphanumeric)
- Emit appropriate directive token type
- Handle email addresses (user@example.com edge case)

**Validates**: T008 contract test, edge case fixtures pass (partial)

---

### T045: Implement BladeLexer - Echo statement tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement _lexEcho() states for {{ }}, {{{ }}}, {!! !!}

**Implementation**:
- Detect opening braces: {{, {{{, {!!
- Scan expression content
- Detect closing braces
- Emit echo tokens (echoOpen, echoClose, rawEchoOpen, etc.)

**Validates**: T008 contract test, T015 integration test pass (partial)

---

### T046: Implement BladeLexer - Blade comment tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement _lexBladeComment() for {{-- --}}

**Implementation**:
- Detect {{--
- Scan until --}}
- Emit bladeComment token
- Handle unclosed comments (error recovery)
- Edge case: PHP code inside comments (research.md bug)

**Validates**: T008 contract test, edge case fixtures pass (partial)

---

### T047: Implement BladeLexer - @verbatim block handling
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement _lexVerbatim() for @verbatim...@endverbatim

**Implementation**:
- Detect @verbatim directive
- Switch to verbatim mode (literal text, no Blade parsing)
- Scan until @endverbatim
- Emit text tokens for verbatim content
- Handle unclosed @verbatim (error)

**Validates**: T008 contract test, edge case fixtures pass (partial)

---

### T048: Implement BladeLexer - Component tag tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement component tag states for <x-component>

**Implementation**:
- Detect <x- prefix
- Scan component name
- Detect /> self-closing or >
- Emit componentTagOpen, componentSelfClose tokens
- Handle <x-slot:name> syntax

**Validates**: T008 contract test, T016 integration test pass (partial)

---

### T049: Implement BladeLexer - Alpine.js attribute tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement Alpine.js attribute detection (x-data, @click, :bind)

**Implementation**:
- Detect x- prefix attributes
- Detect @ shorthand (Alpine.js event, not Blade directive)
- Detect : shorthand (Alpine.js bind)
- Emit appropriate Alpine.js token types

**Validates**: T008 contract test, T017 integration test pass (partial)

---

### T050: Implement BladeLexer - Livewire attribute tokenization
**File**: `lib/src/lexer/lexer.dart`
**Description**: Implement Livewire attribute detection (wire:click, wire:model.live)

**Implementation**:
- Detect wire: prefix
- Parse modifiers (e.g., .live, .prevent, .5s)
- Emit Livewire token types with modifier information

**Validates**: T008 contract test, T018 integration test pass (partial)

---

### T051: Implement BladeLexer - UTF-8 and line ending handling
**File**: `lib/src/lexer/lexer.dart`
**Description**: Handle UTF-8 characters and LF/CRLF line endings

**Implementation**:
- Proper UTF-8 character handling
- Detect \n (LF) and \r\n (CRLF)
- Track line and column correctly for both endings
- Test with edge case fixtures

**Validates**: T008 contract test, edge case fixtures pass (partial)

---

### T052: Implement BladeParser - Parser skeleton
**File**: `lib/src/parser/parser.dart`
**Description**: Create BladeParser with recursive descent skeleton

**Implementation**:
- BladeParser class with TokenStream
- parse() method skeleton returning ParseResult
- _parseNode() method dispatching to specific parsers
- ErrorReporter integration

**Validates**: T009 contract test passes (partial)

---

### T053: Implement ErrorReporter
**File**: `lib/src/error/error_reporter.dart`
**Description**: Create ErrorReporter for collecting errors/warnings

**Implementation**:
- Lists for errors and warnings
- reportError() and reportWarning() methods
- Severity tracking (ErrorSeverity.error vs warning)
- Source context extraction for error messages

**Validates**: T019 integration test passes (partial)

---

### T054: Implement TokenStream helper
**File**: `lib/src/lexer/token_stream.dart`
**Description**: Create TokenStream for token navigation

**Implementation**:
- Wrapper around List<Token>
- Methods: peek(), advance(), consume(), match(), check()
- Position tracking (current index)
- isAtEnd check
- previous() for error reporting

**Validates**: T009 contract test passes (partial)

---

### T055: Implement BladeParser - Directive parsing (@if, @foreach, etc.)
**File**: `lib/src/parser/directive_parser.dart`
**Description**: Parse all Blade directive types into DirectiveNode

**Implementation**:
- _parseIfDirective() with @elseif/@else/@endif
- _parseForeachDirective() with @endforeach
- _parseForDirective(), _parseWhileDirective(), etc.
- Handle inline conditions (@continue($x), @break($x))
- All 75+ directives from research.md

**Validates**: T015 integration test passes (partial)

---

### T056: Implement BladeParser - Component parsing
**File**: `lib/src/parser/component_parser.dart`
**Description**: Parse Blade components into ComponentNode

**Implementation**:
- Parse <x-component> tags
- Parse attributes (Standard, Alpine, Livewire)
- Parse slots: <x-slot:name>, default slot
- Handle self-closing components
- Distinguish components from HTML elements

**Validates**: T016, T017, T018 integration tests pass (partial)

---

### T057: Implement BladeParser - Expression parsing (Pratt parser)
**File**: `lib/src/parser/expression_parser.dart`
**Description**: Parse PHP expressions using Pratt parsing from research.md

**Implementation**:
- ExpressionParser class
- parseExpression() with binding powers
- Prefix parsing (variables, literals, unary operators)
- Infix parsing (binary operators, ternary)
- Operator precedence handling

**Validates**: T015 integration test passes (partial)

---

### T058: Implement BladeParser - Echo parsing
**File**: `lib/src/parser/parser.dart` (add method)
**Description**: Parse echo statements into EchoNode

**Implementation**:
- _parseEcho() method
- Detect echo type (raw, escaped, legacy)
- Extract expression content
- Create EchoNode with correct flags

**Validates**: T015, T021 integration tests pass (partial)

---

### T059: Implement BladeParser - HTML element parsing
**File**: `lib/src/parser/parser.dart` (add method)
**Description**: Parse HTML elements into HtmlElementNode

**Implementation**:
- _parseHtmlElement() method
- Parse opening tag, attributes, children, closing tag
- Detect void elements (<br>, <img>, <meta>)
- Self-closing syntax handling

**Validates**: T015, T016 integration tests pass (partial)

---

### T060: Implement BladeParser - Error recovery (panic mode)
**File**: `lib/src/parser/parser.dart` (add method)
**Description**: Implement error recovery using panic mode and synchronization points

**Implementation**:
- _synchronize() method
- Synchronization points: directive starts, component tags
- Create ErrorNode markers in AST
- Continue parsing after errors (FR-026)

**Validates**: T019 integration test passes (complete)

---

### T061: Implement BladeParser - Multiple error reporting
**File**: `lib/src/parser/parser.dart` (update parse())
**Description**: Collect all errors without stopping at first error

**Implementation**:
- Wrap _parseNode() in try-catch
- Report error to ErrorReporter
- Continue parsing next nodes
- Return ParseResult with all errors and partial AST

**Validates**: T019 integration test passes (complete)

---

### T062: Implement StreamingParser
**File**: `lib/src/streaming/streaming_parser.dart`
**Description**: Implement parseStreaming() for incremental parsing

**Implementation**:
- StreamingParser class
- parseStreaming(Stream<String>) → Stream<AstNode>
- Buffer incomplete constructs (@if without @endif)
- Emit complete nodes as soon as parseable
- Memory usage O(buffered nodes) not O(file size)

**Validates**: T009 contract test, T023 integration test pass (complete)

---

### T063: Implement CLI - Argument parsing
**File**: `bin/blade_parser.dart`
**Description**: Parse CLI arguments (--json, --tree, --stdin)

**Implementation**:
- Use `args` package or manual parsing
- Flags: --json, --tree, --streaming, --stdin
- File path argument
- Usage help message

**Validates**: T011, T022 contract and integration tests pass (partial)

---

### T064: Implement CLI - File and stdin input
**File**: `bin/blade_parser.dart` (extend)
**Description**: Read input from file or stdin

**Implementation**:
- Read file if path provided
- Read from stdin if --stdin flag
- Error if neither or both provided
- UTF-8 decoding

**Validates**: T011, T022 contract and integration tests pass (partial)

---

### T065: Implement CLI - JSON and tree output
**File**: `bin/blade_parser.dart` (extend)
**Description**: Format output as JSON or human-readable tree

**Implementation**:
- JSON output: Use JsonSerializerVisitor, jsonEncode()
- Tree output: Custom TreeFormatterVisitor
- Output to stdout
- Errors to stderr

**Validates**: T011, T022 contract and integration tests pass (partial)

---

### T066: Implement CLI - Exit codes
**File**: `bin/blade_parser.dart` (extend)
**Description**: Set correct exit codes

**Implementation**:
- Exit 0 on successful parse
- Exit 1 on parse errors
- Exit 2 on invalid arguments

**Validates**: T011, T022 contract and integration tests pass (complete)

---

### T067: Create public API exports
**File**: `lib/blade_parser.dart`
**Description**: Export public API from main library file

**Implementation**:
- Export BladeParser, BladeLexer (optional)
- Export ParseResult, ParseError
- Export AstNode hierarchy
- Export AstVisitor
- Hide internal implementation details

**Validates**: T009 contract test passes (complete)

---

### T068: Optimize lexer performance
**File**: `lib/src/lexer/lexer.dart` (refactor)
**Description**: Apply performance optimizations from research.md

**Implementation**:
- Minimize string allocations (store indices, lazy extraction)
- Avoid dynamic types
- Pre-size token list if possible
- Profile with benchmarking package

**Validates**: T012 performance test passes (throughput)

---

### T069: Optimize parser performance
**File**: `lib/src/parser/parser.dart` (refactor)
**Description**: Apply performance optimizations

**Implementation**:
- Minimize AST node allocations
- Efficient list management
- Profile hot paths
- Ensure <10s for 10k line files

**Validates**: T012, T020 performance tests pass (complete)

---

### T070: Optimize memory usage
**File**: Multiple (refactor)
**Description**: Reduce memory footprint to meet FR-028 (<100MB)

**Implementation**:
- Use lightweight Position/Token structures
- Avoid duplicate strings
- Clear temporary buffers
- Profile with Observatory heap snapshots

**Validates**: T013 performance test passes (complete)

---

## Phase 3.4: Integration & Validation

---

### T071 [P]: Unit test - Lexer edge cases
**File**: `test/unit/lexer/lexer_edge_cases_test.dart`
**Description**: Unit tests for lexer edge cases from research.md

**Test Cases**:
- Email address @ handling (user@example.com)
- @verbatim with {{ }} inside
- Blade comments with PHP code
- Alpine.js @ vs Blade @ disambiguation
- UTF-8 characters
- CRLF line endings

**Validates**: All edge case fixtures parse correctly

---

### T072 [P]: Unit test - Parser directive handling
**File**: `test/unit/parser/directive_parser_test.dart`
**Description**: Unit tests for all 75+ directive types

**Test Cases**:
- Each directive type parses correctly
- Unclosed directives detected
- Inline conditions (@continue($x))
- Deprecated directives emit warnings

**Validates**: Complete directive coverage

---

### T073 [P]: Unit test - Expression parser
**File**: `test/unit/parser/expression_parser_test.dart`
**Description**: Unit tests for Pratt expression parser

**Test Cases**:
- Operator precedence correct
- Binary operators
- Unary operators
- Ternary operator
- Edge case: 'or' keyword in strings

**Validates**: Expression parsing correctness

---

### T074 [P]: Create README.md
**File**: `README.md`
**Description**: Write comprehensive README with quickstart examples

**Content**:
- Installation instructions
- Basic usage examples from quickstart.md
- API documentation link
- Performance characteristics
- Platform compatibility

**Validates**: Project documentation complete

---

### T075 [P]: Create CHANGELOG.md
**File**: `CHANGELOG.md`
**Description**: Document v1.0.0 initial release

**Content**:
- Version 1.0.0 release notes
- Features implemented
- Known limitations
- Breaking changes policy

**Validates**: Release documentation complete

---

### T076: Run all tests and verify passing
**Files**: All test files
**Description**: Execute full test suite and verify 100% pass rate

**Actions**:
```bash
dart test
dart test --coverage
```

**Validates**:
- All contract tests pass
- All integration tests pass
- All unit tests pass
- All performance tests pass
- Coverage ≥90% for core parsing logic

---

### T077: Generate API documentation
**Files**: All source files
**Description**: Generate dartdoc API documentation

**Actions**:
```bash
dart doc
```

**Validates**: Public API fully documented

---

### T078: Performance validation
**Files**: Performance test results
**Description**: Verify all performance targets met

**Validates**:
- ≥1000 lines/sec throughput ✓
- <100MB memory for 5k lines ✓
- <10s for 10k lines ✓
- <10% slowdown at 20 nesting levels ✓

---

## Dependencies

**Critical Path**:
```
Setup (T001-T006)
  ↓
Tests (T007-T023) - MUST FAIL before implementation
  ↓
Data Models (T024-T039)
  ↓
Lexer (T042-T051)
  ↓
Parser Core (T052-T061)
  ↓
Parser Features (T062)
  ↓
CLI (T063-T066)
  ↓
API Export (T067)
  ↓
Optimization (T068-T070)
  ↓
Validation (T071-T078)
```

**Parallel Execution Groups**:
- T007-T023: All contract and integration tests (different files)
- T024-T026: Token/Position classes (different files)
- T027-T037: AST node classes (different files)
- T038-T039: Error classes (different files)
- T071-T075: Documentation tasks (different files)

**Blocking Dependencies**:
- T027 (AstNode base) blocks T028-T037 (node implementations)
- T042 (Lexer skeleton) blocks T043-T051 (lexer states)
- T052 (Parser skeleton) blocks T055-T061 (parser methods)
- T067 (API export) blocks T076 (full test run)

---

## Parallel Execution Examples

### Launch all contract tests (T007-T013):
```bash
# In parallel - different files
dart test test/contract/token_contract_test.dart &
dart test test/contract/lexer_contract_test.dart &
dart test test/contract/parser_contract_test.dart &
dart test test/contract/ast_contract_test.dart &
dart test test/contract/cli_contract_test.dart &
wait
```

### Launch all integration tests (T015-T023):
```bash
# In parallel - different files
dart test test/integration/parse_dashboard_test.dart &
dart test test/integration/parse_component_test.dart &
dart test test/integration/parse_alpine_test.dart &
dart test test/integration/parse_livewire_test.dart &
dart test test/integration/error_reporting_test.dart &
dart test test/integration/large_file_test.dart &
dart test test/integration/json_serialization_test.dart &
dart test test/integration/cli_interface_test.dart &
dart test test/integration/streaming_parse_test.dart &
wait
```

### Create data model classes in parallel (T024-T039):
```bash
# In parallel - different files
# (Pseudocode - use Task agent for actual parallel execution)
Task: "Implement Position class in lib/src/lexer/position.dart"
Task: "Implement TokenType enum in lib/src/lexer/token_type.dart"
Task: "Implement Token class in lib/src/lexer/token.dart"
Task: "Implement base AstNode in lib/src/ast/node.dart"
# etc.
```

---

## Validation Checklist

- [x] All contracts have corresponding tests (T007-T011)
- [x] All entities have implementation tasks (T024-T039)
- [x] All tests come before implementation (Phase 3.2 before 3.3)
- [x] Parallel tasks are independent (different files, marked [P])
- [x] Each task specifies exact file path
- [x] No [P] task modifies same file as another [P] task
- [x] TDD workflow enforced (tests fail, then implement)
- [x] Performance targets validated (T012-T014, T078)
- [x] Constitutional compliance verified throughout

---

## Notes

- **TDD MANDATORY**: Phase 3.2 tests MUST be written and failing before Phase 3.3 implementation
- **[P] markers**: Indicates tasks that can run in parallel (different files, no dependencies)
- **Commit strategy**: Commit after each task completion
- **Test-driven**: Red → Green → Refactor cycle strictly enforced
- **Performance**: Profile early (T012-T014), optimize later (T068-T070)
- **Documentation**: Generated from code (dartdoc), examples from quickstart.md

---

**Total Tasks**: 78
**Estimated Effort**: 4-6 weeks for complete implementation
**Critical Path**: Setup → Tests → Data Models → Lexer → Parser → CLI → Validation

---

**Tasks Generation Complete**: ✅
**Ready for Implementation**: ✅ (After Phase 3.2 tests written and approved)
**Constitutional Compliance**: ✅ (TDD, Zero Dependencies, Performance Standards)
