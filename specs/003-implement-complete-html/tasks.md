# Tasks: Complete HTML Element Parsing

**Input**: Design documents from `/specs/003-implement-complete-html/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Extract: Dart 3.0+, zero dependencies, performance ≥1000 lines/sec
2. Load design documents ✅:
   → research.md: State-based tokenization, void elements, tag matching
   → data-model.md: HtmlElementNode (exists), AttributeNode types (exist), token types (to add)
   → contracts/: HTML element API contracts
   → quickstart.md: 13 test scenarios
3. Generate tasks by category ✅:
   → Setup: Token types, void elements set
   → Tests: Contract tests (6), integration tests (13), unit tests (8)
   → Core: Lexer HTML tokenization, parser _parseHtmlElement()
   → Integration: Tag matching, attribute categorization, error handling
   → Polish: Performance validation, backward compatibility
4. Apply task rules ✅:
   → Contract tests = parallel [P] (different test files)
   → Lexer/parser = sequential (same files modified)
   → Integration tests = parallel [P] (different test files)
5. Number tasks sequentially (T001-T040)
6. TDD enforced: All tests before implementation
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Exact file paths included in task descriptions

## Path Conventions
- Single library project: `lib/src/`, `test/` at repository root
- Paths: `lib/src/lexer/`, `lib/src/parser/`, `lib/src/ast/`
- Tests: `test/contract/`, `test/integration/`, `test/unit/`, `test/performance/`

---

## Phase 3.1: Setup & Foundation
*Prepare infrastructure for HTML parsing*

- [x] **T001** Add HTML token types to `lib/src/lexer/token_type.dart`
  - Add enum values: `htmlTagOpen`, `htmlTagName`, `htmlTagClose`, `htmlSelfClose`, `htmlClosingTagStart`, `htmlClosingTagEnd`
  - Update `TokenType.toString()` for new types
  - File: `lib/src/lexer/token_type.dart` (single file, not parallel)

- [x] **T002** Add void elements set to `lib/src/parser/parser.dart`
  - Create `static const Set<String> _voidElements = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'}`
  - Add `bool _isVoidElement(String tagName) => _voidElements.contains(tagName.toLowerCase())`
  - File: `lib/src/parser/parser.dart` (single file, not parallel)

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
*CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation*

### Contract Tests (API Surface Validation)

- [x] **T003** [P] Write HtmlElementNode constructor contract tests in `test/contract/html_element_contract_test.dart`
  - Test minimal parameters construction
  - Test tag name normalization to lowercase
  - Test void element flags acceptance
  - Tests MUST FAIL initially (HtmlElementNode already exists, but verify behavior)
  - File: `test/contract/html_element_contract_test.dart` (new file)

- [x] **T004** [P] Write HtmlElementNode visitor pattern contract tests in `test/contract/html_element_contract_test.dart`
  - Test `accept()` method calls `visitor.visitHtmlElement()`
  - Test visitor returns correct result
  - File: `test/contract/html_element_contract_test.dart` (same as T003, append to file)

- [x] **T005** [P] Write HtmlElementNode JSON serialization contract tests in `test/contract/html_element_contract_test.dart`
  - Test toJson() includes type, tagName, attributes, isSelfClosing, isVoid, position, children
  - Test JSON is encodable (jsonEncode works)
  - Test attribute types distinguishable in JSON
  - File: `test/contract/html_element_contract_test.dart` (same as T003-T004, append)

- [x] **T006** [P] Write attribute categorization contract tests in `test/contract/html_attribute_contract_test.dart`
  - Test StandardAttribute for class, id, data-*, aria-*
  - Test AlpineAttribute for x-data, @click, :class
  - Test LivewireAttribute for wire:click, wire:model.defer
  - Test boolean attributes (disabled, required) have null value
  - File: `test/contract/html_attribute_contract_test.dart` (new file)

