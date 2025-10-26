# Formatter Test Fixtures

This directory contains **intentionally badly formatted** Blade templates
used for testing the formatter.

## Purpose

These files are committed in their "messy" state and serve as:

- **Integration tests** for the formatter
- **Visual regression tests** to ensure formatting is consistent
- **Real-world examples** of formatting issues the formatter should fix

## Usage

### Format the fixtures:

```bash
just format-fixtures
```

### Reset to original messy state:

```bash
just reset-fixtures
```

### View formatting changes without writing:

```bash
just show-format-diff
```

## Files

- **01-basic-messy.blade.php** - Basic whitespace/spacing issues
- **02-indentation-chaos.blade.php** - Inconsistent indentation
- **03-whitespace-hell.blade.php** - Excessive blank lines
- **04-nested-directives-ugly.blade.php** - Deep nesting, no formatting
- **05-components-messy.blade.php** - Components with bad formatting
- **06-mixed-content.blade.php** - HTML + Blade + Alpine.js
- **07-real-world-mess.blade.php** - Realistic legacy code
- **08-edge-cases.blade.php** - Unusual but valid syntax

## Note

**Do not manually format these files!** They must remain messy for testing.
Use `git checkout` to restore if accidentally formatted.
