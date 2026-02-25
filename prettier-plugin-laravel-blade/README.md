# prettier-plugin-laravel-blade

Prettier plugin for formatting Laravel Blade templates, powered by a real AST parser.

Unlike regex-based alternatives, this plugin uses a full recursive-descent parser that correctly handles:
- 108 Blade directives
- Blade components (`<x-alert>`) with slots
- Alpine.js attributes (`x-data`, `@click`, `:bind`)
- Livewire attributes (`wire:model`, `wire:click`)
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

# Check formatting
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
        "printWidth": 120
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
| `bladeQuoteStyle` | `"preserve"` | `single`, `double`, `preserve` | Quote style for HTML attributes |
| `bladeDirectiveSpacing` | `"between_blocks"` | `between_blocks`, `none`, `preserve` | Spacing between directive blocks |
| `bladeSlotFormatting` | `"compact"` | `compact`, `block` | Formatting style for component slots |
| `bladeWrapAttributes` | `"auto"` | `auto`, `always`, `never` | When to wrap attributes to multiple lines |
| `bladeAttributeSort` | `"none"` | `none`, `alphabetical`, `by_type` | How to sort HTML attributes |
| `bladeClosingBracketStyle` | `"same_line"` | `same_line`, `new_line` | Closing bracket position when attributes wrap |
| `bladeSelfClosingStyle` | `"preserve"` | `preserve`, `always`, `never` | How to format empty elements |

## How It Works

This plugin compiles a Dart-based Blade parser/formatter to JavaScript (via `dart2js`), running entirely in-process with zero IPC overhead. The parser produces a full AST and the formatter is idempotent and deterministic.

## License

MIT
