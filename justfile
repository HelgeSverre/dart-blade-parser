# dart-blade-parser - Development Tasks

# List all available commands
default:
    @just --list

# Testing

# Run all tests
[group('testing')]
test:
    dart test

# Run specific test file
[group('testing')]
test-file FILE:
    dart test {{ FILE }}

# Run tests matching a pattern
[group('testing')]
test-name NAME:
    dart test --name "{{ NAME }}"

# Run performance benchmarks (Dart unit tests)
[group('testing')]
test-perf:
    dart test test/performance/

# Run the acid test suite
[group('testing')]
acid:
    @echo "🧪 Running acid tests..."
    @cd tool/acid && dart acid_test.dart --format=both --open

# Spot-check stress fixtures (parse, format, idempotency, content)
[group('testing')]
spot-check *ARGS:
    dart run tool/spot_check.dart {{ ARGS }}

# Generate coverage report and show summary
[group('testing')]
coverage:
    @echo "🧪 Running tests with coverage..."
    @dart test --coverage=coverage || true
    @echo "📊 Formatting coverage data..."
    @dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
    @echo "\n📈 Coverage Summary:"
    @lcov --summary coverage/lcov.info

# Generate HTML coverage report and open in browser
[group('testing')]
coverage-html: coverage
    @echo "🌐 Generating HTML report..."
    @genhtml coverage/lcov.info -o coverage/html --quiet
    @echo "✅ HTML report generated: coverage/html/index.html"
    @open coverage/html/index.html

# Code Quality

# Run linter
[group('quality')]
lint:
    dart analyze

# Apply automatic fixes and format code
[group('quality')]
fix:
    dart fix --apply
    dart format .

# Run all checks (lint + tests)
[group('quality')]
check: lint test
    @echo "\n✅ All checks passed!"

# Format Blade templates
[group('quality')]
format PATH:
    @echo "🎨 Formatting Blade templates..."
    dart run bin/blade.dart format {{ PATH }} --write --verbose

# Check if templates need formatting (for CI)
[group('quality')]
format-check PATH:
    @echo "🔍 Checking Blade template formatting..."
    dart run bin/blade.dart format {{ PATH }} --check

# Format test fixtures (for testing the formatter)
[group('quality')]
format-fixtures:
    @echo "🎨 Formatting test fixtures..."
    dart run bin/blade.dart format "test/fixtures/format/*.blade.php" --write --verbose

# Reset test fixtures to their original messy state
[group('quality')]
reset-fixtures:
    @echo "🔄 Resetting test fixtures to original state..."
    @git checkout -- test/fixtures/format/
    @echo "✅ Test fixtures reset"

# Dependencies & Setup

# Get dependencies
[group('dev')]
deps:
    dart pub get

# Upgrade dependencies
[group('dev')]
deps-upgrade:
    dart pub upgrade

# Show outdated dependencies
[group('dev')]
deps-outdated:
    dart pub outdated

# Generate API documentation
[group('dev')]
docs:
    @echo "📚 Generating API documentation..."
    @dart doc
    @echo "✅ Documentation generated in doc/api/"

# Clean build artifacts
[group('dev')]
clean:
    @rm -rf .dart_tool/ build/ coverage/ *.html

# Build & Compile

# Compile for current platform
[group('build')]
compile:
    @echo "🔧 Compiling for current platform..."
    @mkdir -p build
    @dart compile exe bin/blade.dart -o build/blade
    @echo "✅ Compilation completed: build/blade"

# Cross-compile for multiple platforms
[group('build')]
cross-compile:
    @echo "🔧 Cross-compiling for multiple platforms..."
    @mkdir -p build
    @dart compile exe bin/blade.dart -o build/blade-linux-x64 --target-os linux --target-arch x64
    @dart compile exe bin/blade.dart -o build/blade-linux-arm64 --target-os linux --target-arch arm64
    @dart compile exe bin/blade.dart -o build/blade-macos-arm64 --target-os macos --target-arch arm64
    @echo "✅ Cross-compilation completed. Binaries are in the build/ directory."

