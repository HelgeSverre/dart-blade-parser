# Data Model: Laravel Blade Template Parser

**Feature**: Laravel Blade Template Parser
**Date**: 2025-10-04
**Phase**: Phase 1 - Design

---

## Entity Models

### 1. Token

**Purpose**: Atomic lexical unit representing a piece of Blade syntax

**Fields**:
- `type: TokenType` - Enum identifying the token category
- `value: String` - Raw text content of the token
- `startLine: int` - 1-based line number where token starts
- `startColumn: int` - 1-based column number where token starts
- `endLine: int` - 1-based line number where token ends
- `endColumn: int` - 1-based column number where token ends
- `startOffset: int` - 0-based character offset from file start
- `endOffset: int` - 0-based character offset from file start

**Validation Rules**:
- `startLine ≥ 1`, `startColumn ≥ 1`
- `endLine ≥ startLine`
- `endColumn ≥ startColumn` if on same line
- `startOffset ≥ 0`, `endOffset > startOffset`
- `value` must not be null (can be empty string for structural tokens)

**TokenType Enum Values**:
```
// Blade Directives - Control Flow
directiveIf, directiveElseif, directiveElse, directiveEndif,
directiveUnless, directiveEndunless,
directiveSwitch, directiveCase, directiveDefault, directiveEndswitch,
directiveIsset, directiveEmpty,

// Blade Directives - Loops
directiveFor, directiveEndfor,
directiveForeach, directiveEndforeach,
directiveForelse, directiveEndforelse,
directiveWhile, directiveEndwhile,
directiveContinue, directiveBreak,

// Blade Directives - Template Inheritance
directiveExtends, directiveSection, directiveEndsection,
directiveYield, directiveParent, directiveShow, directiveOverwrite,

// Blade Directives - Stacks
directivePush, directiveEndpush,
directivePrepend, directiveEndprepend,
directiveStack,
directivePushOnce, directiveEndPushOnce,
directivePushIf,
directivePrependOnce, directiveEndPrependOnce,

// Blade Directives - Components
directiveComponent, directiveEndcomponent,
directiveSlot, directiveEndslot,
directiveProps, directiveAware,

// Blade Directives - Includes
directiveInclude, directiveIncludeIf, directiveIncludeWhen,
directiveIncludeUnless, directiveIncludeFirst,
directiveEach,

// Blade Directives - Special
directiveOnce, directiveEndonce,
directivePhp, directiveEndphp,
directiveVerbatim, directiveEndverbatim,

// Blade Directives - Authentication & Authorization
directiveAuth, directiveEndauth,
directiveGuest, directiveEndguest,
directiveCan, directiveEndcan,
directiveCannot, directiveEndcannot,
directiveCanany, directiveEndcanany,

// Blade Directives - Environment
directiveEnv, directiveEndenv,
directiveProduction, directiveEndproduction,
directiveSession, directiveEndsession,

// Blade Directives - Debugging
directiveDd, directiveDump,

// Blade Directives - Validation
directiveError, directiveEnderror,

// Blade Directives - Section Conditionals
directiveHasSection, directiveSectionMissing,

// Blade Directives - HTML Attributes
directiveClass, directiveStyle,
directiveChecked, directiveSelected,
directiveDisabled, directiveReadonly, directiveRequired,

// Blade Directives - Assets & Data
directiveJson, directiveMethod, directiveCsrf, directiveVite,

// Blade Directives - Service Injection
directiveInject,

// Blade Directives - Modern Features
directiveFragment, directiveEndfragment,
directiveUse,

// Echo Statements
echoOpen,        // {{
echoClose,       // }}
rawEchoOpen,     // {!!
rawEchoClose,    // !!}
legacyEchoOpen,  // {{{
legacyEchoClose, // }}}
bladeEscape,     // @{{

// Components
componentTagOpen,       // <x-
componentTagClose,      // </x-
componentSelfClose,     // />
componentSlotOpen,      // <x-slot:
componentSlotClose,     // </x-slot>

// Alpine.js Attributes
alpineData, alpineInit, alpineShow, alpineIf, alpineFor,
alpineModel, alpineText, alpineHtml, alpineBind, alpineOn,
alpineTransition, alpineCloak, alpineIgnore, alpineRef, alpineTeleport,
alpineShorthandBind,   // :attribute
alpineShorthandOn,     // @event

// Livewire Attributes
livewireClick, livewireSubmit, livewireKeydown, livewireKeyup,
livewireMouseenter, livewireMouseleave,
livewireModel, livewireModelLive, livewireModelBlur,
livewireModelDebounce, livewireModelLazy, livewireModelDefer,
livewireLoading, livewireTarget, livewireLoadingClass,
livewireLoadingRemove, livewireLoadingAttr,
livewirePoll, livewirePollKeepAlive, livewirePollVisible,
livewireIgnore, livewireKey, livewireId, livewireInit,
livewireDirty, livewireOffline,
livewireNavigate, livewireTransition, livewireStream,

// Livewire Directives
directiveEntangle, directiveThis, directiveJs,

// Literals & Identifiers
text,           // Plain text content
whitespace,     // Whitespace (may be significant)
identifier,     // Variable/function names
expression,     // PHP expression content
stringLiteral,  // Quoted strings
numberLiteral,  // Numeric literals

// Structural
bladeComment,   // {{-- comment --}}
htmlComment,    // <!-- comment -->
eof,            // End of file
error           // Lexing error
```

