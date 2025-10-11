# dart-blade-parser Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-05

## Active Technologies
- Dart 3.0+ (latest stable) + Zero external parsing libraries (pure Dart standard library) (001-create-a-laravel)
- HTML element parsing: State-based lexer tokenization, void element recognition, mixed attribute support (002-enhanced-html-parsing)
- Dart 3.0+ (SDK: '>=3.0.0 <4.0.0') + Zero external parsing dependencies (pure Dart standard library per constitution) (003-implement-complete-html)
- N/A (parser operates in-memory on source text) (003-implement-complete-html)

## Project Structure
```
lib/src/
├── lexer/        # HTML tag tokenization (002)
├── parser/       # HTML element parsing (002)
└── ast/          # HtmlElementNode (001, enhanced in 002)

test/
├── contract/     # HTML API contracts (002)
├── integration/  # HTML integration tests (002)
└── unit/         # HTML unit tests (002)
```

## Commands
# Add commands for Dart 3.0+ (latest stable)

## Code Style
Dart 3.0+ (latest stable): Follow standard conventions

## Recent Changes
- 003-implement-complete-html: Added Dart 3.0+ (SDK: '>=3.0.0 <4.0.0') + Zero external parsing dependencies (pure Dart standard library per constitution)
- 002-enhanced-html-parsing: Added HTML element parsing with void elements, self-closing syntax, mixed attributes
- 001-create-a-laravel: Completed Blade parser (75+ directives, streaming mode, 100 tests passing)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
