# Data Model: Enhanced HTML Element Parsing

**Feature**: 002-enhanced-html-parsing  
**Date**: 2025-10-05

---

## Entities

### HtmlElementNode (Extends AstNode)

**Purpose**: Represents an HTML element in the Blade template AST

**Fields**:
- `tagName: String` - HTML element name (div, p, span, etc.)
  - Normalized to lowercase for comparison
  - Validated: must start with letter, contain only letters/digits/hyphens
  
- `attributes: Map<String, AttributeNode>` - Parsed attributes by name
  - Key: attribute name (e.g., "class", "x-data", "wire:loading")
  - Value: AttributeNode subtype (StandardAttribute, AlpineAttribute, LivewireAttribute)
  
- `children: List<AstNode>` - Child nodes
  - Can contain: TextNode, DirectiveNode, EchoNode, ComponentNode, HtmlElementNode
  - Empty for void elements and self-closing tags
  
- `isSelfClosing: bool` - Used self-closing `/>`syntax
  - `true` if tag ends with `/>`
  - `false` for explicit closing tag or void elements
  
- `isVoid: bool` - Is void element (computed property)
  - Computed from tagName against void element set
  - Void elements: area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr
  
- `startPosition: Position` - Opening tag start location
  - Line, column, offset of `<` character
  
- `endPosition: Position` - Closing tag end location
  - For normal tags: position after `</tag>`
  - For self-closing: position after `/>`
  - For void: position after `>` or `/>`

**Invariants**:
1. If `isVoid == true` → `children.isEmpty`
2. If `isSelfClosing == true` → `children.isEmpty`
3. `tagName` matches `/^[a-zA-Z][a-zA-Z0-9-]*$/`
4. `attributes` keys are unique (case-sensitive)

**Validation Rules**:
- Void elements MUST NOT have closing tags
- Void elements MUST NOT have children
- Self-closing elements MUST NOT have closing tags
- Tag name MUST be valid HTML identifier

---

## Token Types (Extensions to existing TokenType enum)

### htmlTagOpen
- **Value**: Opening tag with name (e.g., `<div`)
- **Example**: `<div` in `<div class="foo">`
- **Emitted by**: Lexer when `<` + letter detected

### htmlTagClose  
- **Value**: Closing tag (e.g., `</div>`)
- **Example**: `</div>` in `<div></div>`
- **Emitted by**: Lexer when `</` + tagName + `>` detected

### htmlTagSelfClose
- **Value**: Self-closing marker `/>`
- **Example**: `/>` in `<br />`
- **Emitted by**: Lexer when `/>` detected in tag context

### htmlTagEnd
- **Value**: End of opening tag `>`
- **Example**: `>` in `<div class="foo">`
- **Emitted by**: Lexer when `>` detected in tag context

---

## Relationships

### HtmlElementNode → AttributeNode (1 to Many)
- One HTML element has zero or more attributes
- Attributes stored in map by name
- Attribute types: StandardAttribute, AlpineAttribute, LivewireAttribute

### HtmlElementNode → AstNode (1 to Many, recursive)
- One HTML element has zero or more child nodes
- Children can be any AstNode subtype including HtmlElementNode
- Forms tree structure

### HtmlElementNode → Position (2 positions)
- `startPosition`: Where opening tag begins
- `endPosition`: Where closing tag ends (or self-close)

---

## State Transitions

### Void Element Flow
```
<br> → htmlTagOpen("br") → htmlTagEnd(">") → HtmlElementNode(isVoid=true)
```

### Self-Closing Flow  
```
<div /> → htmlTagOpen("div") → htmlTagSelfClose("/>") → HtmlElementNode(isSelfClosing=true)
```

### Normal Element Flow
```
<div>...</div> → htmlTagOpen("div") → htmlTagEnd(">") → [children] → htmlTagClose("</div>") → HtmlElementNode
```

---

## JSON Serialization

**HtmlElementNode.toJson() output**:
```json
{
  "type": "htmlElement",
  "tagName": "div",
  "attributes": {
    "class": {
      "type": "standard",
      "name": "class",
      "value": "container"
    },
    "x-data": {
      "type": "alpine",
      "name": "x-data",
      "value": "{ open: false }"
    }
  },
  "isSelfClosing": false,
  "isVoid": false,
  "position": {
    "start": { "line": 1, "column": 1, "offset": 0 },
    "end": { "line": 3, "column": 7, "offset": 45 }
  },
  "children": [...]
}
```

---

**Ready for contract generation**
