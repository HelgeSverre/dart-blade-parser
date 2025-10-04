# Test Fixtures

Real-world Laravel Blade template files collected from production projects for parser testing.

## Directory Structure

```
fixtures/
├── small/          # Simple templates (1-20 lines)
├── medium/         # Medium complexity (20-50 lines)
├── large/          # Complex templates (50+ lines)
├── livewire/       # Templates with Livewire attributes (wire:click, wire:model, etc.)
├── alpine/         # Templates with Alpine.js attributes (x-data, x-show, @click, etc.)
└── components/     # Templates with Blade components (<x-component>)
```

## File Statistics

| Category    | Files | Size Range | Features |
|-------------|-------|------------|----------|
| small       | 2     | 1-16 lines | Basic directives, simple components |
| medium      | 2     | 27-47 lines | Nested structures, slots |
| large       | 1     | 178 lines | Complex pagination with multiple directives |
| livewire    | 2     | 55-68 lines | wire:click, wire:model, wire:loading |
| alpine      | 2     | 55-115 lines | x-data, x-show, @click, Alpine expressions |
| components  | 2     | 29-171 lines | Blade components with attributes and slots |

## Coverage

These fixtures cover:

- **Blade Directives**: @if, @foreach, @section, @yield, @include, @extends, @component, @slot, @props
- **Echo Statements**: {{ }}, {{{ }}}, {!! !!}
- **Comments**: {{-- --}}
- **Components**: <x-component>, <x-slot>
- **Alpine.js**: x-data, x-show, x-if, x-model, @click, :class
- **Livewire**: wire:click, wire:model, wire:loading, wire:submit, wire:poll
- **Nested Structures**: Up to 5+ levels of nesting
- **Mixed Syntax**: HTML + Blade + Alpine.js + Livewire in single templates

## Source Projects

Files sourced from real Laravel applications:
- chatflow
- reflow
- boatflow
- unlimit
- crescat
- kassalapp

All vendor and node_modules files excluded.

## Usage

These fixtures should be used for:

1. **Unit Tests**: Test individual parser components (lexer, tokenizer, AST builder)
2. **Integration Tests**: Full parsing pipeline tests
3. **Performance Benchmarks**: Measure parsing speed and memory usage
4. **Regression Tests**: Ensure parser changes don't break existing functionality
5. **Error Recovery Tests**: Validate error handling with malformed templates

## Adding New Fixtures

When adding fixtures, ensure:
- No sensitive data (credentials, API keys, personal information)
- Representative of real-world usage patterns
- Diverse syntax coverage
- Clear categorization (size, feature set)
