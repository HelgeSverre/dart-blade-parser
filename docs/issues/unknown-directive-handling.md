# [DECISION] How should the parser handle unknown/custom Blade directives?

> **Posted to GitHub:** https://github.com/HelgeSverre/dart-blade-parser/issues/1
>
> This is the original draft. See the GitHub issue for updates and discussion.

## Problem Statement

The parser currently **silently discards** unknown Blade directives (like `@ifaasdf` or legitimate custom directives like `@datetime`). This behavior is problematic because:

1. **Typos disappear silently** - `@ifaasdf` (typo of `@if`) produces no errors or warnings
2. **Custom directives vanish from AST** - Valid custom directives registered via `Blade::directive()` are lost
3. **Orphaned closing tags** - An `@endif` after `@ifaasdf` may match the wrong block or get lost
4. **No developer feedback** - Users don't know if they made a typo or if the directive was preserved

## Current Behavior

**Test Case:**
```blade
<div class="dashboard">
    @foreach($widgets as $widget)
        @ifaasdf($widget->isVisible())  <!-- Unknown directive -->
            <div class="widget">
                <h3>{{ $widget->title }}</h3>
            </div>
        @endif                           <!-- Orphaned? -->
    @endforeach
</div>
```

**Current Output:**
- **Errors reported:** 0
- **AST result:** `@ifaasdf` completely missing from AST
- **`@endif` behavior:** Unclear - may match with `@foreach` or disappear

**Code Flow:**
1. Lexer (`lexer.dart:1458`): Unknown directives → `TokenType.identifier`
2. Parser (`parser.dart:257-259`): `TokenType.identifier` → `default` case → silently skipped with `return null`

```dart
default:
  _advance();  // Just skip it
  return null;
```

## Context & Background

### Laravel's Custom Directive System

Laravel allows developers to register **custom directives** that are perfectly valid:

```php
// Inline custom directive
Blade::directive('datetime', function ($expression) {
    return "<?php echo formatDate($expression); ?>";
});

// Block-style custom directive
Blade::directive('card', function ($expr) {
    return "<?php echo '<div class=\"card\">'; ?>";
});
Blade::directive('endcard', function () {
    return "<?php echo '</div>'; ?>";
});
```

**Usage in templates:**
```blade
{{-- Inline style --}}
@datetime($post->created_at)

{{-- Block style --}}
@card('primary')
  <h3>Title</h3>
  <p>Content</p>
@endcard
```

### Why This Is Complex

1. **Parser can't know** what's a typo vs a legitimate custom directive
2. **No runtime context** - Parser runs without knowing what's registered in Laravel
3. **Block detection is ambiguous** - Is `@foo` inline or does it need `@endfoo`?
4. **Must not break** - Custom directives are common in Laravel projects

## Expected/Desired Behavior

### Option 1: Parse as `CustomDirectiveNode` (Preserve Everything)

**Implementation:**
```dart
case TokenType.identifier:
  return _parseCustomDirective(); // New method

// CustomDirectiveNode extends DirectiveNode
// name: "ifaasdf"
// expression: "($widget->isVisible())"
// isCustom: true
```

**Pros:**
- ✅ Preserves all directive information in AST
- ✅ Allows formatters/linters to process custom directives
- ✅ Users can inspect AST and see what was parsed
- ✅ No information loss

**Cons:**
- ❌ No feedback for typos (e.g., `@ifaasdf` looks like valid custom directive)
- ❌ Complex: Need heuristics to detect if it's a block directive
- ❌ Closing tag matching becomes ambiguous (`@endif` for `@ifaasdf`?)

---

### Option 2: Parse with Warning (Non-Fatal Error)

**Implementation:**
```dart
case TokenType.identifier:
  _warnings.add(ParseWarning(
    message: "Unknown directive '@$name' - may be custom or typo",
    position: token.startPosition,
    hint: "If this is a custom directive, ignore this warning",
  ));
  return _parseCustomDirective();
```

**Pros:**
- ✅ Preserves directives in AST
- ✅ Gives developers feedback about potential typos
- ✅ Non-fatal - doesn't break parsing
- ✅ Can be suppressed per project (config option)

**Cons:**
- ❌ Warnings may be noisy for projects with many custom directives
- ❌ Requires new `ParseWarning` type separate from `ParseError`
- ❌ Users must configure to suppress warnings

---

### Option 3: Parse as Text (Downgrade to Content)

**Implementation:**
```dart
case TokenType.identifier:
  // Emit as text node instead
  return TextNode(
    content: '@$name$expression',
    startPosition: token.startPosition,
    endPosition: token.endPosition,
  );
```

**Pros:**
- ✅ Simple implementation
- ✅ Content is preserved (visible in output)
- ✅ Clear that parser doesn't understand it

**Cons:**
- ❌ Loses semantic meaning (not recognized as directive)
- ❌ Formatters can't process as directives
- ❌ No way to distinguish typo vs custom

---

### Option 4: Keep Current (Silent Skip) - Status Quo

**Pros:**
- ✅ Simple
- ✅ Parser doesn't fail on unknowns

**Cons:**
- ❌ Information loss - directives vanish
- ❌ No feedback for typos
- ❌ Confusing behavior

## Examples & Edge Cases

### Example 1: Typo in Built-in Directive
```blade
@ifaasdf($condition)
  Content
@endif
```

