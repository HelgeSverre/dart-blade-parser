# Data Model

## Overview
This document defines the data structures for HTML element parsing. Most entities already exist in the codebase (lib/src/ast/node.dart, lib/src/lexer/token_type.dart). This feature extends them with HTML-specific capabilities.

## Core Entities

### HtmlElementNode (existing, to be enhanced)
**Location**: `lib/src/ast/node.dart:319`

**Purpose**: Represents a parsed HTML element in the Abstract Syntax Tree

**Fields**:
- `tagName: String` - HTML tag name (normalized to lowercase: 'div', 'p', 'span')
- `attributes: Map<String, AttributeNode>` - Map of attribute name to AttributeNode
- `children: List<AstNode>` - Child nodes (TextNode, DirectiveNode, HtmlElementNode, etc.)
- `isSelfClosing: bool` - True if written as `<div />`, false for `<div></div>`
- `isVoid: bool` - True if HTML5 void element (br, img, input, etc.)
- `startPosition: Position` - Location of opening `<` character
- `endPosition: Position` - Location of closing `>` or `/>`
- `parent: AstNode?` - Parent node reference

**Validation Rules** (enforced during parsing):
- If `isVoid == true`, `children` must be empty (error if violated)
- If `isVoid == true` and closing tag present, generate error
- `tagName` must be valid identifier (letters, digits, hyphens; cannot start with digit)
- `tagName` starting with `x-` followed by hyphen → ComponentNode, not HtmlElementNode

**State Transitions**: N/A (immutable after construction)

**Relationships**:
- Parent: DocumentNode or HtmlElementNode or DirectiveNode
- Children: Any AstNode subtype (TextNode, DirectiveNode, HtmlElementNode, EchoNode, CommentNode)
- Contains: Multiple AttributeNode instances

**Example**:
```dart
HtmlElementNode(
  tagName: 'div',
  attributes: {
    'class': StandardAttribute(name: 'class', value: 'container'),
    'x-data': AlpineAttribute(name: 'x-data', value: '{count: 0}'),
  },
  isSelfClosing: false,
  isVoid: false,
  startPosition: Position(line: 1, column: 1, offset: 0),
  endPosition: Position(line: 1, column: 50, offset: 49),
  children: [TextNode(content: 'Hello')],
)
```

---

### AttributeNode (existing)
**Location**: `lib/src/ast/node.dart:172`

**Purpose**: Base class for all attribute types. Sealed class with three concrete implementations.

**Common Fields** (all subtypes):
- `name: String` - Attribute name (e.g., 'class', 'x-data', 'wire:click')
- `value: String?` - Attribute value (null for boolean attributes like 'disabled')
- `quote: String?` - Quote character used ('"', "'", or null for unquoted/boolean)

**Subtypes**:

#### StandardAttribute
**Purpose**: Regular HTML attributes

**Examples**:
- `class="container"` → StandardAttribute(name: 'class', value: 'container', quote: '"')
- `id='app'` → StandardAttribute(name: 'id', value: 'app', quote: "'")
- `disabled` → StandardAttribute(name: 'disabled', value: null, quote: null)
- `data-user-id="123"` → StandardAttribute(name: 'data-user-id', value: '123', quote: '"')

**Recognition Pattern**: Does not start with `x-`, `@`, `:`, or `wire:`

#### AlpineAttribute
**Purpose**: Alpine.js framework attributes

**Examples**:
- `x-data="{count: 0}"` → AlpineAttribute(name: 'x-data', value: '{count: 0}', quote: '"')
- `@click="increment"` → AlpineAttribute(name: '@click', value: 'increment', quote: '"')
- `:class="{'active': isActive}"` → AlpineAttribute(name: ':class', value: "{'active': isActive}", quote: '"')
- `x-show="open"` → AlpineAttribute(name: 'x-show', value: 'open', quote: '"')

**Recognition Pattern**: Starts with `x-`, `@`, or `:`

**Expansion Rules**:
- `@event` shorthand for `x-on:event`
- `:attr` shorthand for `x-bind:attr`

#### LivewireAttribute
**Purpose**: Livewire framework attributes (may include modifiers)

**Examples**:
- `wire:click="save"` → LivewireAttribute(name: 'wire:click', value: 'save', quote: '"')
- `wire:model="name"` → LivewireAttribute(name: 'wire:model', value: 'name', quote: '"')
- `wire:loading.attr="disabled"` → LivewireAttribute(name: 'wire:loading.attr', value: 'disabled', quote: '"')
- `wire:poll.5s="refresh"` → LivewireAttribute(name: 'wire:poll.5s', value: 'refresh', quote: '"')

**Recognition Pattern**: Starts with `wire:`

**Modifier Handling**: Modifiers are part of the attribute name (e.g., `wire:loading.attr` → name includes `.attr`)

---

### Token Types (to be extended)
**Location**: `lib/src/lexer/token_type.dart`

**Purpose**: Define token types for HTML tag scanning

**New Token Types to Add**:
```dart
enum TokenType {
  // ... existing types ...

  // HTML-specific tokens
  htmlTagOpen,        // '<' when starting HTML element (not Blade component)
  htmlTagName,        // Tag name after '<' (e.g., 'div', 'span')
  htmlTagClose,       // '>' closing opening tag
  htmlSelfClose,      // '/>' self-closing tag
  htmlClosingTagStart, // '</' starting closing tag
  htmlClosingTagEnd,   // '>' closing a closing tag

  // Existing attribute tokens already support HTML attributes
  // attributeName, attributeValue, attributeEquals
}
```