- [x] **T007** [P] Write parser HTML recognition contract tests in `test/contract/parser_html_contract_test.dart`
  - Test Parser creates HtmlElementNode for `<div></div>`
  - Test Parser recognizes void elements `<br>`
  - Test Parser handles self-closing `<div />`
  - Test Parser builds nested HTML structure
  - Test Parser distinguishes HTML `<div>` from Blade component `<x-button>`
  - File: `test/contract/parser_html_contract_test.dart` (new file)

- [x] **T008** [P] Write error handling contract tests in `test/contract/parser_html_contract_test.dart`
  - Test unclosed tag error `<div><p>` → "Unclosed <p> at line X"
  - Test mismatched tag error `<div></span>` → "Expected </div>, found </span>"
  - Test void element closing tag error `<br></br>`
  - Test invalid tag name error `<123>`
  - Test multiple errors collected
  - Test partial AST returned on error
  - File: `test/contract/parser_html_contract_test.dart` (same as T007, append)

### Integration Tests (User Scenarios)

- [x] **T009** [P] Write simple HTML element parsing test in `test/integration/html_parsing_test.dart`
  - Test `<div class="container">Hello</div>` → HtmlElementNode with attributes and TextNode child
  - Quickstart scenario #1
  - File: `test/integration/html_parsing_test.dart` (new file)

- [x] **T010** [P] Write void element parsing test in `test/integration/html_parsing_test.dart`
  - Test `<br>` → HtmlElementNode with isVoid=true, no children
  - Quickstart scenario #2
  - File: `test/integration/html_parsing_test.dart` (same as T009, append)

- [x] **T011** [P] Write self-closing element parsing test in `test/integration/html_parsing_test.dart`
  - Test `<div />` → HtmlElementNode with isSelfClosing=true, no children
  - Quickstart scenario #3
  - File: `test/integration/html_parsing_test.dart` (same as T009-T010, append)

- [x] **T012** [P] Write Alpine.js attributes parsing test in `test/integration/html_parsing_test.dart`
  - Test `<div x-data="{count: 0}" @click="count++">` → AlpineAttribute instances
  - Quickstart scenario #4
  - File: `test/integration/html_parsing_test.dart` (same as T009-T011, append)

- [x] **T013** [P] Write Livewire attributes parsing test in `test/integration/html_parsing_test.dart`
  - Test `<button wire:click="save" wire:loading.class="opacity-50">` → LivewireAttribute instances
  - Quickstart scenario #5
  - File: `test/integration/html_parsing_test.dart` (same as T009-T012, append)

- [x] **T014** [P] Write nested HTML parsing test in `test/integration/html_parsing_test.dart`
  - Test `<div><header><h1>Title</h1></header><main><p>Content</p></main></div>` → nested HtmlElementNodes
  - Quickstart scenario #6
  - File: `test/integration/html_parsing_test.dart` (same as T009-T013, append)

- [x] **T015** [P] Write mixed Blade/HTML parsing test in `test/integration/mixed_blade_html_test.dart`
  - Test `<div>@if($show)<p>{{$message}}</p>@endif</div>` → HtmlElementNode containing DirectiveNode containing HtmlElementNode
  - Quickstart scenario #7
  - File: `test/integration/mixed_blade_html_test.dart` (new file)

- [x] **T016** [P] Write boolean attributes parsing test in `test/integration/html_parsing_test.dart`
  - Test `<input type="text" disabled required>` → boolean attributes with null value
  - Quickstart scenario #8
  - File: `test/integration/html_parsing_test.dart` (same as T009-T014, append)

- [x] **T017** [P] Write JSON export integration test in `test/integration/html_parsing_test.dart`
  - Test `<div class="foo" x-data="{}"></div>` → valid JSON with attribute types
  - Quickstart scenario #9
  - File: `test/integration/html_parsing_test.dart` (same as T009-T016, append)

- [x] **T018** [P] Write visitor pattern integration test in `test/integration/html_parsing_test.dart`
  - Test HTML element counter visitor on `<div><p>text</p><span>more</span></div>`
  - Quickstart scenario #10
  - File: `test/integration/html_parsing_test.dart` (same as T009-T017, append)

