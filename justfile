# dart-blade-parser - Development Tasks

# List all available commands
default:
    @just --list

# Run all tests
test:
    dart test

# Run specific test file
test-file FILE:
    dart test {{ FILE }}

# Run tests matching a pattern
test-name NAME:
    dart test --name "{{ NAME }}"

# Generate coverage report and show summary
coverage:
    @echo "🧪 Running tests with coverage..."
    @dart test --coverage=coverage || true
    @echo "📊 Formatting coverage data..."
    @dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    @echo "\n📈 Coverage Summary:"
    @lcov --summary coverage/lcov.info

# Generate HTML coverage report and open in browser
coverage-html: coverage
    @echo "🌐 Generating HTML report..."
    @genhtml coverage/lcov.info -o coverage/html --quiet
    @echo "✅ HTML report generated: coverage/html/index.html"
    @open coverage/html/index.html

# Run linter
lint:
    dart analyze

# Apply automatic fixes and format code
fix:
    dart fix --apply
    dart format .

# Run all checks (lint + format + tests)
check: lint test
    @echo "\n✅ All checks passed!"

# Run benchmarks
bench:
    dart test test/performance/

# Clean build artifacts
clean:
    @rm -rf .dart_tool/ build/ coverage/ *.html

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

# Generate API documentation
docs:
    @echo "📚 Generating API documentation..."
    @dart doc
    @echo "✅ Documentation generated in doc/api/"

# Full pre-publish check
pre-publish: clean deps lint test publish-check
    @echo "\n✅ All pre-publish checks passed! Ready to publish."

# Compile for current platform
compile:
    @echo "🔧 Compiling for current platform..."
    @mkdir -p build
    @dart compile exe bin/blade_parser.dart -o build/blade-parser
    @echo "✅ Compilation completed: build/blade-parser"

# Cross-compile for multiple platforms
cross-compile:
    @echo "🔧 Cross-compiling for multiple platforms..."
    @mkdir -p build
    @dart compile exe bin/blade_parser.dart -o build/blade-linux-x64 --target-os linux --target-arch x64
    @dart compile exe bin/blade_parser.dart -o build/blade-linux-arm64 --target-os linux --target-arch arm64
    @dart compile exe bin/blade_parser.dart -o build/blade-macos-arm64 --target-os macos --target-arch arm64
    @echo "✅ Cross-compilation completed. Binaries are in the build/ directory."

# Run the playground demo
playground:
    @echo "🎮 Running playground..."
    @cd tool/playground && fvm flutter pub get && fvm flutter run -d chrome

# Run the acid test suite
acid:
    @echo "🧪 Running acid tests..."
    @cd tool/acid && dart acid_test.dart --format=both --open

# Format templates using blade_formatter CLI
format-templates PATH:
    @echo "🎨 Formatting Blade templates..."
    dart run bin/blade_formatter.dart {{ PATH }} --write --verbose

# Check if templates need formatting (for CI)
check-templates PATH:
    @echo "🔍 Checking Blade template formatting..."
    dart run bin/blade_formatter.dart {{ PATH }} --check

# Format test fixtures (for testing the formatter)
format-fixtures:
    @echo "🎨 Formatting test fixtures..."
    dart run bin/blade_formatter.dart "test/fixtures/format/*.blade.php" --write --verbose

# Reset test fixtures to their original messy state
reset-fixtures:
    @echo "🔄 Resetting test fixtures to original state..."
    @git checkout -- test/fixtures/format/
    @echo "✅ Test fixtures reset"

# Show diff of formatting changes (without writing)
show-format-diff:
    @echo "📊 Showing formatting changes..."
    @echo "\n=== 01-basic-messy.blade.php ==="
    @dart run tool/format_file.dart test/fixtures/format/01-basic-messy.blade.php | diff -u test/fixtures/format/01-basic-messy.blade.php - || true
    @echo "\n=== 02-indentation-chaos.blade.php ==="
    @dart run tool/format_file.dart test/fixtures/format/02-indentation-chaos.blade.php | diff -u test/fixtures/format/02-indentation-chaos.blade.php - || true
    @echo "\n=== 03-whitespace-hell.blade.php ==="
    @dart run tool/format_file.dart test/fixtures/format/03-whitespace-hell.blade.php | diff -u test/fixtures/format/03-whitespace-hell.blade.php - || true
