# Edge Cases and Known Limitations

**Last Updated:** 2026-02-26

This document catalogs known limitations and future enhancement ideas for the dart-blade-parser.

---

## Known Limitations

- ⚠️ True streaming parser not implemented (placeholder only)
- ⚠️ PHP expression formatting not implemented
- ⚠️ Mismatched component tag names (e.g., `<x-alert></x-button>`) may not produce errors in all cases

---

## Future Enhancements

### Formatter

- **Format Range** — Format only a selection/range instead of whole file. Useful for editor integrations.
- **Trailing Comma in Attributes** — Option to add trailing comma when attributes are wrapped.

### Linter

- **Linter Rules** — Require @csrf in forms, warn on raw echo `{!! !!}` usage (security), check max nesting depth, enforce consistent component naming, detect unclosed directives.
- **Unused Slot Detection** — Warn when a slot is defined but never filled.
- **Component Prop Validation** — Check that required props are passed to components.

### Integrations

- **Prettier Plugin** — Research integration strategies (CLI wrapper vs dart2js vs LSP). Implement adapter for Prettier API. Publish as npm package.
- **VS Code Extension** — Format on save, configuration file support, hover documentation for directives, status bar integration, diagnostics panel for linter warnings.

### Analysis

- **Include/Extends Graph** — Build dependency tree of template relationships. Visualize @extends and @include chains.

### Parser

- **Improve `_isDirectiveContext()`** — Consider adding quote-aware tag detection. Handle `@` inside CSS/JavaScript strings more robustly. Current implementation works for 99%+ of cases.
- **Enhance Component Tag Name Validation** — Improve error position for mismatched component tags.
