# Blade Prettier Plugin Benchmark

Reproducible benchmark comparing three Prettier plugins for Laravel Blade
templates. Measures formatting performance and idempotency across 109 real-world
fixtures synced from the project test suite.

## Plugins Compared

| Label | Plugin | Version |
|-------|--------|---------|
| A | `prettier-plugin-laravel-blade` (this project) | 0.1.0 |
| B | `prettier-plugin-blade` (stillat) | 2.1.21 |
| C | `@shufo/prettier-plugin-blade` (shufo) | 1.16.1 |

## Latest Results

### Performance (20 runs, 3 warmup)

| Plugin | Avg (ms) | vs A |
|--------|----------|------|
| A | 0.33 | -- |
| B | 7.31 | 22x slower |
| C | 10.45 | 32x slower |

### Idempotency

| Plugin | Pass | Fail | Error |
|--------|------|------|-------|
| A | 104 | 0 | 3 |
| B | 91 | 4 | 12 |
| C | 104 | 1 | 2 |

A "fail" means formatting the output a second time produces a different result.
An "error" means the plugin crashed or timed out on that fixture -- it does not
indicate the fixture is invalid.

## Prerequisites

- Node.js >= 18
- The prettier plugin must be built first: `just prettier-build` (from project root)

## Setup

```bash
# Sync fixtures from test/fixtures/ (excludes invalid/malformed, skips files >100KB)
just bench-sync

# Install benchmark dependencies
just bench-install
```

## Running

```bash
# Full benchmark (performance + idempotency)
just bench-plugins

# Performance only
just bench-plugins-perf

# Idempotency only
just bench-plugins-idempotency

# Quick run (fewer iterations, useful during development)
just bench-quick
```

## CLI Options

The benchmark runner (`run.mjs`) accepts the following arguments:

| Flag | Description | Default |
|------|-------------|---------|
| `--runs N` | Number of timed runs per fixture | 20 |
| `--warmup N` | Number of warmup runs (excluded from stats) | 3 |
| `--filter PATTERN` | Only run fixtures matching the pattern | all |
| `--plugin LABEL` | Only run a specific plugin (A, B, or C) | all |
| `--timeout MS` | Per-fixture timeout in milliseconds | (default) |
| `--max-size BYTES` | Skip fixtures larger than this size | 100000 |
| `--json` | Write machine-readable results to `results/` | off |
| `--help` | Show usage information | -- |

## Fixtures

The `fixtures/` directory is gitignored — run `just bench-sync` to populate it
from `test/fixtures/`. The sync excludes `invalid/`, `malformed/`, `index.md`,
and `README.md`. One fixture exceeding 100KB is skipped at runtime.

## Output

Results are written to `results/` (gitignored):

- `benchmark.json` -- machine-readable results (when `--json` is passed)
- `*.A.txt`, `*.B.txt`, `*.C.txt` -- formatted output from each plugin per fixture

## Architecture

Each plugin runs in an isolated child process (`worker.mjs`) rather than being
loaded into the main benchmark process. This ensures that if a plugin triggers
an out-of-memory crash or an unhandled exception, it does not take down the
benchmark runner. The main process spawns a worker per fixture per plugin,
collects the result or error, and aggregates the statistics.