# Publishing

# Publish dry-run (check what would be published)
[group('publish')]
publish-check:
    dart pub publish --dry-run

# Full pre-publish check
[group('publish')]
pre-publish: clean deps lint test publish-check
    @echo "\n✅ All pre-publish checks passed! Ready to publish."

# Flutter AST playground (not the site formatter)

[private]
playground:
    @echo "🎮 Running playground..."
    @cd tool/playground && fvm flutter pub get && fvm flutter run -d chrome

[private]
playground-build:
    @echo "🔨 Building playground for web..."
    @cd tool/playground && fvm flutter build web --release --wasm && cd ../..
    @echo "📋 Copying vercel.json to build output..."
    @cp tool/playground/web/vercel.json tool/playground/build/web/
    @echo "✅ Playground built: tool/playground/build/web/"

[private]
playground-deploy: playground-build
    @echo "🚀 Deploying playground to Vercel..."
    @cd tool/playground/build/web && vercel --prod
    @echo "✅ Playground deployed!"

# Prettier Plugin

# Build the Prettier plugin (compile Dart to JS)
[group('plugin')]
plugin-build:
    @bash prettier-plugin-laravel-blade/scripts/build.sh

# Run Prettier plugin tests
[group('plugin')]
plugin-test: plugin-build
    @cd prettier-plugin-laravel-blade && npm test

# Install Prettier plugin dependencies
[group('plugin')]
plugin-install:
    @cd prettier-plugin-laravel-blade && npm install

# Publish the Prettier plugin to npm (builds, tests, then publishes)
[group('plugin')]
plugin-publish: plugin-test
    @cd prettier-plugin-laravel-blade && npm publish

# Benchmark

# Sync curated fixtures into benchmark/fixtures/ (from benchmark/curated.txt)
[group('benchmark')]
bench-sync:
    @echo "Syncing curated fixtures from test/fixtures/ to benchmark/fixtures/..."
    @rm -rf benchmark/fixtures
    @while IFS= read -r f; do mkdir -p "benchmark/fixtures/$(dirname "$f")" && cp "test/fixtures/$f" "benchmark/fixtures/$f"; done < benchmark/curated.txt
    @echo "Synced $(find benchmark/fixtures -name '*.blade.php' | wc -l | tr -d ' ') fixtures."

# Install benchmark dependencies
[group('benchmark')]
bench-install:
    @cd benchmark && npm install

# Run the full benchmark comparison
[group('benchmark')]
bench: bench-install bench-sync
    @cd benchmark && node run.mjs --full --json

# Run performance benchmark only
[group('benchmark')]
bench-perf: bench-install bench-sync
    @cd benchmark && node run.mjs --perf-only

# Run idempotency check only
[group('benchmark')]
bench-idempotency: bench-install bench-sync
    @cd benchmark && node run.mjs --idempotency-only

# Quick benchmark (fewer runs, faster feedback)
[group('benchmark')]
bench-quick: bench-install bench-sync
    @cd benchmark && node run.mjs --perf-only --runs 5 --warmup 1

# Site

# Full pipeline: build plugin, run benchmarks, build site, serve locally
[group('site')]
site-dev: plugin-build bench site-build
    @cd site && npx -y serve .

# Build site (copy benchmark data for pages to consume)
[group('site')]
site-build:
    @echo "Copying benchmark data to site..."
    @mkdir -p site/data site/dist
    @cp benchmark/results/benchmark.json site/data/benchmark.json
    @cp prettier-plugin-laravel-blade/dist/blade-formatter.js site/dist/blade-formatter.js
    @echo "Site built."

# Run site tests
[group('site')]
site-test:
    node --test site/tests/*.mjs

# Deploy site to Vercel
[group('site')]
site-deploy: site-build
    @echo "Deploying site to Vercel..."
    @cd site && vercel --prod
    @echo "Site deployed."
