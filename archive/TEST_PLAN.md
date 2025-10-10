# Test Plan for Identified Parser Failures

This document outlines the test cases to add that will expose the failures identified in REVIEW.md.

## Test Organization

Tests will be added to existing test files where appropriate, or new test files will be created. Each test is designed to **fail** under current implementation and pass once fixes are applied.

---

## 1. Escaped Echo `@{{` Tests

**File**: `test/unit/lexer/lexer_blade_escapes_test.dart` (NEW)  
**Priority**: HIGH

### Test Cases:
1. **Simple escaped echo**
   - Input: `@{{ $variable }}`
   - Expected: Single text token containing `@{{ $variable }}`
   - Current behavior: Text token `@` + Echo token `{{ $variable }}`

2. **Escaped echo with nested braces**
   - Input: `@{{ $array['key'] }}`
   - Expected: Text token containing entire string
   - Current: Incorrectly parses as echo

3. **Multiple escaped echoes**
   - Input: `@{{ $a }} and @{{ $b }}`
   - Expected: Two text tokens
   - Current: Partial text + echoes

4. **Escaped echo in mixed content**
   - Input: `<p>Use @{{ $var }} for literal display</p>`
   - Expected: HTML with text child containing `@{{ $var }}`
   - Current: Echo inside HTML

---

## 2. Literal `@@` Escape Tests

**File**: `test/unit/lexer/lexer_blade_escapes_test.dart` (NEW)  
**Priority**: MEDIUM

### Test Cases:
1. **Simple @@ escape**
   - Input: `Contact us at admin@@example.com`
   - Expected: Text token with single `@` (output: `admin@example.com`)
   - Current: Likely treated as text `@@` (not normalized)

2. **@@ before directive**
   - Input: `@@if this is literal text`
   - Expected: Text `@if this is literal text`
   - Current: Unknown behavior

3. **Multiple @@ in string**
   - Input: `Email: user@@domain.com or admin@@domain.com`
   - Expected: Both `@@` converted to single `@`
   - Current: Not handled

---

## 3. Block Directive Tests (unless, php)

**File**: `test/unit/parser/directive_parser_test.dart` (EXISTING)  
**Priority**: HIGH

### Test Cases:
1. **@unless block directive**
   - Input: `@unless($condition)\n  <p>Content</p>\n@endunless`
   - Expected: DirectiveNode with name='unless', children containing HTML
   - Current: Inline directive, no children

2. **@php block directive**
   - Input: `@php\n  $x = 1;\n  echo $x;\n@endphp`
   - Expected: DirectiveNode with name='php', children as raw content
   - Current: Inline directive, content parsed as Blade/HTML

3. **Missing @endunless error**
   - Input: `@unless($x)\n  <p>Text</p>`
   - Expected: ParseError for missing @endunless
   - Current: No error or incorrect error

4. **@switch/@case/@default block**
   - Input:
     ```
     @switch($type)
       @case(1)
         <p>One</p>
         @break
       @default
         <p>Other</p>
     @endswitch
     ```
   - Expected: Specialized multi-branch structure
   - Current: Unknown/incorrect parsing

5. **@forelse/@empty block**
   - Input:
     ```
     @forelse($items as $item)
       <p>{{ $item }}</p>
     @empty
       <p>No items</p>
     @endforelse
     ```
   - Expected: Special forelse structure with empty branch
   - Current: Unknown/incorrect parsing

---

## 4. Component Slots Tests

**File**: `test/unit/parser/component_slots_test.dart` (NEW)  
**Priority**: HIGH

### Test Cases:
1. **Named slot with colon syntax**
   - Input: `<x-card>\n  <x-slot:header>Title</x-slot:header>\n  Body\n</x-card>`
   - Expected: ComponentNode with slots map containing 'header' → SlotNode
   - Current: Slot not recognized, likely treated as component

2. **Named slot with attribute syntax**
   - Input: `<x-card>\n  <x-slot name="footer">Footer</x-slot>\n</x-card>`
   - Expected: SlotNode with name='footer'
   - Current: Not recognized

3. **Multiple slots in component**
   - Input:
     ```
     <x-layout>
       <x-slot:header>Header</x-slot:header>
       <x-slot:footer>Footer</x-slot:footer>
       Body content
     </x-layout>
     ```
   - Expected: Component with 2 slots + default content
   - Current: Slots not parsed

4. **Slot with attributes**
   - Input: `<x-slot:title class="font-bold">My Title</x-slot:title>`
   - Expected: SlotNode with attributes
   - Current: Not parsed

5. **Nested content in slot**
   - Input:
     ```
     <x-slot:header>
       <h1>Title</h1>
       <p>Subtitle</p>
     </x-slot:header>
     ```
   - Expected: SlotNode with HTML children
   - Current: Not parsed

---

## 5. Raw Text Elements (script/style) Tests

**File**: `test/unit/parser/raw_text_elements_test.dart` (NEW)  
**Priority**: HIGH

### Test Cases:
1. **Script with comparison operators**
   - Input: `<script>\n  if (x < 10 && y > 5) { alert('test'); }\n</script>`
   - Expected: HtmlElementNode with single text child containing raw content
   - Current: Tries to parse `< 10` as HTML tag, fails

2. **Style with selectors**
   - Input: `<style>\n  div > p { color: red; }\n</style>`
   - Expected: Text child with raw CSS
   - Current: Tries to parse `>` as tag

3. **Script with template literals**
   - Input: `<script>\n  const html = \`<div>test</div>\`;\n</script>`
   - Expected: Raw content preserved
   - Current: Parses inner HTML

4. **Script with closing tag in string**
   - Input: `<script>\n  const str = "</script>";\n  console.log(str);\n</script>`
   - Expected: Proper handling of escaped closing tag
   - Current: Prematurely closes at first `</script>`

