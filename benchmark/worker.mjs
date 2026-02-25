// Worker process — runs benchmarks for a single plugin in isolation.
// Communicates with parent via IPC messages.

import * as prettier from 'prettier';

const plugin = JSON.parse(process.argv[2]);
const config = JSON.parse(process.argv[3]);

let pluginModule = null;

async function loadPlugin() {
  try {
    const mod = plugin.loadPath.startsWith('/') || plugin.loadPath.startsWith('.')
      ? await import(plugin.loadPath)
      : await import(plugin.loadPath);
    if (mod.parsers) return mod;
    if (mod.default?.parsers) return mod.default;
    return null;
  } catch {
    return null;
  }
}

async function formatOnce(code) {
  return prettier.format(code, {
    parser: plugin.parser,
    plugins: [pluginModule],
    tabWidth: 4,
    printWidth: 120,
  });
}

async function benchPerf(fixture) {
  for (let i = 0; i < config.warmup; i++) {
    try { await formatOnce(fixture.content); } catch {}
  }

  // Snapshot memory and CPU before timed runs
  if (global.gc) global.gc();
  const memBefore = process.memoryUsage();
  const cpuBefore = process.cpuUsage();

  const times = [];
  for (let i = 0; i < config.runs; i++) {
    const start = performance.now();
    try {
      await formatOnce(fixture.content);
      times.push(performance.now() - start);
    } catch {}
  }

  // Snapshot after
  const cpuAfter = process.cpuUsage(cpuBefore);
  const memAfter = process.memoryUsage();

  if (times.length > 0) {
    const avg = times.reduce((a, b) => a + b, 0) / times.length;
    return {
      avg: parseFloat(avg.toFixed(2)),
      min: parseFloat(Math.min(...times).toFixed(2)),
      max: parseFloat(Math.max(...times).toFixed(2)),
      runs: times.length,
      // CPU time in ms (user + system) across all runs
      cpuUser: parseFloat((cpuAfter.user / 1000).toFixed(2)),
      cpuSystem: parseFloat((cpuAfter.system / 1000).toFixed(2)),
      // Memory: peak heap used during runs (bytes)
      heapUsed: memAfter.heapUsed,
      heapTotal: memAfter.heapTotal,
      rss: memAfter.rss,
      // Memory delta (bytes allocated during runs)
      heapDelta: memAfter.heapUsed - memBefore.heapUsed,
    };
  }
  return { avg: null, error: true };
}

async function benchIdempotency(fixture) {
  try {
    const pass1 = await formatOnce(fixture.content);
    const pass2 = await formatOnce(pass1);
    const idempotent = pass1 === pass2;
    const result = { idempotent, pass1Length: pass1.length, pass2Length: pass2.length };

    if (!idempotent) {
      let diffPos = -1;
      for (let i = 0; i < Math.max(pass1.length, pass2.length); i++) {
        if (pass1[i] !== pass2[i]) { diffPos = i; break; }
      }
      result.diffAt = diffPos;
      result.pass1Snippet = pass1.substring(Math.max(0, diffPos - 20), diffPos + 20);
      result.pass2Snippet = pass2.substring(Math.max(0, diffPos - 20), diffPos + 20);
    }
    return result;
  } catch (e) {
    return { error: e.message };
  }
}

async function benchOutput(fixture) {
  try {
    const formatted = await formatOnce(fixture.content);
    return { formatted };
  } catch (e) {
    return { error: e.message };
  }
}

async function main() {
  pluginModule = await loadPlugin();
  if (!pluginModule) {
    process.send({ type: 'loaded', ok: false });
    process.exit(1);
  }
  process.send({ type: 'loaded', ok: true });

  process.on('message', async (msg) => {
    if (msg.type === 'perf') {
      const result = await benchPerf(msg.fixture);
      process.send({ type: 'perf-result', name: msg.fixture.name, result });
    } else if (msg.type === 'idempotency') {
      const result = await benchIdempotency(msg.fixture);
      process.send({ type: 'idempotency-result', name: msg.fixture.name, result });
    } else if (msg.type === 'output') {
      const result = await benchOutput(msg.fixture);
      process.send({ type: 'output-result', name: msg.fixture.name, result });
    } else if (msg.type === 'exit') {
      process.exit(0);
    }
  });
}

main();