**Token Sequence Examples**:
- `<div>` → [htmlTagOpen, htmlTagName('div'), htmlTagClose]
- `<br />` → [htmlTagOpen, htmlTagName('br'), htmlSelfClose]
- `</div>` → [htmlClosingTagStart, htmlTagName('div'), htmlClosingTagEnd]
- `<div class="foo">` → [htmlTagOpen, htmlTagName('div'), attributeName('class'), attributeEquals, attributeValue('foo'), htmlTagClose]

---

### Position (existing)
**Location**: `lib/src/lexer/position.dart`

**Purpose**: Track source code location for error reporting and source mapping

**Fields**:
- `line: int` - Line number (1-based)
- `column: int` - Column number (1-based)
- `offset: int` - Byte offset from start of file (0-based)

**Usage in HTML Parsing**:
- Capture position before consuming `<` → HtmlElementNode.startPosition
- Capture position after consuming `>` or `/>` → HtmlElementNode.endPosition
- Include in error messages: "Unclosed <div> at line 5, column 10"

---

### ParseError (existing)
**Location**: `lib/src/error/parse_error.dart`

**Purpose**: Represent parsing errors with position and context

**New Error Types for HTML**:
- `unclosedTag(tagName, position)` - Tag opened but not closed
- `mismatchedTag(expected, found, position)` - `<div>...</span>`
- `invalidTagName(tagName, position)` - `<123>` or `<>`
- `voidElementClosingTag(tagName, position)` - `<br></br>`
- `voidElementChildren(tagName, position)` - `<img>text</img>`

**Error Message Format**:
```dart
ParseError(
  message: "Expected </div>, found </span> at line 5, column 20",
  position: Position(line: 5, column: 20, offset: 150),
  severity: ErrorSeverity.error,
)
```

---

## Validation Rules Summary

| Entity | Rule | Error Condition |
|--------|------|----------------|
| HtmlElementNode | Void elements cannot have children | `isVoid == true && children.isNotEmpty` |
| HtmlElementNode | Void elements cannot have closing tags | `isVoid == true` and `</tag>` encountered |
| HtmlElementNode | Tag name must be valid | Starts with digit, contains invalid characters |
| HtmlElementNode | Tags must match | Opening `<div>` with closing `</span>` |
| AttributeNode | Boolean attributes have no value | `disabled="true"` should be `disabled` (warning, not error) |
| Token | Self-close only on opening tag | `<div></>` is invalid |

---

## State Transitions

### Tag Parsing State Machine
```
[Start]
  → Consume '<'
  → [InOpeningTag]
     → Consume tag name
     → [InTagName]
        → Consume attributes*
        → [InAttributes]
           → Consume '>' → [TagClosed] → Parse children
           → Consume '/>' → [SelfClosed] → No children
  → Consume '</'
  → [InClosingTag]
     → Consume tag name
     → Verify matches opening tag
     → Consume '>'
     → [TagMatched]
```

### Error Recovery States
```
[UnclosedTag] → Return partial AST + error
[MismatchedTag] → Return partial AST + error, continue parsing
[InvalidTagName] → Skip to next valid token, continue parsing
```

---

## Relationships Diagram

```
DocumentNode (root)
  ├─ HtmlElementNode (div)
  │   ├─ attributes: Map<String, AttributeNode>
  │   │   ├─ 'class' → StandardAttribute
  │   │   ├─ 'x-data' → AlpineAttribute
  │   │   └─ 'wire:click' → LivewireAttribute
  │   └─ children: List<AstNode>
  │       ├─ TextNode
  │       ├─ DirectiveNode (@if)
  │       │   └─ children: List<AstNode>
  │       │       └─ HtmlElementNode (p)
  │       └─ HtmlElementNode (span)
  └─ HtmlElementNode (footer)
```

---

## JSON Serialization

All entities support `toJson()` for tooling integration:

```json
{
  "type": "htmlElement",
  "tagName": "div",
  "attributes": {
    "class": {
      "type": "standard",
      "name": "class",
      "value": "container",
      "quote": "\""
    },
    "x-data": {
      "type": "alpine",
      "name": "x-data",
      "value": "{count: 0}",
      "quote": "\""
    }
  },
  "isSelfClosing": false,
  "isVoid": false,
  "position": {
    "start": {"line": 1, "column": 1, "offset": 0},
    "end": {"line": 3, "column": 7, "offset": 85}
  },
  "children": [...]
}
```

---

## Performance Considerations

- **Map<String, AttributeNode>**: O(1) attribute lookup by name
- **Set<String> _voidElements**: O(1) void element check (const static set)
- **List<AstNode> children**: Ordered children, efficient iteration
- **Immutable nodes**: Safe for concurrent access, cacheable
- **Position tracking**: Minimal overhead (3 integers per position)

---

## Summary

The data model leverages existing AST infrastructure:
- ✅ HtmlElementNode already exists (ready to use)
- ✅ AttributeNode types already exist (StandardAttribute, AlpineAttribute, LivewireAttribute)
- ✅ Position tracking already implemented
- ✅ Visitor pattern already in place
- ✅ JSON serialization already supported

New additions:
- 🆕 HTML-specific token types in TokenType enum
- 🆕 HTML-specific error messages in ParseError
- 🆕 Void element validation logic in parser
- 🆕 Tag matching/stack tracking in parser