---

### 2. AstNode (Abstract)

**Purpose**: Base class for all AST node types

**Fields**:
- `startPosition: Position` - Start location in source
- `endPosition: Position` - End location in source
- `parent: AstNode?` - Parent node (null for root)
- `children: List<AstNode>` - Child nodes (empty for leaf nodes)

**Methods**:
- `accept<T>(visitor: AstVisitor<T>): T` - Visitor pattern
- `toJson(): Map<String, dynamic>` - JSON serialization

**Node Types** (sealed class hierarchy):
- DocumentNode
- DirectiveNode
- ComponentNode
- EchoNode
- TextNode
- HtmlElementNode
- CommentNode
- ErrorNode

---

### 3. Position

**Purpose**: Source code location information

**Fields**:
- `line: int` - 1-based line number
- `column: int` - 1-based column number
- `offset: int` - 0-based character offset from file start

**Validation Rules**:
- `line ≥ 1`, `column ≥ 1`, `offset ≥ 0`

---

### 4. DocumentNode extends AstNode

**Purpose**: Root node containing entire parsed template

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- No additional fields

**Validation Rules**:
- `parent` must be null (root node)
- `children` contains all top-level nodes

---

### 5. DirectiveNode extends AstNode

**Purpose**: Represents Blade directive (@if, @foreach, etc.)

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `name: String` - Directive name (e.g., "if", "foreach")
- `expression: String?` - Unparsed PHP expression/condition
- `hasClosingTag: bool` - Whether directive has closing tag (@endif, @endforeach)
- `closingTagPosition: Position?` - Position of closing tag if present
- `elseBranch: DirectiveNode?` - @else/@elseif node (for conditionals)
- `hasError: bool` - True if unclosed or malformed

**Validation Rules**:
- `name` must not be empty
- If `hasClosingTag` is true, `closingTagPosition` must not be null
- `elseBranch` only valid for @if/@elseif/@unless directives
- If `hasError` is true, node represents partial/incomplete AST

**Examples**:
```
@if($user->isAdmin())          → name="if", expression="$user->isAdmin()", hasClosingTag=true
@foreach($items as $item)      → name="foreach", expression="$items as $item", hasClosingTag=true
@continue($item->skip)         → name="continue", expression="$item->skip", hasClosingTag=false
@csrf                          → name="csrf", expression=null, hasClosingTag=false
```

---

### 6. ComponentNode extends AstNode

**Purpose**: Represents Blade component (tag or directive syntax)

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `name: String` - Component name (e.g., "alert", "button")
- `attributes: Map<String, AttributeNode>` - Component attributes
- `slots: Map<String, SlotNode>` - Named slots (includes "default")
- `isSelfClosing: bool` - True for <x-component />

**Validation Rules**:
- `name` must not be empty
- Must have "default" slot if has children not in named slots
- If `isSelfClosing` is true, no closing tag

**Examples**:
```
<x-alert type="error">Text</x-alert>
→ name="alert", attributes={"type": "error"}, slots={"default": SlotNode}

<x-card>
  <x-slot:header>Title</x-slot>
  Content
</x-card>
→ name="card", slots={"header": SlotNode, "default": SlotNode}
```