- [x] **T019** [P] Write error scenario integration tests in `test/integration/html_error_test.dart`
  - Test unclosed tag scenario (quickstart #11)
  - Test mismatched tags scenario (quickstart #12)
  - Test void element with closing tag scenario (quickstart #13)
  - File: `test/integration/html_error_test.dart` (new file)

### Unit Tests (Edge Cases)

- [x] **T020** [P] Write tag name normalization unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test `<DIV>` → tagName='div'
  - Test `<Div>` → tagName='div'
  - Test case-insensitive matching
  - File: `test/unit/parser/html_element_parser_test.dart` (new file)

- [x] **T021** [P] Write tag matching unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test matching `<div>...</div>`
  - Test mismatch detection `<div>...</span>`
  - Test nested matching `<div><p>...</p></div>`
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020, append)

- [x] **T022** [P] Write void element validation unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test all 14 void elements recognized
  - Test void element cannot have children
  - Test void element with closing tag error
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T021, append)

- [x] **T023** [P] Write attribute quote handling unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test double quotes: `class="foo"`
  - Test single quotes: `class='foo'`
  - Test unquoted: `data-id=123` (if valid)
  - Test escaped quotes: `title="He said \"hi\""`
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T022, append)

- [x] **T024** [P] Write HTML vs Blade component distinction unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test `<div>` → HtmlElementNode
  - Test `<x-button>` → ComponentNode
  - Test `<x-alert>` → ComponentNode
  - Test custom elements `<my-element>` → HtmlElementNode
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T023, append)

- [x] **T025** [P] Write multiple error collection unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test multiple unclosed tags collected
  - Test mixed error types collected
  - Test error positions accurate
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T024, append)

- [x] **T026** [P] Write partial AST generation unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test partial AST returned on unclosed tag
  - Test partial AST returned on mismatched tag
  - Test partial AST preserves valid nodes
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T025, append)

- [x] **T027** [P] Write position tracking unit tests in `test/unit/parser/html_element_parser_test.dart`
  - Test startPosition captures opening `<` location
  - Test endPosition captures closing `>` or `/>` location
  - Test position accuracy for nested elements
  - File: `test/unit/parser/html_element_parser_test.dart` (same as T020-T026, append)

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)
*Implement HTML parsing to make tests pass*

### Lexer Extension (HTML Tokenization)

- [x] **T028** Implement HTML tag opening recognition in `lib/src/lexer/lexer.dart`
  - When encountering `<`, check next character(s):
    - If letter (not 'x-'): emit `htmlTagOpen`, enter tag name state
    - If 'x-' followed by hyphen: delegate to existing component logic
    - If '/': emit `htmlClosingTagStart`, enter closing tag state
  - Update lexer state machine
  - File: `lib/src/lexer/lexer.dart` (single file, sequential with T029-T030)

- [x] **T029** Implement HTML tag name scanning in `lib/src/lexer/lexer.dart`
  - Scan tag name: letters, digits, hyphens (cannot start with digit)
  - Emit `htmlTagName` token with tag name
  - Transition to attribute scanning or tag close state
  - File: `lib/src/lexer/lexer.dart` (same as T028, sequential)

- [x] **T030** Implement HTML tag closing recognition in `lib/src/lexer/lexer.dart`
  - Detect `>` → emit `htmlTagClose` or `htmlClosingTagEnd`
  - Detect `/>` → emit `htmlSelfClose`
  - Return to text state after tag close
  - File: `lib/src/lexer/lexer.dart` (same as T028-T029, sequential)

### Parser Extension (HTML Element Parsing)

- [x] **T031** Implement `_parseHtmlElement()` method in `lib/src/parser/parser.dart`
  - Parse opening tag: consume `htmlTagOpen`, `htmlTagName`, attributes, `htmlTagClose` or `htmlSelfClose`
  - Create tag stack entry for non-void, non-self-closing elements
  - Parse children recursively until closing tag or EOF
  - Parse closing tag: verify tag name matches
  - Create HtmlElementNode with parsed data
  - File: `lib/src/parser/parser.dart` (same as T002, sequential with T032-T035)