5. **Style followed by HTML**
   - Input: `<style>body { margin: 0; }</style>\n<div>Content</div>`
   - Expected: Two separate elements
   - Current: May merge incorrectly

---

## 6. HTML Comments Tests

**File**: `test/unit/lexer/lexer_html_comments_test.dart` (NEW)  
**Priority**: MEDIUM

### Test Cases:
1. **Simple HTML comment**
   - Input: `<!-- This is a comment -->`
   - Expected: Token with type=htmlComment, value='This is a comment'
   - Current: Treated as text

2. **Comment with special characters**
   - Input: `<!-- TODO: Fix <div> and @if -->`
   - Expected: htmlComment token
   - Current: Text, may interfere with parsing

3. **Comment in HTML structure**
   - Input: `<div><!-- comment --><p>Text</p></div>`
   - Expected: HTML with CommentNode child
   - Current: Comment lost or as text

4. **Multi-line comment**
   - Input:
     ```
     <!--
       Multi-line
       comment
     -->
     ```
   - Expected: Single comment token
   - Current: Text

5. **Comment vs Blade comment**
   - Input: `<!-- HTML --> {{-- Blade --}}`
   - Expected: htmlComment + bladeComment tokens
   - Current: Blade works, HTML doesn't

---

## 7. Unquoted Attribute Values Tests

**File**: `test/unit/parser/unquoted_attributes_test.dart` (NEW)  
**Priority**: MEDIUM

### Test Cases:
1. **Simple unquoted value**
   - Input: `<div class=container>`
   - Expected: Attribute name='class', value='container'
   - Current: value=null or error

2. **Numeric unquoted value**
   - Input: `<input maxlength=100>`
   - Expected: Attribute value='100'
   - Current: Fails

3. **Wire:poll with unquoted value**
   - Input: `<div wire:poll=500ms>`
   - Expected: LivewireAttribute value='500ms'
   - Current: Fails or value=null

4. **Multiple unquoted attributes**
   - Input: `<div id=main class=container data-x=value>`
   - Expected: All three attributes parsed correctly
   - Current: Some/all fail

5. **Mixed quoted and unquoted**
   - Input: `<div class="quoted" id=unquoted data-test="another">`
   - Expected: All three attributes correct
   - Current: Unquoted fails

---

## 8. Component Closing Tag Validation Tests

**File**: `test/unit/parser/component_validation_test.dart` (NEW)  
**Priority**: MEDIUM

### Test Cases:
1. **Mismatched component names**
   - Input: `<x-alert>Content</x-button>`
   - Expected: ParseError "Expected </x-alert>, found </x-button>"
   - Current: No error, silently accepts

2. **Correctly matched component tags**
   - Input: `<x-card>Content</x-card>`
   - Expected: No error
   - Current: Works (baseline)

3. **Nested components with mismatch**
   - Input: `<x-layout>\n  <x-card>Text</x-alert>\n</x-layout>`
   - Expected: Error on inner mismatch
   - Current: No error

4. **Case sensitivity in component names**
   - Input: `<x-Alert>Content</x-alert>`
   - Expected: Should match (normalize to lowercase) OR error
   - Current: Unknown

---

## 9. Streaming Incremental Emission Tests

**File**: `test/unit/streaming/streaming_incremental_test.dart` (NEW)  
**Priority**: HIGH

### Test Cases:
1. **Nodes emitted before stream completion**
   - Setup: Stream with 3 chunks, 500ms delay between each
   - Expected: First nodes available before 1500ms total
   - Current: All nodes arrive at end (after full buffer)

2. **Incremental node availability**
   - Input: Stream of separate top-level elements
   - Expected: Each element available as soon as its closing tag arrives
   - Current: All buffered

3. **Chunk split mid-token**
   - Input: Chunks: `['<di', 'v class=', '"test"', '>', 'Content', '</div>']`
   - Expected: Correct parsing, eventual node emission
   - Current: Likely fails or buffers everything

4. **Large file streaming memory test**
   - Input: Stream simulating 100KB+ file in 1KB chunks
   - Expected: Memory stays bounded, nodes emitted incrementally
   - Current: Buffers entire file in memory

5. **Error in mid-stream**
   - Input: Valid chunks, then error chunk, then valid chunks
   - Expected: Partial nodes + errors, continue parsing
   - Current: Unknown behavior

---

## 10. CLI Tests

**File**: `test/integration/cli_test.dart` (NEW)  
**Priority**: LOW

### Test Cases:
1. **Stdin multiline input**
   - Input: Pipe multiline template via stdin
   - Expected: All lines processed
   - Current: Only first line read

2. **Tree output includes HTML nodes**
   - Input: Template with HTML elements
   - Expected: Tree shows HTML structure
   - Current: HTML nodes missing from tree

3. **Tree output includes components**
   - Input: Template with `<x-component>`
   - Expected: Tree shows component
   - Current: Missing

---

## Implementation Order

### Phase 1 - Critical Failures (Week 1)
1. Escaped echo `@{{` tests
2. Block directive tests (unless, php)
3. Raw text elements tests
4. Component slots tests
5. Streaming incremental tests

### Phase 2 - Medium Priority (Week 2)
6. HTML comments tests
7. Unquoted attributes tests
8. Component validation tests
9. Literal `@@` tests

### Phase 3 - Polish (Week 3)
10. CLI tests
11. Additional edge cases discovered during phases 1-2

---

## Success Criteria

Each test should:
1. **Currently FAIL** - exposing the bug/gap
2. Have clear expected vs actual behavior documented
3. Include assertions that will pass once fix is implemented
4. Be isolated and not depend on other failing tests
5. Run quickly (<100ms per test)

After fixes are implemented, all tests should pass with `dart test` showing 100% success rate.
