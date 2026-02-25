import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { createServer } from 'node:http';
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load benchmark data for validation
const benchmarkData = JSON.parse(
  readFileSync(resolve(__dirname, 'data', 'benchmark.json'), 'utf8')
);
const hasIdempotency = benchmarkData.idempotency && Object.keys(benchmarkData.idempotency.A || {}).length > 0;
const hasPerformance = benchmarkData.performance && Object.keys(benchmarkData.performance.A || {}).length > 0;
const hasResources = hasPerformance && Object.values(benchmarkData.performance.A).some(e => e.cpuUser != null);

// Simple static file server for the site directory
function startServer(dir, port) {
  return new Promise((resolve, reject) => {
    const mimeTypes = {
      '.html': 'text/html', '.js': 'application/javascript',
      '.css': 'text/css', '.json': 'application/json',
      '.png': 'image/png', '.svg': 'image/svg+xml',
    };
    const server = createServer((req, res) => {
      const url = req.url === '/' ? '/index.html' : req.url;
      const filePath = `${dir}${url}`;
      try {
        const data = readFileSync(filePath);
        const ext = filePath.match(/\.[^.]+$/)?.[0] || '.html';
        res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'text/plain' });
        res.end(data);
      } catch {
        res.writeHead(404);
        res.end('Not found');
      }
    });
    server.listen(port, () => resolve(server));
    server.on('error', reject);
  });
}

describe('benchmarks.html e2e', () => {
  let browser, page, server;
  const PORT = 9876;
  const errors = [];

  before(async () => {
    server = await startServer(__dirname, PORT);
    browser = await chromium.launch();
    page = await browser.newPage();
    page.on('pageerror', (e) => errors.push(e.message));
    await page.goto(`http://localhost:${PORT}/benchmarks.html`, {
      waitUntil: 'networkidle',
    });
    // Wait for data to render
    await page.waitForTimeout(1000);
  });

  after(async () => {
    await browser?.close();
    server?.close();
  });

  it('loads without JavaScript errors', () => {
    assert.deepEqual(errors, [], `Page had JS errors: ${errors.join('; ')}`);
  });

  // ── Metrics bar (requires performance data) ──
  it('renders average format time metric', { skip: !hasPerformance }, async () => {
    const text = await page.locator('#m-avg').textContent();
    assert.match(text, /\d+\.\d+ms/, `Expected avg time like "0.45ms", got "${text}"`);
  });

  it('renders faster-vs-stillat ratio', { skip: !hasPerformance }, async () => {
    const text = await page.locator('#m-ratio-b').textContent();
    assert.match(text, /\d+x/, `Expected ratio like "22x", got "${text}"`);
  });

  it('renders faster-vs-shufo ratio', { skip: !hasPerformance }, async () => {
    const text = await page.locator('#m-ratio-c').textContent();
    assert.match(text, /\d+x/, `Expected ratio like "30x", got "${text}"`);
  });

  it('renders fixture count', { skip: !hasPerformance }, async () => {
    const text = await page.locator('#m-fixtures').textContent();
    const count = parseInt(text);
    const expected = Object.keys(benchmarkData.performance.A).length;
    assert.ok(count > 0, 'Fixture count should be > 0');
    assert.equal(count, expected, `Fixture count ${count} != benchmark data ${expected}`);
  });

  it('renders idempotency score', { skip: !hasIdempotency }, async () => {
    const text = await page.locator('#m-idem').textContent();
    assert.match(text, /\d+\/\d+/, `Expected like "105/108", got "${text}"`);
  });

  // ── Performance section ──
  it('renders performance rows for all fixtures', { skip: !hasPerformance }, async () => {
    const rows = await page.locator('.bench-row').count();
    const expected = Object.keys(benchmarkData.performance.A).length;
    assert.equal(rows, expected, `Expected ${expected} perf rows, got ${rows}`);
  });

  it('renders performance bars', { skip: !hasPerformance }, async () => {
    const bars = await page.locator('.bench-bar').count();
    assert.ok(bars > 0, 'Should have performance bars');
  });

  it('renders overall average summary', { skip: !hasPerformance }, async () => {
    const summary = await page.locator('.bench-summary').count();
    assert.ok(summary > 0, 'Should have overall average summary row');
  });

  // ── Resource Usage section ──
  it('renders resource usage section', async () => {
    const heading = await page.locator('#resources .sh').textContent();
    assert.equal(heading, 'Memory and CPU footprint');
  });

  it('renders resource metric cards', { skip: !hasResources }, async () => {
    const cards = await page.locator('#resourceMetrics > div').count();
    assert.equal(cards, 3, `Expected 3 resource cards (A, B, C), got ${cards}`);
  });

  it('resource cards contain heap and CPU values', { skip: !hasResources }, async () => {
    const cardTexts = await page.locator('#resourceMetrics > div').allTextContents();
    for (const text of cardTexts) {
      assert.match(text, /Peak Heap/, `Card missing "Peak Heap": ${text}`);
      assert.match(text, /Total CPU/, `Card missing "Total CPU": ${text}`);
      assert.match(text, /\d+(\.\d+)?\s*(MB|KB)/, `Card missing heap value: ${text}`);
      assert.match(text, /\d+\s*ms/, `Card missing CPU value: ${text}`);
    }
  });

  it('renders resource table with per-fixture rows', { skip: !hasResources }, async () => {
    const rows = await page.locator('#resourceBody tr').count();
    const fixturesWithResources = Object.values(benchmarkData.performance.A)
      .filter(e => e.cpuUser != null).length;
    assert.equal(rows, fixturesWithResources,
      `Expected ${fixturesWithResources} resource rows, got ${rows}`);
  });

  // ── Idempotency section ──
  it('renders idempotency summary', { skip: !hasIdempotency }, async () => {
    const text = await page.locator('#idemSummary').textContent();
    assert.match(text, /pass/, 'Idempotency summary should mention "pass"');
  });

  it('renders idempotency table rows', { skip: !hasIdempotency }, async () => {
    const rows = await page.locator('#idemBody tr').count();
    assert.ok(rows > 0, 'Should have idempotency table rows');
  });

  // ── Error catalog section ──
  it('renders error catalog section', { skip: !hasIdempotency }, async () => {
    const plugins = await page.locator('.error-plugin').count();
    assert.equal(plugins, 3, `Expected 3 error catalog plugin sections, got ${plugins}`);
  });

  // ── Generated at ──
  it('shows generated-at timestamp', async () => {
    const text = await page.locator('#benchGeneratedAt').textContent();
    assert.match(text, /Generated/, `Expected "Generated ..." timestamp, got "${text}"`);
  });

  // ── No missing data (only when full data available) ──
  it('no "--" placeholder in metrics bar', { skip: !hasPerformance || !hasIdempotency }, async () => {
    for (const id of ['m-avg', 'm-ratio-b', 'm-ratio-c', 'm-fixtures', 'm-idem']) {
      const text = await page.locator(`#${id}`).textContent();
      assert.notEqual(text, '--', `Metric ${id} still shows placeholder "--"`);
    }
  });
});