---

### 7. AttributeNode (Sealed Class Hierarchy)

**Purpose**: Represents HTML/component attribute

**Base Fields**:
- `name: String` - Attribute name
- `value: String?` - Attribute value (null for boolean attributes)

**Subtypes**:

#### StandardAttribute extends AttributeNode
- No additional fields
- Example: `class="btn"`, `disabled`

#### AlpineAttribute extends AttributeNode
- `directive: String` - Alpine.js directive (e.g., "data", "show", "click")
- Example: `x-data="{open: false}"` → directive="data", value="{open: false}"

#### LivewireAttribute extends AttributeNode
- `action: String` - Livewire action (e.g., "click", "model")
- `modifiers: List<String>` - Modifiers (e.g., ["prevent", "live"])
- Example: `wire:click.prevent="save"` → action="click", modifiers=["prevent"], value="save"

**Validation Rules**:
- `name` must not be empty
- AlpineAttribute: `directive` must match known Alpine.js directive
- LivewireAttribute: `action` must match known Livewire action

---

### 8. SlotNode extends AstNode

**Purpose**: Named slot content within component

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `name: String` - Slot name ("default" for unnamed slot)
- `attributes: Map<String, AttributeNode>` - Slot attributes

**Validation Rules**:
- `name` must not be empty
- Default slot has name "default"

---

### 9. EchoNode extends AstNode

**Purpose**: Represents echo statement ({{ }}, {!! !!}, {{{ }}})

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `expression: String` - Unparsed PHP expression
- `isRaw: bool` - True for {!! !!}, false for {{ }}
- `isLegacy: bool` - True for {{{ }}} (deprecated escaped syntax)

**Validation Rules**:
- `expression` must not be empty
- `children` must be empty (leaf node)
- If `isLegacy` is true, `isRaw` must be false

**Examples**:
```
{{ $user->name }}          → expression="$user->name", isRaw=false, isLegacy=false
{!! $html !!}              → expression="$html", isRaw=true, isLegacy=false
{{{ $old }}}               → expression="$old", isRaw=false, isLegacy=true
```

---

### 10. TextNode extends AstNode

**Purpose**: Plain text content

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `content: String` - Text content

**Validation Rules**:
- `children` must be empty (leaf node)
- `content` may be empty string

---

### 11. HtmlElementNode extends AstNode

**Purpose**: HTML element (not a Blade component)

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `tagName: String` - HTML tag name (e.g., "div", "span")
- `attributes: Map<String, AttributeNode>` - Element attributes
- `isSelfClosing: bool` - True for <br />, <img />, etc.
- `isVoid: bool` - True for void elements (<br>, <img>, <meta>, etc.)

**Validation Rules**:
- `tagName` must not be empty
- Void elements must not have children
- If `isVoid` is true, `isSelfClosing` should be true

---

### 12. CommentNode extends AstNode

**Purpose**: Blade or HTML comment

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `content: String` - Comment text
- `isBladeComment: bool` - True for {{-- --}}, false for <!-- -->

**Validation Rules**:
- `children` must be empty (leaf node)
- Blade comments removed from output, HTML comments preserved

---

### 13. ErrorNode extends AstNode

**Purpose**: Marker for parse error location in AST

**Fields**:
- Inherits: `startPosition`, `endPosition`, `parent`, `children`
- `error: ParseError` - Associated error details
- `partialContent: String?` - Partial parsed content if available

**Validation Rules**:
- Always has `hasError` flag set
- Used for error recovery (FR-026)

---

### 14. ParseError

**Purpose**: Represents parsing error with location and severity

**Fields**:
- `message: String` - Human-readable error description
- `position: Position` - Location where error occurred
- `severity: ErrorSeverity` - Error or Warning
- `hint: String?` - Optional suggestion for fixing
- `sourceContext: String?` - Surrounding source code for context

**Validation Rules**:
- `message` must not be empty
- `severity` must be Error or Warning

**ErrorSeverity Enum Values**:
- `error` - Syntax violation preventing correct interpretation
- `warning` - Deprecated syntax or best practice violation

**Examples**:
```
ParseError(
  message: "Unclosed @if directive starting at line 15, column 3",
  position: Position(line: 15, column: 3, offset: 432),
  severity: ErrorSeverity.error,
  hint: "Add @endif to close the conditional block",
  sourceContext: "15: @if(\$condition)\n16:   <p>Content</p>\n17: "
)
```