- [x] **T032** Implement tag stack tracking in `lib/src/parser/parser.dart`
  - Add `_TagStackEntry` class (tagName, startPosition)
  - Add `List<_TagStackEntry> _tagStack = []`
  - Push on opening tag, pop on closing tag
  - Validate stack matches on close
  - File: `lib/src/parser/parser.dart` (same as T002, T031, sequential)

- [x] **T033** Implement tag matching validation in `lib/src/parser/parser.dart`
  - On closing tag: peek tag stack
  - If mismatch: generate ParseError with expected vs actual
  - If match: pop stack, complete element
  - Handle edge cases: empty stack, nested mismatches
  - File: `lib/src/parser/parser.dart` (same as T002, T031-T032, sequential)

- [x] **T034** Implement attribute categorization in `lib/src/parser/parser.dart`
  - During attribute parsing, check attribute name:
    - Starts with `x-`, `@`, `:` → AlpineAttribute
    - Starts with `wire:` → LivewireAttribute
    - Otherwise → StandardAttribute
  - Handle boolean attributes (no value) → value = null
  - Reuse existing attribute tokenization
  - File: `lib/src/parser/parser.dart` (same as T002, T031-T033, sequential)

- [x] **T035** Implement void element validation in `lib/src/parser/parser.dart`
  - After parsing opening tag: check `_isVoidElement(tagName)`
  - If void and self-closing: set both flags, no children
  - If void and not self-closing: set isVoid, no children, no closing tag expected
  - If void and closing tag encountered: generate error
  - If void and children added: generate error
  - File: `lib/src/parser/parser.dart` (same as T002, T031-T034, sequential)

### Error Handling Implementation

- [x] **T036** Implement HTML-specific error generation in `lib/src/parser/parser.dart`
  - Add error methods: `_unclosedTagError()`, `_mismatchedTagError()`, `_invalidTagNameError()`, `_voidElementError()`
  - Generate errors with position and clear messages
  - Continue parsing after error (error recovery)
  - Collect multiple errors in `errors` list
  - File: `lib/src/parser/parser.dart` (same as T002, T031-T035, sequential)

- [x] **T037** Implement partial AST generation on error in `lib/src/parser/parser.dart`
  - On unclosed tag: return HtmlElementNode with partial children
  - On mismatched tag: return HtmlElementNode with children up to error point
  - On invalid tag: skip to next valid token, continue
  - Ensure errors list populated and AST usable
  - File: `lib/src/parser/parser.dart` (same as T002, T031-T036, sequential)

---

## Phase 3.4: Validation & Performance
*Verify implementation meets requirements*

- [x] **T038** [P] Write and run HTML parsing performance benchmark in `test/performance/html_parsing_benchmark_test.dart`
  - Benchmark: 1000 lines of mixed HTML/Blade template
  - Measure: lines per second (must be ≥1000)
  - Measure: memory usage (must be <100MB)
  - Compare: baseline performance (no regression)
  - File: `test/performance/html_parsing_benchmark_test.dart` (new file)

- [x] **T039** [P] Verify backward compatibility by running existing test suite
  - Run: `dart test test/contract/` (existing contract tests)
  - Run: `dart test test/unit/parser/directive_parser_test.dart` (existing directive tests)
  - Run: `dart test test/integration/basic_parsing_test.dart` (existing integration tests)
  - Verify: All 100+ existing tests still pass
  - No changes to existing test files (read-only verification)

- [x] **T040** [P] Verify streaming mode compatibility in `test/unit/streaming/streaming_html_test.dart`
  - Test streaming parser handles HTML elements
  - Test partial chunk parsing (tag split across chunks)
  - Test tag stack maintained across chunks
  - File: `test/unit/streaming/streaming_html_test.dart` (new file)

---

## Dependencies

**Critical TDD Dependencies**:
- Tests T003-T027 MUST complete and FAIL before implementation T028-T037
- No implementation allowed until tests are failing

