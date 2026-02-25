import { readFileSync, readdirSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { fork } from 'node:child_process';
import chalk from 'chalk';
import Table from 'cli-table3';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── Colors per plugin ──
const colors = {
  A: chalk.hex('#b5f542'),  // ours — acid green
  B: chalk.hex('#60a5fa'),  // stillat — blue
  C: chalk.hex('#fbbf24'),  // shufo — yellow
};
const dim = chalk.dim;
const bold = chalk.bold;

// Plugin configurations
const plugins = [
  {
    name: 'prettier-plugin-laravel-blade',
    short: 'A',
    loadPath: join(__dirname, '..', 'prettier-plugin-laravel-blade', 'src', 'index.mjs'),
    parser: 'blade',
  },
  {
    name: 'prettier-plugin-blade',
    short: 'B',
    loadPath: 'prettier-plugin-blade',
    parser: 'blade',
  },
  {
    name: '@shufo/prettier-plugin-blade',
    short: 'C',
    loadPath: '@shufo/prettier-plugin-blade',
    parser: 'blade',
  },
];

// Directories to skip (invalid/malformed templates that are expected to fail)
const SKIP_DIRS = new Set(['invalid', 'malformed']);

// ── CLI arg parsing ──
const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
${bold('Usage:')} node run.mjs [options]

${bold('Mode (pick one, default: --full):')}
  --full              Run performance + idempotency + output comparison
  --perf-only         Run performance benchmark only
  --idempotency-only  Run idempotency check only

${bold('Tuning:')}
  --runs <n>          Timed runs per fixture (default: 100)
  --warmup <n>        Warmup runs per fixture (default: 5)
  --filter <pattern>  Only run fixtures whose name contains <pattern>
  --plugin <A|B|C>    Only benchmark a specific plugin (A=ours, B=stillat, C=shufo)
  --timeout <s>       Per-format timeout in seconds (default: 30)
  --max-size <kb>     Skip fixtures larger than <kb> kilobytes (default: 100)

${bold('Output:')}
  --json              Write results to benchmark/results/benchmark.json
  --help, -h          Show this help

${bold('Examples:')}
  node run.mjs --perf-only --runs 10 --warmup 1
  node run.mjs --filter kitchen --plugin A
  node run.mjs --idempotency-only --filter alpine
  node run.mjs --full --json

${bold('Note:')} Competitor plugins can OOM on many fixtures. Use npm scripts
  (which pass --max-old-space-size=8192) or run directly with:
  node --max-old-space-size=8192 run.mjs [options]
`);
  process.exit(0);
}

function getArgValue(flag) {
  const i = args.indexOf(flag);
  return i !== -1 && i + 1 < args.length ? args[i + 1] : null;
}

const perfOnly = args.includes('--perf-only');
const idempotencyOnly = args.includes('--idempotency-only');
const full = args.includes('--full') || (!perfOnly && !idempotencyOnly);
const outputJson = args.includes('--json');
const WARMUP_RUNS = parseInt(getArgValue('--warmup')) || 5;
const TIMED_RUNS = parseInt(getArgValue('--runs')) || 100;
const fixtureFilter = getArgValue('--filter');
const pluginFilter = getArgValue('--plugin')?.toUpperCase();
const timeoutSec = parseInt(getArgValue('--timeout')) || 30;
const maxSizeKb = parseInt(getArgValue('--max-size')) || 100;

// Recursively collect all .blade.php files from a directory
function collectFixtures(dir, baseDir) {
  const entries = readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (SKIP_DIRS.has(entry.name)) continue;
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectFixtures(fullPath, baseDir));
    } else if (entry.name.endsWith('.blade.php')) {
      const relPath = relative(baseDir, fullPath);
      files.push({
        name: relPath.replace(/\.blade\.php$/, '').replace(/\//g, '/'),
        content: readFileSync(fullPath, 'utf-8'),
        path: fullPath,
      });
    }
  }
  return files;
}

// Load fixtures from benchmark/fixtures/
const fixturesDir = join(__dirname, 'fixtures');

let fixtures = [];
if (existsSync(fixturesDir)) {
  fixtures = collectFixtures(fixturesDir, fixturesDir);
} else {
  console.error(chalk.red('No fixtures found. Run: just bench-sync'));
  process.exit(1);
}
fixtures.sort((a, b) => a.name.localeCompare(b.name));

// Apply fixture filters
const maxSizeBytes = maxSizeKb * 1024;
const skippedLarge = fixtures.filter(f => f.content.length > maxSizeBytes);
fixtures = fixtures.filter(f => f.content.length <= maxSizeBytes);

if (fixtureFilter) {
  const pattern = fixtureFilter.toLowerCase();
  fixtures = fixtures.filter(f => f.name.toLowerCase().includes(pattern));
}

// Apply plugin filter
const activePlugins = pluginFilter
  ? plugins.filter(p => p.short === pluginFilter)
  : plugins;

if (pluginFilter && activePlugins.length === 0) {
  console.error(chalk.red(`Unknown plugin "${pluginFilter}". Use A, B, or C.`));
  process.exit(1);
}
if (fixtureFilter && fixtures.length === 0) {
  console.error(chalk.red(`No fixtures match "${fixtureFilter}".`));
  process.exit(1);
}

const FORMAT_TIMEOUT_MS = timeoutSec * 1000;
const workerPath = join(__dirname, 'worker.mjs');

// Spawn an isolated child process for a plugin, returning a helper to send/receive messages.
function spawnWorker(plugin) {
  return new Promise((resolve, reject) => {
    const child = fork(workerPath, [
      JSON.stringify(plugin),
      JSON.stringify({ warmup: WARMUP_RUNS, runs: TIMED_RUNS }),
    ], { stdio: ['pipe', 'pipe', 'pipe', 'ipc'] });

    child.stderr.on('data', () => {}); // suppress stderr noise
    child.stdout.on('data', () => {});

    child.once('message', (msg) => {
      if (msg.type === 'loaded' && msg.ok) {
        resolve(child);
      } else {
        child.kill();
        resolve(null);
      }
    });

    child.once('error', () => resolve(null));
    child.once('exit', (code) => {
      if (code !== 0 && code !== null) resolve(null);
    });

    setTimeout(() => { child.kill(); resolve(null); }, 15_000);
  });
}

// Send a task to the worker and wait for the result, with a timeout.
// Returns { error: ... } if the worker crashes or times out.
function workerRequest(child, msg) {
  if (!child || child.killed || !child.connected) {
    return Promise.resolve({ error: 'worker dead' });
  }
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      cleanup();
      resolve({ error: 'timeout' });
    }, FORMAT_TIMEOUT_MS);

    const onMessage = (reply) => {
      cleanup();
      resolve(reply);
    };

    const onExit = () => {
      cleanup();
      resolve({ error: 'worker crashed' });
    };

    function cleanup() {
      clearTimeout(timer);
      child.removeListener('message', onMessage);
      child.removeListener('exit', onExit);
    }

    child.on('message', onMessage);
    child.on('exit', onExit);

    try {
      child.send(msg);
    } catch {
      cleanup();
      resolve({ error: 'worker dead' });
    }
  });
}

// ── Header ──
function printHeader() {
  console.log();
  console.log(bold('Blade Prettier Plugin Benchmark'));
  console.log(dim(`   ${fixtures.length} fixtures x ${activePlugins.length} plugins`));
  console.log(dim(`   ${WARMUP_RUNS} warmup + ${TIMED_RUNS} timed runs`));
  if (fixtureFilter) console.log(dim(`   filter: "${fixtureFilter}"`));
  if (skippedLarge.length > 0) {
    console.log(dim(`   skipped ${skippedLarge.length} fixture(s) > ${maxSizeKb}KB: ${skippedLarge.map(f => f.name).join(', ')}`));
  }
  console.log();
  console.log(bold('  Legend:'));
  for (const p of activePlugins) {
    const c = colors[p.short];
    console.log(`   ${c(p.short)}  ${c(p.name)}`);
  }
  console.log();
}

// ── Spawn workers for all plugins ──
async function spawnAllWorkers() {
  const workers = new Map();
  for (const plugin of activePlugins) {
    process.stdout.write(dim(`  Loading ${plugin.name}... `));
    const child = await spawnWorker(plugin);
    workers.set(plugin.short, child);
    console.log(child ? chalk.green('ok') : chalk.red('failed'));
  }
  console.log();
  return workers;
}

function killWorker(workers, key) {
  const child = workers.get(key);
  if (child && !child.killed) {
    try { child.send({ type: 'exit' }); } catch {}
    setTimeout(() => { try { child.kill(); } catch {} }, 500);
  }
}

// ── Performance benchmark (streaming) ──
async function benchPerformance(workers) {
  console.log(bold('PERFORMANCE') + dim(` (avg ms over ${TIMED_RUNS} runs, ${WARMUP_RUNS} warmup)`));
  console.log();

  const table = new Table({
    head: ['', ...activePlugins.map(p => colors[p.short](p.short))],
    style: { head: [], border: ['dim'], compact: true },
    chars: {
      'top': dim('─'), 'top-mid': dim('┬'), 'top-left': dim('┌'), 'top-right': dim('┐'),
      'bottom': dim('─'), 'bottom-mid': dim('┴'), 'bottom-left': dim('└'), 'bottom-right': dim('┘'),
      'left': dim('│'), 'left-mid': dim('├'), 'mid': dim('─'), 'mid-mid': dim('┼'),
      'right': dim('│'), 'right-mid': dim('┤'), 'middle': dim('│'),
    },
    colAligns: ['left', ...activePlugins.map(() => 'right')],
  });

  const results = {};
  for (const p of activePlugins) results[p.short] = {};
  const totals = {};
  for (const p of activePlugins) totals[p.short] = { sum: 0, count: 0, errors: 0 };

  let done = 0;

  for (const fixture of fixtures) {
    done++;
    const progress = dim(`[${String(done).padStart(3)}/${fixtures.length}]`);
    process.stdout.write(`\r${progress} ${dim(fixture.name.slice(0, 60).padEnd(60))} `);

    const row = [fixture.name];
    const avgs = {};

    for (const plugin of activePlugins) {
      const child = workers.get(plugin.short);
      if (!child || child.killed || !child.connected) {
        avgs[plugin.short] = null;
        continue;
      }

      const reply = await workerRequest(child, {
        type: 'perf',
        fixture: { name: fixture.name, content: fixture.content },
      });

      if (reply.error || !reply.result || reply.result.error) {
        avgs[plugin.short] = null;
        totals[plugin.short].errors++;
        results[plugin.short][fixture.name] = { avg: null, error: true };
      } else {
        const r = reply.result;
        avgs[plugin.short] = r.avg;
        totals[plugin.short].sum += r.avg;
        totals[plugin.short].count++;
        results[plugin.short][fixture.name] = r;
      }
    }

    // Find best (lowest) avg for this fixture
    let bestAvg = Infinity;
    for (const p of activePlugins) {
      if (avgs[p.short] != null && avgs[p.short] < bestAvg) bestAvg = avgs[p.short];
    }

    // Build colored cells
    for (const plugin of activePlugins) {
      const avg = avgs[plugin.short];
      const c = colors[plugin.short];
      if (avg == null) {
        row.push(dim('--'));
      } else {
        const label = avg.toFixed(2) + ' ms';
        row.push(avg === bestAvg ? c.bold(label) : dim(label));
      }
    }

    table.push(row);
  }

  // Clear progress line
  process.stdout.write('\r' + ' '.repeat(80) + '\r');

  // Average row
  const avgRow = [bold('Average')];
  for (const plugin of activePlugins) {
    const t = totals[plugin.short];
    const c = colors[plugin.short];
    if (t.count > 0) {
      const avg = (t.sum / t.count).toFixed(2) + ' ms';
      avgRow.push(c.bold(avg));
    } else {
      avgRow.push(dim('N/A'));
    }
  }
  table.push(avgRow);

  console.log(table.toString());
  console.log();

  // Summary
  const oursAvg = totals.A?.count > 0 ? totals.A.sum / totals.A.count : null;
  for (const plugin of activePlugins.filter(p => p.short !== 'A')) {
    const t = totals[plugin.short];
    if (t.count > 0 && oursAvg != null) {
      const theirAvg = t.sum / t.count;
      const ratio = (theirAvg / oursAvg).toFixed(0);
      const c = colors[plugin.short];
      console.log(`  ${colors.A('ours')} vs ${c(plugin.name)}: ${bold(ratio + 'x')} faster`);
    }
  }
  console.log();

  return results;
}

// ── Idempotency check (streaming) ──
async function benchIdempotency(workers) {
  console.log(bold('IDEMPOTENCY CHECK'));
  console.log();

  const table = new Table({
    head: ['', ...activePlugins.map(p => colors[p.short](p.short))],
    style: { head: [], border: ['dim'], compact: true },
    chars: {
      'top': dim('─'), 'top-mid': dim('┬'), 'top-left': dim('┌'), 'top-right': dim('┐'),
      'bottom': dim('─'), 'bottom-mid': dim('┴'), 'bottom-left': dim('└'), 'bottom-right': dim('┘'),
      'left': dim('│'), 'left-mid': dim('├'), 'mid': dim('─'), 'mid-mid': dim('┼'),
      'right': dim('│'), 'right-mid': dim('┤'), 'middle': dim('│'),
    },
  });

  const results = {};
  for (const p of activePlugins) results[p.short] = {};
  const summary = {};
  for (const p of activePlugins) summary[p.short] = { pass: 0, fail: 0, error: 0 };
  const failures = [];

  let done = 0;

  for (const fixture of fixtures) {
    done++;
    process.stdout.write(`\r${dim(`[${String(done).padStart(3)}/${fixtures.length}]`)} ${dim(fixture.name.slice(0, 60).padEnd(60))} `);

    const row = [fixture.name];

    for (const plugin of activePlugins) {
      const child = workers.get(plugin.short);
      if (!child || child.killed || !child.connected) {
        row.push(dim('--'));
        continue;
      }

      const reply = await workerRequest(child, {
        type: 'idempotency',
        fixture: { name: fixture.name, content: fixture.content },
      });

      const r = reply.result || reply;
      if (r.error) {
        row.push(chalk.red('ERR'));
        summary[plugin.short].error++;
        results[plugin.short][fixture.name] = { error: r.error };
      } else if (r.idempotent) {
        row.push(chalk.green('[v] Pass'));
        summary[plugin.short].pass++;
        results[plugin.short][fixture.name] = r;
      } else {
        row.push(chalk.red('[x] FAIL'));
        summary[plugin.short].fail++;
        results[plugin.short][fixture.name] = r;
        failures.push({
          plugin: plugin.name,
          fixture: fixture.name,
          diffAt: r.diffAt,
          pass1Snippet: r.pass1Snippet,
          pass2Snippet: r.pass2Snippet,
        });
      }
    }

    table.push(row);
  }

  // Clear progress line
  process.stdout.write('\r' + ' '.repeat(80) + '\r');

  console.log(table.toString());
  console.log();

  // Summary per plugin
  for (const plugin of activePlugins) {
    const s = summary[plugin.short];
    const c = colors[plugin.short];
    const parts = [c.bold(plugin.name) + ':'];
    parts.push(chalk.green(`${s.pass} pass`));
    if (s.fail > 0) parts.push(chalk.red(`${s.fail} fail`));
    if (s.error > 0) parts.push(chalk.red(`${s.error} errors`));
    console.log('  ' + parts.join('  '));
  }
  console.log();

  // Failure details
  if (failures.length > 0) {
    console.log(bold('  Failure Details:'));
    for (const f of failures) {
      console.log(chalk.red(`  [!] ${f.plugin} x ${f.fixture}: differs at char ${f.diffAt}`));
      console.log(dim(`      Pass 1: ...${JSON.stringify(f.pass1Snippet)}...`));
      console.log(dim(`      Pass 2: ...${JSON.stringify(f.pass2Snippet)}...`));
    }
    console.log();
  }

  return results;
}

// ── Formatted output comparison ──
async function benchOutput(workers) {
  console.log(bold('FORMATTED OUTPUT COMPARISON'));
  console.log();

  const outputDir = join(__dirname, 'results');
  if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

  for (const fixture of fixtures) {
    console.log(dim(`--- ${fixture.name} ---`));

    for (const plugin of activePlugins) {
      const child = workers.get(plugin.short);
      const c = colors[plugin.short];
      if (!child || child.killed || !child.connected) {
        console.log(`  ${c(plugin.short)} ${dim('SKIPPED')}`);
        continue;
      }

      const reply = await workerRequest(child, {
        type: 'output',
        fixture: { name: fixture.name, content: fixture.content },
      });

      const r = reply.result || reply;
      if (r.error) {
        console.log(`  ${c(plugin.short)} ${chalk.red('ERROR')} ${dim(r.error)}`);
      } else {
        const safeName = fixture.name.replace(/\//g, '__');
        const outFile = join(outputDir, `${safeName}.${plugin.short}.txt`);
        writeFileSync(outFile, r.formatted);
        const lines = r.formatted.split('\n').length;
        console.log(`  ${c(plugin.short)} ${dim(`${lines} lines`)} ${dim('->')} ${dim(outFile)}`);
      }
    }
  }
  console.log();
}

// ── Main ──
async function main() {
  printHeader();
  let workers = await spawnAllWorkers();

  const allResults = {};

  if (full || perfOnly) {
    allResults.performance = await benchPerformance(workers);
  }

  if (full || idempotencyOnly) {
    // Respawn workers — perf runs may have exhausted them
    for (const [key] of workers) killWorker(workers, key);
    console.log(dim('  Respawning workers for idempotency check...'));
    workers = await spawnAllWorkers();
    allResults.idempotency = await benchIdempotency(workers);
  }

  if (full) {
    for (const [key] of workers) killWorker(workers, key);
    console.log(dim('  Respawning workers for output comparison...'));
    workers = await spawnAllWorkers();
    await benchOutput(workers);
  }

  // Clean up workers
  for (const [key] of workers) {
    killWorker(workers, key);
  }

  if (outputJson) {
    allResults.generatedAt = new Date().toISOString();
    const jsonFile = join(__dirname, 'results', 'benchmark.json');
    if (!existsSync(join(__dirname, 'results'))) mkdirSync(join(__dirname, 'results'), { recursive: true });
    writeFileSync(jsonFile, JSON.stringify(allResults, null, 2));
    console.log(dim(`JSON results written to ${jsonFile}`));
  }

  console.log(dim('Done.'));
  console.log();
}

main().catch(e => {
  console.error(chalk.red('Benchmark failed:'), e);
  process.exit(1);
});