---

### 15. ParseResult

**Purpose**: Container for parsing output

**Fields**:
- `ast: DocumentNode?` - Root AST node (null if parsing completely failed)
- `errors: List<ParseError>` - All parsing errors
- `warnings: List<ParseError>` - All parsing warnings
- `isSuccess: bool` - True if no errors (warnings allowed)

**Validation Rules**:
- If `ast` is null, `errors` must not be empty
- If `isSuccess` is true, `errors` must be empty
- `ast` may contain ErrorNode children even if `isSuccess` is true (partial recovery)

**State Transitions**:
```
Input → Lexer → Tokens → Parser → ParseResult
                          ↓
                     (errors) → ErrorNode in AST

ParseResult.isSuccess:
  - true: ast != null, errors.isEmpty
  - false: errors.isNotEmpty (ast may be partial or null)
```

---

## Entity Relationships

```
DocumentNode (root)
  ├─ DirectiveNode
  │   ├─ expression: String
  │   ├─ elseBranch: DirectiveNode?
  │   └─ children: List<AstNode>
  ├─ ComponentNode
  │   ├─ attributes: Map<String, AttributeNode>
  │   │   ├─ StandardAttribute
  │   │   ├─ AlpineAttribute
  │   │   └─ LivewireAttribute
  │   ├─ slots: Map<String, SlotNode>
  │   │   └─ children: List<AstNode>
  │   └─ children: List<AstNode>
  ├─ EchoNode
  │   └─ expression: String
  ├─ TextNode
  │   └─ content: String
  ├─ HtmlElementNode
  │   ├─ attributes: Map<String, AttributeNode>
  │   └─ children: List<AstNode>
  ├─ CommentNode
  │   └─ content: String
  └─ ErrorNode
      └─ error: ParseError

ParseResult
  ├─ ast: DocumentNode?
  ├─ errors: List<ParseError>
  └─ warnings: List<ParseError>

Token
  ├─ type: TokenType
  ├─ value: String
  └─ startPosition, endPosition: Position
```

---

## JSON Serialization Schema

### DocumentNode
```json
{
  "type": "document",
  "position": {"start": {...}, "end": {...}},
  "children": [...]
}
```

### DirectiveNode
```json
{
  "type": "directive",
  "name": "if",
  "expression": "$user->isAdmin()",
  "position": {"start": {...}, "end": {...}},
  "hasClosingTag": true,
  "closingTagPosition": {...},
  "children": [...],
  "elseBranch": {...} // optional
}
```

### ComponentNode
```json
{
  "type": "component",
  "name": "alert",
  "attributes": {
    "type": {"type": "standard", "name": "type", "value": "error"}
  },
  "slots": {
    "default": {"type": "slot", "name": "default", "children": [...]}
  },
  "position": {"start": {...}, "end": {...}},
  "isSelfClosing": false
}
```

### EchoNode
```json
{
  "type": "echo",
  "expression": "$user->name",
  "isRaw": false,
  "isLegacy": false,
  "position": {"start": {...}, "end": {...}}
}
```

### ParseError
```json
{
  "message": "Unclosed @if directive",
  "severity": "error",
  "position": {"line": 15, "column": 3, "offset": 432},
  "hint": "Add @endif to close the conditional block",
  "sourceContext": "15: @if($condition)\n..."
}
```

---

## Performance Characteristics

### Memory Footprint (per FR-028)
- Token: ~80 bytes (7 fields × ~10 bytes + string overhead)
- Position: ~24 bytes (3 int fields)
- AstNode (avg): ~120 bytes (base fields + polymorphic data)
- Typical 5000-line file:
  - Tokens: ~50,000 tokens × 80 bytes = ~4MB
  - AST: ~25,000 nodes × 120 bytes = ~3MB
  - Total: ~7MB << 100MB limit ✅

### Traversal Complexity
- Tree depth: O(nesting level) - max 20 per FR-030
- Children iteration: O(n) where n = number of children
- Visitor pattern: O(total nodes)

---

**Data Model Status**: ✅ Complete
**Aligned with FR-015 through FR-020**: ✅ Yes
**Ready for Contract Generation**: ✅ Yes
