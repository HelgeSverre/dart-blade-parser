# prettier-plugin-laravel-blade

Prettier plugin for formatting Laravel Blade templates, powered by a real AST parser.

Unlike regex-based alternatives, this plugin uses a full recursive-descent parser that correctly handles:
- 108 Blade directives (`@if`, `@foreach`, `@auth`, `@switch`, `@push`, `@section`, etc.)
- Blade components (`<x-alert>`) with named slots and nested content
- Alpine.js attributes (`x-data`, `@click`, `:bind`, `x-show`, `x-transition`)
- Livewire attributes (`wire:model`, `wire:click`, `wire:poll`)
- Echo statements (`{{ }}`, `{!! !!}`)
- Nested and interleaved HTML/Blade structures
- Error recovery for malformed templates

## Install

```bash
npm install --save-dev prettier-plugin-laravel-blade prettier
```

## Usage

The plugin automatically formats `.blade.php` files:

```bash
# Format all Blade files
prettier --write "**/*.blade.php"

# Check formatting (CI)
prettier --check "**/*.blade.php"
```

Or configure in `.prettierrc`:

```json
{
  "plugins": ["prettier-plugin-laravel-blade"],
  "overrides": [
    {
      "files": "*.blade.php",
      "options": {
        "tabWidth": 4,
        "printWidth": 120,
        "bladeSlotFormatting": "compact",
        "bladeSlotNameStyle": "colon",
        "bladeSlotSpacing": "after",
        "bladeWrapAttributes": "auto",
        "bladeAttributeSort": "by_type",
        "bladeSelfClosingStyle": "preserve"
      }
    }
  ]
}
```

## Options

### Standard Prettier Options

| Option | Default | Description |
|--------|---------|-------------|
| `tabWidth` | `4` | Number of spaces per indentation level |
| `useTabs` | `false` | Use tabs instead of spaces |
| `printWidth` | `120` | Line width before wrapping attributes |

### Blade-Specific Options

| Option | Default | Choices | Description |
|--------|---------|---------|-------------|
| `bladeQuoteStyle` | `"preserve"` | `single`, `double`, `preserve` | `'` vs `"` in attribute values |
| `bladeDirectiveSpacing` | `"between_blocks"` | `between_blocks`, `none`, `preserve` | Blank lines between `@if`, `@foreach`, etc. |
| `bladeSlotFormatting` | `"compact"` | `compact`, `block` | Extra newlines inside `<x-slot>` blocks |
| `bladeSlotNameStyle` | `"colon"` | `colon`, `attribute`, `preserve` | `<x-slot:name>` vs `<x-slot name="...">` |
| `bladeSlotSpacing` | `"after"` | `none`, `after`, `before`, `around` | Blank lines before/after `<x-slot>` tags |
| `bladeWrapAttributes` | `"auto"` | `auto`, `always`, `never` | Multi-line attributes when line is too long |
| `bladeAttributeSort` | `"none"` | `none`, `alphabetical`, `by_type` | Reorder attributes (HTML, Alpine, Livewire) |
| `bladeClosingBracketStyle` | `"same_line"` | `same_line`, `new_line` | Where `>` sits when attributes wrap |
| `bladeSelfClosingStyle` | `"preserve"` | `preserve`, `always`, `never` | `<x-icon />` vs `<x-icon></x-icon>` for empty tags |

## How It Works

This plugin compiles a Dart-based Blade parser/formatter to JavaScript via `dart2js`, running entirely in-process with zero IPC overhead. The parser produces a full AST and the formatter is idempotent and deterministic.

## License

MIT
