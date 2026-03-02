# Alpine.js x-data Attribute Formatting

## Problem

Alpine.js `x-data` attributes contain JavaScript object literals that the Blade formatter treats as opaque strings. This means expressions like:

```html
x-data="{ expanded: false,
    activeTrack: null,
    ...
}"
```

don't get properly formatted with consistent indentation and line breaks.

Similarly, `x-*` attributes with conditional directives don't receive proper tab-aligned formatting when wrapped.

## Approach

Post-process formatted output in the Prettier plugin layer (JS side only). After the Dart formatter produces clean Blade output, scan for Alpine attribute values and format them using Prettier's TypeScript parser.

### Why this approach

- Keeps the Dart formatter simple (no JS parsing needed)
- Leverages Prettier's battle-tested JS/TS parser
- Proven pattern used by prettier-plugin-django-alpine
- Graceful fallback: if Prettier can't parse a value, keep it unchanged

### Trade-off

Only works via Prettier plugin, not standalone `blade` CLI. This is acceptable because Alpine formatting requires a JS parser, which the Dart runtime doesn't have.

## Design

### Attribute categories

| Category | Attributes | Wrapping |
|----------|-----------|----------|
| Expression | `x-data`, `x-show`, `x-bind`, `x-text`, `x-html`, `x-model`, `x-modelable`, `x-if`, `x-id`, `:*` | Wrap as `() => (value)`, format, unwrap |
| Statement | `x-init`, `x-on`, `x-effect`, `@*` (not Blade directives) | Format as-is |

### The "wrap trick"

For expression attributes (which aren't valid JS programs on their own):

1. Wrap: `{ expanded: false }` becomes `() => ({ expanded: false })`
2. Format with `prettier.format(wrapped, { parser: "typescript" })`
3. Unwrap: strip `() =>` prefix and outer parentheses

### Detection

Regex-based scan of formatted output. Since the Dart formatter produces clean, consistent output, this is reliable:

```
(x-(?:data|show|bind|text|html|model|modelable|if|id)|:[\w-]+|@(?!if|unless|...)[\w.-]+|x-(?:init|on|effect))\s*=\s*(?:"([^"]*)"|'([^']*)')
```

Must exclude Blade directives (`@if`, `@foreach`, etc.) from the `@*` pattern.

### Short value handling

Values that format to a single short line (under ~60 chars) stay inline. Multi-line formatted values get indented to match their attribute position.

### Skip conditions

- Values containing Blade interpolation (`{{ }}`, `{!! !!}`) — not valid JS
- Empty values
- Values that Prettier fails to parse (graceful fallback)

### New option

- `bladeFormatAlpine` (boolean, default: `true`)

### Files to modify

- `prettier-plugin-laravel-blade/src/index.mjs` — add `formatAlpineAttributes()`, call in preprocess, add option

### Test cases

1. Simple `x-data="{ open: false }"` — stays on one line
2. Long `x-data="{ expanded: false, activeTrack: null, filters: [], ... }"` — breaks to multiple lines
3. `@click="open = !open"` — formats as JS statement
4. `x-show="open && !loading"` — stays on one line
5. `x-data` with Blade interpolation — skipped, preserved as-is
6. Invalid JS in attribute — preserved as-is (graceful fallback)
7. Nested objects in `x-data` — properly indented
8. Template literals in values — handled by Prettier
