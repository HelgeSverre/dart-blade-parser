# dart-blade-parser - Development Tasks
# Modern task runner using just (https://github.com/casey/just)

# List all available commands
default:
    @just --list

# Run all tests
test:
    dart test

# Run tests with verbose output
test-verbose:
    dart test --reporter expanded

# Run specific test file
test-file FILE:
    dart test {{FILE}}

# Run tests matching a pattern
test-name NAME:
    dart test --name "{{NAME}}"

# Generate code coverage report (lcov format) - continues even if tests fail
coverage:
    @echo "🧪 Running tests with coverage..."
    @dart test --coverage=coverage || true
    @echo "📊 Formatting coverage data..."
    @dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    @echo "✅ Coverage report generated: coverage/lcov.info"

# Generate HTML coverage report and open in browser
coverage-html: coverage
    @echo "🌐 Generating HTML report..."
    @genhtml coverage/lcov.info -o coverage/html --quiet
    @echo "✅ HTML report generated: coverage/html/index.html"
    @open coverage/html/index.html

# Generate coverage with filtered output (exclude generated files)
coverage-clean:
    @echo "🧪 Running tests with coverage..."
    @dart test --coverage=coverage || true
    @echo "📊 Formatting coverage data..."
    @dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    @echo "🧹 Removing generated files from coverage..."
    @lcov --remove coverage/lcov.info \
        '*.g.dart' \
        '*.freezed.dart' \
        '**/*.g.dart' \
        '**/*.freezed.dart' \
        -o coverage/lcov.info
    @echo "✅ Cleaned coverage report: coverage/lcov.info"

# Show coverage summary in terminal
coverage-summary: coverage
    @echo "\n📈 Coverage Summary:"
    @lcov --summary coverage/lcov.info

# Check if coverage meets minimum threshold (e.g., 90%)
coverage-check THRESHOLD="90":
    @echo "🎯 Checking coverage threshold (minimum {{THRESHOLD}}%)..."
    @just coverage-summary
    @COVERAGE=$$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $$2}' | sed 's/%//'); \
    echo "Current coverage: $${COVERAGE}%"; \
    if (( $$(echo "$${COVERAGE} < {{THRESHOLD}}" | bc -l) )); then \
        echo "❌ Coverage $${COVERAGE}% is below threshold {{THRESHOLD}}%"; \
        exit 1; \
    else \
        echo "✅ Coverage $${COVERAGE}% meets threshold {{THRESHOLD}}%"; \
    fi

# Clean coverage artifacts
coverage-clean-artifacts:
    @echo "🧹 Cleaning coverage artifacts..."
    @rm -rf coverage/
    @echo "✅ Coverage artifacts removed"

# Run linter
lint:
    dart analyze

# Apply automatic fixes
fix:
    dart fix --apply

# Format code
format:
    dart format .

# Format and check for changes (useful in CI)
format-check:
    dart format --set-exit-if-changed .

# Run all checks (lint + format check + tests)
check: lint format-check test

# Run benchmarks
bench:
    dart test test/performance/

# Run specific benchmark
bench-file FILE:
    dart test {{FILE}}

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    @rm -rf .dart_tool/
    @rm -rf build/
    @rm -rf coverage/
    @rm -rf *.html
    @echo "✅ Build artifacts cleaned"

# Get dependencies
deps:
    dart pub get

# Upgrade dependencies
deps-upgrade:
    dart pub upgrade

# Show outdated dependencies
deps-outdated:
    dart pub outdated

# Publish dry-run (check what would be published)
publish-check:
    dart pub publish --dry-run

# Lint only lib/ directory (focused library checks)
lint-lib:
    dart analyze lib/

# Run dart fix without applying (preview changes)
fix-dry:
    dart fix --dry-run

# Count remaining lint issues
lint-count:
    @echo "Counting lint issues..."
    @dart analyze 2>&1 | grep -E "(info|warning|error)" | wc -l | xargs echo "Total issues:"

# Show only errors and warnings (not info)
lint-strict:
    @dart analyze 2>&1 | grep -E "(error|warning)" || echo "✅ No errors or warnings!"

# Generate API documentation
docs:
    @echo "📚 Generating API documentation..."
    @dart doc
    @echo "✅ Documentation generated in doc/api/"

# Full pre-publish check (everything needed before publishing)
pre-publish: clean deps lint format-check test publish-check
    @echo "\n✅ All pre-publish checks passed! Ready to publish."

# Quick iteration check (format, fix, test)
quick-check: format fix test
    @echo "\n✅ Quick checks passed!"

# Full CI pipeline locally (for passing tests only)
ci: deps lint format-check
    @echo "\n✅ All CI checks passed!"
