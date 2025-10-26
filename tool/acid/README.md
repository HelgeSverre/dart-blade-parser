# Blade Parser Acid Test

A comprehensive test tool that parses all fixture files and reports the results.

## Purpose

The Acid Test is a diagnostic tool (not a regular test suite) that:

- Scans all Blade template fixtures in `test/fixtures/`
- Attempts to parse each one
- Reports successes, failures, and parsing statistics
- Generates detailed HTML reports

## Usage

```bash
# Run with console output (default)
dart tools/acid/acid_test.dart

# Generate HTML report only
dart tools/acid/acid_test.dart --format=html

# Generate both console and HTML output
dart tools/acid/acid_test.dart --format=both

# Custom output path for HTML report
dart tools/acid/acid_test.dart --format=html --output=reports/my_report.html
```

## Options

- `--format=console` - Print colored console output (default)
- `--format=html` - Generate HTML report only
- `--format=both` - Generate both console and HTML output
- `--output=path` - Custom path for HTML report (default: `tools/acid/reports/acid_test_report_TIMESTAMP.html`)

## Output

The tool provides:

- **Console Output**: Color-coded results showing which fixtures passed/failed
- **HTML Report**: Detailed interactive report with:
  - Overall statistics
  - Per-fixture parsing results
  - Error details with line/column information
  - AST visualization for successful parses

## Why "Acid Test"?

Like the acid test in metallurgy that determines gold purity, this tool stress-tests the parser against a comprehensive suite of real-world Blade templates to validate its robustness and completeness.
