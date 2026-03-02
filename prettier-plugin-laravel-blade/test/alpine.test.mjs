import { describe, it } from "node:test";
import assert from "node:assert/strict";
import * as prettier from "prettier";

const pluginPath = new URL("../src/index.mjs", import.meta.url).pathname;

async function format(code, options = {}) {
  return prettier.format(code, {
    parser: "blade",
    plugins: [pluginPath],
    ...options,
  });
}

describe("Alpine.js attribute formatting", () => {
  // --- Expression attributes (x-data, x-show, :class, etc.) ---

  it("formats simple x-data object on one line", async () => {
    const input = '<div x-data="{open:false}"></div>';
    const result = await format(input);
    assert.ok(result.includes('x-data="{ open: false }"'));
  });

  it("formats multi-property x-data with proper spacing", async () => {
    const input =
      '<div x-data="{ expanded: false,activeTrack: null,count:0 }"></div>';
    const result = await format(input);
    // Should have spaces after colons and commas
    assert.ok(result.includes("expanded: false"));
    assert.ok(result.includes("activeTrack: null"));
    assert.ok(result.includes("count: 0"));
  });

  it("formats x-show boolean expression", async () => {
    const input = '<div x-show="open&&!loading"></div>';
    const result = await format(input);
    assert.ok(result.includes("open && !loading"));
  });

  it("formats :class binding expression", async () => {
    const input = '<a href="#" :class="{\'active\':isActive,\'disabled\':!enabled}"></a>';
    const result = await format(input);
    assert.ok(result.includes("active"));
    assert.ok(result.includes("isActive"));
  });

  // --- Statement attributes (@click, x-on, x-init, etc.) ---

  it("formats @click assignment", async () => {
    const input = '<button @click="open=!open">Toggle</button>';
    const result = await format(input);
    assert.ok(result.includes("open = !open"));
  });

  it("formats x-init statement", async () => {
    const input =
      '<div x-init="fetchItems()"></div>';
    const result = await format(input);
    assert.ok(result.includes("fetchItems()"));
  });

  // --- Skip conditions ---

  it("preserves values with Blade interpolation", async () => {
    const input =
      '<div x-data="{ count: {{ $initial }} }"></div>';
    const result = await format(input);
    assert.ok(result.includes("{{ $initial }}"));
  });

  it("preserves invalid JS gracefully", async () => {
    const input =
      '<div x-data="{ this is not valid js }"></div>';
    const result = await format(input);
    // Should not crash, should contain the attribute
    assert.ok(result.includes("x-data="));
  });

  // --- Idempotency ---

  it("is idempotent on Alpine attributes", async () => {
    const input = `<div x-data="{ open: false, count: 0 }">
<button @click="open = !open">Toggle</button>
<div x-show="open" x-transition>
<p>Content</p>
</div>
</div>`;
    const first = await format(input);
    const second = await format(first);
    assert.equal(first, second);
  });

  // --- Option: bladeFormatAlpine ---

  it("skips Alpine formatting when bladeFormatAlpine is false", async () => {
    const input = '<div x-data="{open:false}"></div>';
    const result = await format(input, { bladeFormatAlpine: false });
    // Should NOT format the JS inside — value stays as the Dart formatter left it
    assert.ok(result.includes("x-data="));
    // The Dart formatter preserves attribute values as-is, so {open:false} stays
    assert.ok(result.includes("{open:false}"));
  });
});