**Question:** Should this error? Warn? Or parse as custom?

---

### Example 2: Valid Custom Directive (Inline)
```blade
@datetime($post->created_at)
```

**Expected:** Parse as `CustomDirectiveNode`, preserve in AST

---

### Example 3: Valid Custom Directive (Block)
```blade
@card('primary')
  <h3>Card Title</h3>
@endcard
```

**Challenge:** Parser doesn't know `@card` needs `@endcard`. How to match them?

---

### Example 4: Orphaned Closing Tag
```blade
@ifaasdf($condition)
  Content
@endif
```

**Current:** `@ifaasdf` disappears, `@endif` may match wrong block
**Question:** Should parser track unmatched closing tags?

---

### Example 5: Similar Names
```blade
@customIf($condition)
  Content
@endif  <!-- Does this close @customIf? -->
```

**Challenge:** Is `@endif` the closer for `@customIf` or an orphan?

## Open Questions

1. **Block detection:** How do we know if `@foo` needs `@endfoo`?
   - Could use heuristic: directives with expressions are inline, without are block?
   - Or: always treat custom directives as inline unless `@endfoo` is found?

2. **Closing tag matching:** Should `@endif` match `@ifaasdf`?
   - Laravel doesn't - custom blocks need their own `@endX`
   - But parser doesn't know if `@ifaasdf` is typo or custom

3. **Warning vs Error:** If we add warnings, should they be:
   - On by default (opt-out)?
   - Off by default (opt-in)?
   - Configurable per project (`.blade.json`)?

4. **AST representation:** Should custom directives be:
   - A new `CustomDirectiveNode` type?
   - Regular `DirectiveNode` with `isCustom: true` flag?
   - Stay as text content?

5. **Backward compatibility:** If we change behavior, will it break existing users?

## Technical Considerations

**Performance Impact:**
- Minimal - already lexing these tokens
- Slight increase if adding block matching logic

**Breaking Changes:**
- Option 1-3 would ADD nodes to AST that were previously missing
- Shouldn't break existing users (they weren't using these nodes)
- May surprise users who assumed these would error

**Backward Compatibility:**
- Adding warnings is backward compatible (can be suppressed)
- Adding AST nodes is mostly compatible (additive)
- Changing to errors would be breaking

**Maintenance Burden:**
- Option 1 (Custom nodes): Moderate - need block matching logic
- Option 2 (Warnings): Low - straightforward
- Option 3 (Text): Low - simple downgrade
- Option 4 (Status quo): None

## Possible Implementation Approaches

### Approach A: Simple Custom Node (No Block Matching)

Treat all unknown directives as inline, add to AST:

```dart
DirectiveNode _parseCustomDirective() {
  final startToken = _advance();
  final name = startToken.value.substring(1); // Remove @
  final expression = _extractExpression();

  return DirectiveNode(
    startPosition: startToken.startPosition,
    endPosition: _previous().endPosition,
    name: name,
    expression: expression,
    children: [], // Always inline - no children
    isCustom: true, // New field
  );
}
```

**Pros:** Simple, preserves directives
**Cons:** Can't handle block-style custom directives

---

### Approach B: Smart Block Matching

Try to detect if a custom directive has a closer:

```dart
DirectiveNode _parseCustomDirective() {
  final startToken = _advance();
  final name = startToken.value.substring(1);
  final expression = _extractExpression();

  // Look ahead for @end{name}
  final closingName = 'end$name';
  if (_hasDirectiveAhead(closingName)) {
    // Parse as block
    return _parseGenericDirective(name, closingName);
  }

  // Parse as inline
  return DirectiveNode(..., children: []);
}
```

**Pros:** Handles both inline and block custom directives
**Cons:** Complex, requires lookahead, may be slow

---

### Approach C: Warning-Only (Keep Current + Warn)

```dart
default:
  if (token.type == TokenType.identifier &&
      token.value.startsWith('@')) {
    _warnings.add(ParseWarning(
      message: "Unknown directive '${token.value}'",
      position: token.startPosition,
    ));
  }
  _advance();
  return null;
```

**Pros:** Minimal change, gives feedback
**Cons:** Directives still disappear from AST

## Related Issues / References

- **Fixture:** `test/fixtures/error/malformed-dashboard.blade.php`
- [Laravel Blade Custom Directives](https://laravel.com/docs/11.x/blade#custom-directives)
- [Laravel Extending Blade](https://laravel.com/docs/11.x/blade#extending-blade)

## Community Input Needed

- [ ] Which approach do you prefer for handling unknown directives?
- [ ] Do you use custom directives in your Laravel projects?
- [ ] Would warnings be helpful or annoying?
- [ ] Should block-style custom directives be supported?

## Priority / Impact

- **Urgency:** Low - Current behavior is stable, this is enhancement
- **Impact:** Medium - Affects anyone using custom directives or making typos
- **Affects:** Custom directive users, developers debugging templates

---

**Decision Needed:** This issue requires design discussion before implementation. Community input welcome!

## Proposed Next Steps

1. **Gather feedback** from Laravel + Dart communities
2. **Run survey** - How common are custom directives?
3. **Prototype** Option 1 (CustomDirectiveNode) in separate branch
4. **Benchmark** performance impact of block matching
5. **Make decision** based on feedback and prototype results
