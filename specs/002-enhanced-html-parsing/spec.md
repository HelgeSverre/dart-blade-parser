# Feature Specification: Enhanced HTML Element Parsing

**Feature Branch**: `002-enhanced-html-parsing`
**Created**: 2025-10-05
**Status**: Draft
**Depends On**: 001-create-a-laravel (✅ Complete)

**Input**: "The current parser treats HTML tags as plain text nodes. We need proper HTML element parsing that creates HtmlElementNode instances with parsed tag names, attributes (standard, Alpine.js, and Livewire), proper nesting, and support for void elements. HTML elements should be distinguished from Blade components, and the parser should handle self-closing syntax, mixed attribute types, and nested structures correctly."

---

## Problem Statement

Currently, HTML in Blade templates is parsed as text:

```
❌ Current Output:
TextNode: "div class='foo'>"
TextNode: "</div>"

✅ Expected Output:
HtmlElementNode
  tagName: "div"
  attributes: { "class": StandardAttribute("foo") }
  children: [...]
```

This prevents:
- Accurate AST representation
- Proper formatting
- HTML validation
- Attribute-aware tooling

---

## User Scenarios

### Scenario 1: Parse Standard HTML Elements
**Given**: A Blade template with HTML elements
```blade
<div class="container">
  <h1 id="title">Hello</h1>
  <p>Content</p>
</div>
```

**When**: Parser processes the template

**Then**:
- Creates HtmlElementNode for `<div>`, `<h1>`, `<p>`
- Parses attributes: `class="container"`, `id="title"`
- Maintains proper parent-child relationships
- Closing tags matched correctly

---

### Scenario 2: Parse Void Elements
**Given**: HTML with void elements
```blade
<div>
  <br>
  <img src="photo.jpg" alt="Photo">
  <input type="text" name="email">
  <hr>
</div>
```

**When**: Parser processes void elements

**Then**:
- Recognizes void elements (br, img, input, hr, meta, link)
- No closing tag required
- Children not allowed
- Self-closing `/` optional

---

### Scenario 3: Parse Mixed Attributes
**Given**: HTML with Alpine.js and Livewire attributes
```blade
<div 
  class="card" 
  x-data="{ open: false }"
  wire:loading
  @click="toggle">
  <button wire:click="save">Save</button>
</div>
```

**When**: Parser processes mixed attributes

**Then**:
- `class` → StandardAttribute
- `x-data` → AlpineAttribute
- `wire:loading` → LivewireAttribute
- `@click` → AlpineAttribute (shorthand)
- All attributes accessible in AST

---

### Scenario 4: Distinguish HTML from Components
**Given**: Mix of HTML and Blade components
```blade
<div class="wrapper">
  <x-alert type="info">
    <p>This is HTML inside component</p>
  </x-alert>
</div>
```

**When**: Parser processes mixed content

**Then**:
- `<div>` → HtmlElementNode
- `<x-alert>` → ComponentNode
- `<p>` → HtmlElementNode
- Correct nesting maintained

---

### Scenario 5: Handle Self-Closing HTML
**Given**: Self-closing HTML syntax
```blade
<div class="foo" />
<span id="bar" />
```

**When**: Parser processes self-closing tags

**Then**:
- Accepts self-closing syntax for non-void elements
- No children expected
- Closing tag not required

---

## Functional Requirements

### FR-100: HTML Tag Tokenization
The lexer MUST emit tokens for HTML tag components:
- `htmlTagOpen` - Opening tag start: `<div`
- `htmlTagClose` - Closing tag: `</div>`
- `htmlTagSelfClose` - Self-closing: `/>`
- `htmlTagEnd` - End of opening tag: `>`
- Attributes handled by existing attribute tokenization

### FR-101: HTML Element Parsing
The parser MUST create HtmlElementNode instances with:
- `tagName: String` - Tag name (div, p, span, etc.)
- `attributes: Map<String, AttributeNode>` - Parsed attributes
- `children: List<AstNode>` - Child nodes
- `isSelfClosing: bool` - Self-closing syntax used
- `isVoid: bool` - Is void element (br, img, etc.)

### FR-102: Void Element Recognition
The parser MUST recognize void elements:
- List: `area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr`
- Void elements MUST NOT have children
- Void elements MAY use self-closing `/>`
- Void elements MUST NOT have closing tags

### FR-103: Tag Name Validation
The parser MUST validate tag names:
- Start with letter
- Contain letters, digits, hyphens
- Case-insensitive matching
- Reject invalid names with clear errors

### FR-104: Nesting Validation
The parser MUST validate proper nesting:
- Opening and closing tags match
- Report unclosed tags with line/column
- Handle nested structures correctly
- Maintain parent-child relationships

### FR-105: Component vs HTML Distinction
The lexer MUST distinguish:
- `<div>` → HTML element
- `<x-component>` → Blade component
- Detection by `x-` prefix
- No ambiguity in tokenization

### FR-106: Attribute Parsing
The parser MUST parse all attribute types on HTML:
- Standard attributes (class, id, data-*)
- Alpine.js attributes (x-data, @click, :bind)
- Livewire attributes (wire:click, wire:model.live)
- Boolean attributes (disabled, readonly)
- Quoted and unquoted values

### FR-107: Error Recovery
The parser MUST recover from HTML errors:
- Unclosed tags → Error + partial AST
- Mismatched tags → Error + synchronization
- Invalid tag names → Error + skip
- Continue parsing after errors

### FR-108: Position Tracking
HTML nodes MUST track positions:
- `startPosition` - Opening tag start
- `endPosition` - Closing tag end (or self-close)
- Enable accurate error messages
- Support source mapping

---

## Non-Functional Requirements

### NFR-100: Performance
- HTML parsing MUST NOT degrade parser performance
- Target: Still ≥1000 lines/sec
- Memory: Still <100MB for 5k lines

### NFR-101: Backward Compatibility
- Existing Blade directive parsing MUST NOT change
- Component parsing MUST NOT be affected
- All 100 existing tests MUST still pass

### NFR-102: Test Coverage
- Add 20+ HTML-specific tests
- Cover all void elements
- Test attribute combinations
- Edge cases (unclosed, malformed, nested)

---

## Acceptance Criteria

1. ✅ HTML elements create HtmlElementNode (not TextNode)
2. ✅ Tag names and attributes correctly parsed
3. ✅ Void elements recognized and validated
4. ✅ Self-closing syntax supported
5. ✅ Mixed Alpine.js/Livewire attributes work
6. ✅ HTML/Component distinction clear
7. ✅ Proper nesting with error recovery
8. ✅ All existing tests still pass
9. ✅ 20+ new HTML tests pass
10. ✅ Performance targets maintained

---

## Out of Scope

- HTML validation beyond basic nesting
- CSS parsing within style attributes
- JavaScript parsing within script tags
- HTML entity decoding
- DOCTYPE or meta tag processing

---

## Dependencies

**Required from 001**:
- ✅ Lexer state machine
- ✅ Parser infrastructure
- ✅ HtmlElementNode class (already exists)
- ✅ AttributeNode types (Standard, Alpine, Livewire)
- ✅ Error reporting system

**No new dependencies needed** - Pure Dart implementation

---

## Success Metrics

- HTML elements properly represented in AST
- Tree output shows HtmlElementNode instead of TextNode
- Formatter foundation ready (next feature)
- Zero performance regression

---

**Status**: Ready for /plan command
