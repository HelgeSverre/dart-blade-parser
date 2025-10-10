# Code Coverage Guide

This project uses modern Dart code coverage tools with an easy-to-use `just` task runner interface.

## Quick Start

```bash
# Generate coverage report
just coverage-summary

# Generate and view HTML report in browser
just coverage-html
```

## Current Coverage

**Line Coverage: 78.5%** (1348 of 1718 lines)

## Available Commands

### Basic Coverage Commands

- **`just coverage`** - Generate lcov coverage report
  - Runs all tests with coverage instrumentation
  - Generates `coverage/lcov.info`
  - Continues even if some tests fail

- **`just coverage-summary`** - Show coverage summary in terminal
  - Quick way to see overall coverage percentage
  - Shows number of lines covered

- **`just coverage-html`** - Generate HTML report and open in browser
  - Creates interactive HTML report in `coverage/html/`
  - Automatically opens in your default browser
  - Shows line-by-line coverage with color coding

### Advanced Coverage Commands

- **`just coverage-clean`** - Generate coverage excluding generated files
  - Filters out `*.g.dart` and `*.freezed.dart` files
  - Useful for projects using code generation
  - Currently no generated files in this project

- **`just coverage-check 90`** - Check if coverage meets threshold
  - Fails if coverage is below specified percentage
  - Useful for CI/CD pipelines
  - Example: `just coverage-check 80` (checks for 80% minimum)

- **`just coverage-clean-artifacts`** - Remove all coverage files
  - Cleans up `coverage/` directory
  - Useful for fresh coverage runs

## Understanding the Reports

### Terminal Summary

```
Reading tracefile coverage/lcov.info.
Summary coverage rate:
  source files: 11
  lines.......: 78.5% (1348 of 1718 lines)
```

- **source files**: Number of files with coverage data
- **lines**: Percentage of executable lines that were executed during tests

### HTML Report

The HTML report (`coverage/html/index.html`) provides:
- **Green lines**: Executed during tests
- **Red lines**: Not executed (need more test coverage)
- **Gray lines**: Non-executable (comments, blank lines)
- **File-by-file breakdown**: Click to see detailed coverage per file

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      
      - name: Install dependencies
        run: dart pub get
      
      - name: Run tests with coverage
        run: |
          dart test --coverage=coverage
          dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
      
      - name: Check coverage threshold
        run: |
          sudo apt-get install -y lcov
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
          echo "Coverage: ${COVERAGE}%"
          if (( $(echo "${COVERAGE} < 80" | bc -l) )); then
            echo "Coverage ${COVERAGE}% is below 80%"
            exit 1
          fi
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
```

### Using with `just` in CI

```yaml
- name: Install just
  run: cargo install just

- name: Run coverage check
  run: just coverage-check 80
```

## Improving Coverage

### Identify Low Coverage Files

Run `just coverage-html` and look at the HTML report to see which files have low coverage.

### Focus Areas

1. **Error handling paths** - Test error conditions
2. **Edge cases** - Boundary conditions, empty inputs
3. **Branching logic** - All if/else paths
4. **Loop variations** - Empty loops, single iteration, many iterations

### Example: Improving Lexer Coverage

```dart
// Before: Only testing happy path
test('tokenize simple text', () {
  final lexer = BladeLexer('Hello World');
  final tokens = lexer.tokenize();
  expect(tokens, hasLength(1));
});

// After: Testing edge cases
test('tokenize empty string', () {
  final lexer = BladeLexer('');
  final tokens = lexer.tokenize();
  expect(tokens, isEmpty);
});

test('tokenize with error recovery', () {
  final lexer = BladeLexer('<>'); // Empty tag
  final tokens = lexer.tokenize();
  expect(tokens.any((t) => t.type == TokenType.error), isTrue);
});
```

## Coverage Badges

### For GitHub README

Use [Codecov](https://codecov.io/) or [Coveralls](https://coveralls.io/):

```markdown
![Coverage](https://codecov.io/gh/username/dart-blade-parser/branch/main/graph/badge.svg)
```

### Local Badge Generation

Use [coverage-badge](https://pub.dev/packages/coverage_badge):

```bash
dart pub global activate coverage_badge
dart pub global run coverage_badge
```

## Troubleshooting

### Coverage files not generated

**Problem**: `coverage/` directory is empty

**Solution**: Ensure tests are running:
```bash
dart test --coverage=coverage
ls -la coverage/
```

### "Some tests failed" but need coverage anyway

**Problem**: Tests fail but you still want coverage report

**Solution**: Commands use `|| true` to continue:
```bash
just coverage  # Already handles test failures
```

### Low coverage on specific file

**Problem**: A file shows 0% or very low coverage

**Solution**: 
1. Check if the file is tested at all
2. Look at the HTML report to see which lines are missing
3. Add tests targeting those specific code paths

### HTML report won't open

**Problem**: `just coverage-html` doesn't open browser

**Solution**: Manually open the file:
```bash
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

## Tools Used

- **`dart test --coverage`** - Built-in Dart test coverage
- **`coverage` package** - Format coverage data to lcov
- **`lcov`** - Process and analyze coverage data
- **`genhtml`** - Generate HTML coverage reports
- **`just`** - Modern command runner (alternative to Make)

## Further Reading

- [Dart Testing Documentation](https://dart.dev/guides/testing)
- [Coverage Package](https://pub.dev/packages/coverage)
- [LCOV Documentation](https://ltp.sourceforge.net/coverage/lcov.php)
- [Just Command Runner](https://github.com/casey/just)

## Goals

- **Target**: 90%+ line coverage
- **Current**: 78.5% line coverage
- **Gap**: ~200 more lines need test coverage

To reach 90%, focus on:
1. Parser error recovery paths
2. Lexer edge cases (unicode, escape sequences)
3. Streaming parser implementation
4. AST visitor patterns
