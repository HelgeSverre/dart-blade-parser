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

# Run site e2e tests (Playwright)
[group('testing')]
e2e:
    node --test site/e2e/*.e2e.mjs

# Run benchmarks
[group('testing')]
bench:
    dart test test/performance/

# Run the acid test suite
[group('testing')]
acid:
    @echo "🧪 Running acid tests..."
    @cd tool/acid && dart acid_test.dart --format=both --open

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

# Run all checks (lint + format + tests)
[group('quality')]
check: lint test
    @echo "\n✅ All checks passed!"

# Formatting

# Format templates using blade CLI
[group('formatting')]
format-templates PATH:
    @echo "🎨 Formatting Blade templates..."
    dart run bin/blade.dart format {{ PATH }} --write --verbose

# Check if templates need formatting (for CI)
[group('formatting')]
check-templates PATH:
    @echo "🔍 Checking Blade template formatting..."
    dart run bin/blade.dart format {{ PATH }} --check

# Format test fixtures (for testing the formatter)
[group('formatting')]
format-fixtures:
    @echo "🎨 Formatting test fixtures..."
    dart run bin/blade.dart format "test/fixtures/format/*.blade.php" --write --verbose

# Reset test fixtures to their original messy state
[group('formatting')]
reset-fixtures:
    @echo "🔄 Resetting test fixtures to original state..."
    @git checkout -- test/fixtures/format/
    @echo "✅ Test fixtures reset"

# Show diff of formatting changes (without writing)
[group('formatting')]
show-format-diff:
    @echo "📊 Showing formatting changes..."
    @echo "\n=== 01-basic-messy.blade.php ==="
    @dart run bin/blade.dart format test/fixtures/format/01-basic-messy.blade.php | diff -u test/fixtures/format/01-basic-messy.blade.php - || true
    @echo "\n=== 02-indentation-chaos.blade.php ==="
    @dart run bin/blade.dart format test/fixtures/format/02-indentation-chaos.blade.php | diff -u test/fixtures/format/02-indentation-chaos.blade.php - || true
    @echo "\n=== 03-whitespace-hell.blade.php ==="
    @dart run bin/blade.dart format test/fixtures/format/03-whitespace-hell.blade.php | diff -u test/fixtures/format/03-whitespace-hell.blade.php - || true

# Dependencies

# Get dependencies
[group('dependencies')]
deps:
    dart pub get

# Upgrade dependencies
[group('dependencies')]
deps-upgrade:
    dart pub upgrade

# Show outdated dependencies
[group('dependencies')]
deps-outdated:
    dart pub outdated

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

# Clean build artifacts
[group('build')]
clean:
    @rm -rf .dart_tool/ build/ coverage/ *.html

# Documentation

# Generate API documentation
[group('docs')]
docs:
    @echo "📚 Generating API documentation..."
    @dart doc
    @echo "✅ Documentation generated in doc/api/"

# Publishing

# Publish dry-run (check what would be published)
[group('publish')]
publish-check:
    dart pub publish --dry-run

# Full pre-publish check
[group('publish')]
pre-publish: clean deps lint test publish-check
    @echo "\n✅ All pre-publish checks passed! Ready to publish."

# Development Tools

# Run the playground demo
[group('dev')]
playground:
    @echo "🎮 Running playground..."
    @cd tool/playground && fvm flutter pub get && fvm flutter run -d chrome

# Build playground for web
[group('dev')]
build-playground:
    @echo "🔨 Building playground for web..."
    @cd tool/playground && fvm flutter build web --release --wasm && cd ../..
    @echo "📋 Copying vercel.json to build output..."
    @cp tool/playground/web/vercel.json tool/playground/build/web/
    @echo "✅ Playground built: tool/playground/build/web/"

# Deploy playground to Vercel
[group('dev')]
deploy-playground: build-playground
    @echo "🚀 Deploying playground to Vercel..."
    @cd tool/playground/build/web && vercel --prod
    @echo "✅ Playground deployed!"

# Prettier Plugin

# Build the Prettier plugin (compile Dart to JS)
[group('prettier')]
prettier-build:
    @bash prettier-plugin-laravel-blade/scripts/build.sh

# Run Prettier plugin tests
[group('prettier')]
prettier-test: prettier-build
    @cd prettier-plugin-laravel-blade && npm test

# Install Prettier plugin dependencies
[group('prettier')]
prettier-install:
    @cd prettier-plugin-laravel-blade && npm install

# Publish the Prettier plugin to npm (builds, tests, then publishes)
[group('prettier')]
prettier-publish: prettier-test
    @cd prettier-plugin-laravel-blade && npm publish

# Benchmark

# Sync test fixtures into benchmark/fixtures/
[group('benchmark')]
bench-sync:
    @echo "Syncing fixtures from test/fixtures/ to benchmark/fixtures/..."
    @rsync -a --delete --exclude='invalid/' --exclude='malformed/' --exclude='index.md' --exclude='README.md' test/fixtures/ benchmark/fixtures/
    @echo "Synced $(find benchmark/fixtures -name '*.blade.php' | wc -l | tr -d ' ') fixtures."

# Install benchmark dependencies
[group('benchmark')]
bench-install:
    @cd benchmark && npm install

# Run the full benchmark comparison
[group('benchmark')]
bench-plugins: bench-install
    @cd benchmark && node run.mjs --full --json

# Run performance benchmark only
[group('benchmark')]
bench-plugins-perf: bench-install
    @cd benchmark && node run.mjs --perf-only

# Run idempotency check only
[group('benchmark')]
bench-plugins-idempotency: bench-install
    @cd benchmark && node run.mjs --idempotency-only

# Quick benchmark (fewer runs, faster feedback)
[group('benchmark')]
bench-quick: bench-install
    @cd benchmark && node run.mjs --perf-only --runs 5 --warmup 1

# Site

# Build site (copy benchmark data for pages to consume)
[group('site')]
site-build:
    @echo "Copying benchmark data to site..."
    @mkdir -p site/data site/dist
    @cp benchmark/results/benchmark.json site/data/benchmark.json
    @cp prettier-plugin-laravel-blade/dist/blade-formatter.js site/dist/blade-formatter.js
    @echo "Site built. Serve with: just site-serve"

# Serve site locally
[group('site')]
site-serve: site-build
    @cd site && npx -y serve .

# Open site in browser
[group('site')]
site-open:
    @open site/index.html

# Deploy site to Vercel (builds benchmark data, then deploys)
[group('site')]
site-deploy: site-build
    @echo "Deploying site to Vercel..."
    @cd site && vercel --prod
    @echo "Site deployed."
