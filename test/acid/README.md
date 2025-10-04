# 🧪 Blade Parser Acid Test

A comprehensive test suite that validates the Blade template parser against all 104 fixture files.

## Quick Start

```bash
# Run with console output (default)
dart test/acid/acid_test.dart

# Generate HTML report only
dart test/acid/acid_test.dart --format=html

# Generate both console and HTML output
dart test/acid/acid_test.dart --format=both

# Specify custom HTML output path
dart test/acid/acid_test.dart --format=html --output=my_report.html
```

## What It Tests

The acid test runs the lexer and parser on every `.blade.php` file in `test/fixtures/` and reports:

### Per-Fixture Metrics
- ✅ **Lexing Success** - Did tokenization complete without errors?
- ✅ **Parsing Success** - Did parsing complete successfully?
- ✅ **Token Count** - How many tokens were generated?
- ✅ **Node Count** - How many AST nodes were created?
- ✅ **AST Depth** - Maximum nesting level in the tree
- ✅ **Performance** - Time spent in lexer and parser (microsecond precision)
- ✅ **Errors** - Parse errors with line/column information

### Aggregate Metrics
- 📊 **Pass Rate** - Percentage of fixtures that parsed successfully
- 📊 **Token Coverage** - Which TokenTypes are actually tested
- 📊 **Directive Coverage** - Which @directives are tested
- 📊 **Performance Profile** - Total time, average time per file
- 📊 **Category Breakdown** - Success rate by fixture category

## Console Output

The console reporter features:
- **Color-coded results** using ANSI escape codes
- **Unicode art** for beautiful formatting
- **Progress bars** showing token/directive usage
- **Summary statistics** in a bordered box
- **Failure details** with error messages and hints

Example output:
```
╔════════════════════════════════════════════════════════╗
║       🧪 BLADE PARSER ACID TEST RESULTS                ║
╚════════════════════════════════════════════════════════╝

📊 SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Total Fixtures:     104
  ✅ Passed:          91  (87.5%)
  ❌ Failed:          13  (12.5%)

  ⏱️  Total Time:       52.6ms
  📈 Avg Time:         506μs/file
  🔢 Total Tokens:     57.6k
  🌳 Total Nodes:      35.1k
```

## HTML Report

The HTML reporter generates a standalone, responsive report with:
- **Summary cards** showing key metrics
- **Category breakdown** table with progress bars
- **Coverage analysis** with token and directive usage
- **Visual charts** (CSS-only, no JavaScript dependencies)
- **Detailed results** table with all fixtures
- **Failure details** with expandable error messages
- **Print-friendly** styles for documentation
- **Dark mode** toggle (future enhancement)

Reports are saved to `test/acid/reports/acid_test_report_TIMESTAMP.html`

## Coverage Analysis

The acid test calculates:

### Token Type Coverage
- Total unique token types used across all fixtures
- Percentage of defined token types that are tested
- Top 10 most frequently used tokens

### Directive Coverage
- Total unique directives encountered
- Percentage of defined Blade directives tested
- Top 10 most frequently used directives

### Expected Results

Different fixture categories have different success criteria:

| Category | Expected Result |
|----------|----------------|
| `valid/` | Should parse successfully (100% pass) |
| `invalid/` | Should detect errors (expected to fail) |
| `edge_cases/` | Should handle gracefully (100% pass) |
| `alpine/` | Should parse Alpine.js syntax (100% pass) |
| `livewire/` | Should parse Livewire attributes (100% pass) |
| `components/` | Should parse Blade components (100% pass) |

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed
- `2` - Invalid arguments or missing fixtures

## Architecture

```
test/acid/
├── acid_test.dart              # Main entry point
├── acid_runner.dart            # Core test execution logic
├── models/
│   ├── fixture_info.dart       # Fixture metadata
│   ├── test_result.dart        # Individual test results
│   └── coverage_report.dart    # Coverage analysis
├── reporters/
│   ├── console_reporter.dart   # Colorful terminal output
│   └── html_reporter.dart      # Standalone HTML reports
├── utils/
│   └── fixture_scanner.dart    # Auto-discover fixtures
└── reports/                    # Generated HTML reports
```

## Use Cases

### Daily Development
Run quickly to check what's working:
```bash
dart test/acid/acid_test.dart
```

### Before Merge/PR
Generate full report for documentation:
```bash
dart test/acid/acid_test.dart --format=both
```

### Coverage Gaps
Identify untested features:
```bash
dart test/acid/acid_test.dart | grep "COVERAGE"
```

### Performance Regression
Track if parsing got slower:
```bash
# Save baseline
dart test/acid/acid_test.dart > baseline.txt

# After changes, compare
dart test/acid/acid_test.dart > current.txt
diff baseline.txt current.txt
```

### CI Integration
Use in continuous integration:
```yaml
# .github/workflows/test.yml
- name: Run Acid Test
  run: |
    dart test/acid/acid_test.dart --format=html
    # Upload HTML report as artifact
```

## Adding Test Fixtures

To improve coverage, add `.blade.php` files to `test/fixtures/`:

1. **valid/** - Templates that should parse successfully
2. **invalid/** - Malformed templates (test error handling)
3. **edge_cases/** - Tricky syntax that might break
4. **alpine/** - Alpine.js specific features
5. **livewire/** - Livewire specific features
6. **components/** - Blade component syntax

The acid test will automatically discover and test new fixtures.

## Performance Targets

Current performance (as of 2025-10-05):
- **Total Time**: ~50ms for 104 fixtures
- **Average Time**: ~500μs per file
- **Throughput**: ~2000 files/second

Target performance:
- Average time should stay under 1ms per file
- Total time for 100 fixtures should be under 100ms

## Known Limitations

The acid test currently:
- ✅ Tests lexer and parser functionality
- ✅ Validates error reporting
- ✅ Measures performance
- ❌ Does not validate semantic correctness of AST
- ❌ Does not test code generation from AST
- ❌ Does not test incremental/streaming parsing

## Future Enhancements

Potential additions:
- [ ] Baseline comparison (detect regressions)
- [ ] Fixture metadata (expected token counts, etc.)
- [ ] Watch mode (auto-run on file changes)
- [ ] Memory usage tracking
- [ ] AST semantic validation
- [ ] Performance trend graphs
- [ ] GitHub Actions integration
- [ ] Coverage badges

## License

Part of the dart-blade-parser project.