**Sequential Dependencies**:
- T001 (token types) → T028-T030 (lexer uses token types)
- T002 (void elements) → T035 (parser uses void elements set)
- T028-T030 (lexer) → T031-T037 (parser uses lexer tokens)
- T031 (_parseHtmlElement) → T032-T037 (all extend this method)

**Parallel Opportunities**:
- T003-T008 can run in parallel (different test files)
- T009-T019 can run in parallel (different test files, all integration)
- T020-T027 can run in parallel (different test files, all unit)
- T038-T040 can run in parallel (different test files, validation)

**Blocking Relationships**:
- T001-T002 → T028-T037 (setup before implementation)
- T003-T027 → T028-T037 (tests before implementation)
- T028-T030 → T031-T037 (lexer before parser)
- T031-T037 → T038-T040 (implementation before validation)

---

## Parallel Execution Examples

### Execute all contract tests in parallel:
```bash
# T003-T008 can run together (6 test tasks):
dart test test/contract/html_element_contract_test.dart &
dart test test/contract/html_attribute_contract_test.dart &
dart test test/contract/parser_html_contract_test.dart &
wait
```

### Execute all integration tests in parallel:
```bash
# T009-T019 can run together (11 test tasks):
dart test test/integration/html_parsing_test.dart &
dart test test/integration/mixed_blade_html_test.dart &
dart test test/integration/html_error_test.dart &
wait
```

### Execute all unit tests in parallel:
```bash
# T020-T027 can run together (8 test tasks):
dart test test/unit/parser/html_element_parser_test.dart &
wait
```

### Execute all validation tests in parallel:
```bash
# T038-T040 can run together (3 test tasks):
dart test test/performance/html_parsing_benchmark_test.dart &
dart test test/contract/ &
dart test test/unit/streaming/streaming_html_test.dart &
wait
```

---

## Task Summary

**Total Tasks**: 40
- Setup: 2 tasks (T001-T002)
- Contract Tests: 6 tasks (T003-T008) [P]
- Integration Tests: 11 tasks (T009-T019) [P]
- Unit Tests: 8 tasks (T020-T027) [P]
- Lexer Implementation: 3 tasks (T028-T030) [Sequential]
- Parser Implementation: 7 tasks (T031-T037) [Sequential]
- Validation: 3 tasks (T038-T040) [P]

**Parallel Tasks**: 28 (70% can run in parallel)
**Sequential Tasks**: 12 (30% must run in order)

**Estimated Time**:
- Setup: ~30 minutes (2 small tasks)
- Tests: ~6-8 hours (25 test tasks, can parallelize)
- Implementation: ~8-10 hours (10 sequential tasks, large complexity)
- Validation: ~2 hours (3 validation tasks)
- **Total**: ~16-20 hours

---

## Validation Checklist
*GATE: Verify before marking complete*

- [x] All contracts have corresponding tests (T003-T008 cover all API contracts)
- [x] All entities have model tasks (HtmlElementNode, AttributeNode already exist)
- [x] All tests come before implementation (T003-T027 before T028-T037)
- [x] Parallel tasks truly independent (verified: different files)
- [x] Each task specifies exact file path (all tasks include file paths)
- [x] No task modifies same file as another [P] task (verified: no conflicts)
- [x] TDD enforced (tests T003-T027 must fail before implementation)
- [x] Performance targets specified (T038: ≥1000 lines/sec, <100MB)
- [x] Backward compatibility verified (T039: run existing 100+ tests)
- [x] Constitutional compliance (all tasks align with constitution)

---

## Notes
- **TDD Critical**: All tests (T003-T027) MUST be written and MUST FAIL before starting implementation (T028-T037)
- **Constitutional Compliance**: Zero new dependencies, performance ≥1000 lines/sec, backward compatibility maintained
- **Parallel Execution**: 28/40 tasks (70%) can run in parallel for faster completion
- **File Conflicts**: Lexer and parser tasks are sequential (same files modified)
- **Error Recovery**: Partial AST must be usable even with errors (T036-T037)
- **Streaming Mode**: Must maintain compatibility with existing streaming parser (T040)

---

**Status**: Ready for execution via `/implement` command or manual task-by-task implementation.
