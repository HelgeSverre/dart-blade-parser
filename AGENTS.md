# dart-blade-parser Agent Guidelines

## Commands
- **Test all**: `dart test`
- **Test single file**: `dart test test/unit/parser/directive_parser_test.dart`
- **Analyze**: `dart analyze`
- **Format**: `dart format .`
- **Coverage**: `dart test --coverage=coverage && dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib`

## Architecture
- **Pure Dart parser** for Laravel Blade templates (Dart 3.0+, SDK: '>=3.0.0 <4.0.0')
- **Zero external parsing dependencies** - uses only Dart standard library
- **Structure**: `lib/src/{lexer,parser,ast,error,streaming}/`
  - `lexer/` - HTML tag and Blade directive tokenization
  - `parser/` - Blade directive, component, and HTML element parsing
  - `ast/` - AST nodes (directives, components, HTML elements, echo statements)
  - `error/` - Error handling with recovery
  - `streaming/` - Incremental parsing for large files
- **Tests**: `test/{contract,integration,unit,performance}/`

## Code Style (per analysis_options.yaml)
- **Strict mode**: strict-casts, strict-inference, strict-raw-types enabled
- **Quotes**: Single quotes (`prefer_single_quotes`)
- **Return types**: Always declare (`always_declare_return_types`)
- **Finals**: Prefer final fields and locals (`prefer_final_fields`, `prefer_final_locals`)
- **Documentation**: Public members must have API docs (`public_member_api_docs`)
- **No print statements** in library code (`avoid_print`)
