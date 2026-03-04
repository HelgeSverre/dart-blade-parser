# Alpine.js x-data Attribute Formatting — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Format JavaScript expressions inside Alpine.js attribute values (`x-data`, `@click`, `:class`, etc.) using Prettier's TypeScript parser as a post-processing step in the Prettier plugin.

**Architecture:** After the Dart formatter produces formatted Blade output, a new `formatAlpineAttributes()` function in `index.mjs` scans for Alpine attribute values and re-formats their JS content using `prettier.format()` with `parser: "typescript"`. Expression attributes are wrapped as arrow functions before formatting, then unwrapped. Graceful fallback on parse errors.

**Tech Stack:** JavaScript (ESM), Prettier API, Node.js test runner

---

### Task 1: Add Alpine attribute formatting module

**Files:**
- Create: `prettier-plugin-laravel-blade/src/alpine.mjs`

**Step 1: Create the Alpine formatting module**

Create `prettier-plugin-laravel-blade/src/alpine.mjs` with:

```javascript
import prettier from "prettier";

// Expression attributes: value is a JS expression (object, boolean, etc.)
// These need the arrow-function wrapping trick to become valid JS programs.
const EXPRESSION_ATTR =
  /^(?:x-(?:data|show|bind|text|html|model|modelable|if|id)|:[\w][\w.-]*)$/;

// Statement attributes: value is JS code (function calls, assignments)
// These can be formatted directly as JS statements.
const STATEMENT_ATTR =
  /^(?:x-(?:init|on|effect)|@(?!if\b|else\b|elseif\b|unless\b|isset\b|empty\b|auth\b|guest\b|can\b|cannot\b|canany\b|env\b|production\b|hasSection\b|sectionMissing\b|switch\b|case\b|break\b|default\b|for\b|foreach\b|forelse\b|while\b|continue\b|php\b|include\b|includeIf\b|includeWhen\b|includeUnless\b|includeFirst\b|each\b|once\b|push\b|pushOnce\b|pushIf\b|prepend\b|prependOnce\b|stack\b|props\b|aware\b|inject\b|fragment\b|endfragment\b|verbatim\b|endverbatim\b|section\b|yield\b|extends\b|parent\b|component\b|endcomponent\b|slot\b|endslot\b|class\b|style\b|checked\b|selected\b|disabled\b|readonly\b|required\b|error\b|csrf\b|method\b|dd\b|dump\b|vite\b|livewire\b|livewireStyles\b|livewireScripts\b|persist\b|teleport\b|endteleport\b|session\b|use\b|end)[\w][\w.-]*)$/;

/**
 * Check if an attribute name is an Alpine.js directive.
 */
export function isAlpineExpression(name) {
  return EXPRESSION_ATTR.test(name);
}

export function isAlpineStatement(name) {
  return STATEMENT_ATTR.test(name);
}

export function isAlpineAttribute(name) {
  return isAlpineExpression(name) || isAlpineStatement(name);
}

/**
 * Format an Alpine attribute value using Prettier's TypeScript parser.
 *
 * @param {string} attrName - The attribute name (e.g., "x-data", "@click")
 * @param {string} attrValue - The raw attribute value
 * @param {object} options - Prettier options
 * @param {number} indentLevel - Current indentation depth (number of indent units)
 * @returns {Promise<string>} Formatted attribute value
 */
export async function formatAlpineValue(attrName, attrValue, options, indentLevel) {
  if (!attrValue || attrValue.trim() === "") return attrValue;

  // Skip values containing Blade interpolation — not valid JS
  if (attrValue.includes("{{") || attrValue.includes("{!!")) return attrValue;

  const isExpression = isAlpineExpression(attrName);
  if (!isExpression && !isAlpineStatement(attrName)) return attrValue;

  try {
    // For expressions, wrap as arrow function so it's a valid JS program
    const toFormat = isExpression ? `() => (${attrValue})` : attrValue;

    let formatted = await prettier.format(toFormat, {
      ...options,
      parser: "typescript",
      singleQuote: true,
      plugins: [], // Don't load blade plugin recursively
    });

    formatted = formatted.trim();

    if (isExpression) {
      // Strip the () => wrapper
      formatted = formatted.replace(/^\s*\(\s*\)\s*=>\s*/, "");
      formatted = formatted.trim();
      // Remove outer parens if present
      if (formatted.startsWith("(") && formatted.endsWith(")")) {
        formatted = formatted.slice(1, -1);
      } else if (formatted.startsWith("(") && formatted.endsWith(");")) {
        formatted = formatted.slice(1, -2);
      }
    }

    // Remove trailing semicolons
    if (formatted.endsWith(";")) {
      formatted = formatted.slice(0, -1);
    }

    formatted = formatted.trim();

    // Short values: collapse to single line if under printWidth
    if (formatted.includes("\n") && !/`[^`]*\n[^`]*`/.test(formatted)) {
      const oneLine = formatted.replace(/\n\s*/g, " ");
      if (oneLine.length < 60) {
        formatted = oneLine;
      }
    }

    // Multi-line: indent to match attribute position
    if (formatted.includes("\n")) {
      const indent = options.useTabs
        ? "\t".repeat(indentLevel)
        : " ".repeat(indentLevel * options.tabWidth);
      formatted = formatted.replace(/\n/g, `\n${indent}`);
    }

    return formatted;
  } catch {
    // Graceful fallback: return original value if Prettier can't parse it
    return attrValue;
  }
}
```

**Step 2: Verify the module is syntactically valid**

Run: `cd prettier-plugin-laravel-blade && node -e "import('./src/alpine.mjs').then(() => console.log('OK'))"`
Expected: `OK`

**Step 3: Commit**

```bash
git add prettier-plugin-laravel-blade/src/alpine.mjs
git commit -m "feat(plugin): add Alpine.js attribute value formatting module"
```

---

### Task 2: Write failing tests for Alpine formatting

**Files:**
- Create: `prettier-plugin-laravel-blade/test/alpine.test.mjs`

**Step 1: Write the test file**

```javascript
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
    const input = `<a href="#" :class="{'active':isActive,'disabled':!enabled}"></a>`;
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
```

**Step 2: Run tests to verify they fail**

Run: `cd prettier-plugin-laravel-blade && node --test test/alpine.test.mjs`
Expected: Most tests FAIL (the formatting module exists but isn't wired into the plugin yet)

**Step 3: Commit**

```bash
git add prettier-plugin-laravel-blade/test/alpine.test.mjs
git commit -m "test(plugin): add failing tests for Alpine.js attribute formatting"
```

---

### Task 3: Wire Alpine formatting into the Prettier plugin

**Files:**
- Modify: `prettier-plugin-laravel-blade/src/index.mjs`

**Step 1: Add the post-processing step to preprocess**

In `index.mjs`, modify the `preprocess` function to:
1. Import `formatAlpineValue`, `isAlpineAttribute` from `./alpine.mjs`
2. After getting `result.formatted` from the Dart formatter, scan for Alpine attributes
3. For each match, call `formatAlpineValue()` and replace the value
4. Make `preprocess` async (Prettier supports this)

The key regex to find attribute values in the formatted output:

```javascript
// Match Alpine attribute name=value pairs in formatted output.
// Handles both double and single quoted values, including multi-line values
// from attribute wrapping.
const ALPINE_ATTR_RE =
  /((?:x-(?:data|show|bind|text|html|model|modelable|if|id|init|on|effect)|:[\w][\w.-]*|@(?!if\b|else\b|elseif\b|unless\b|isset\b|empty\b|auth\b|guest\b|can\b|cannot\b|canany\b|env\b|production\b|for\b|foreach\b|forelse\b|while\b|continue\b|php\b|include\b|each\b|once\b|push\b|prepend\b|stack\b|props\b|inject\b|section\b|yield\b|extends\b|component\b|slot\b|class\b|style\b|checked\b|selected\b|disabled\b|readonly\b|required\b|error\b|csrf\b|method\b|dd\b|dump\b|vite\b|livewire\b|persist\b|teleport\b|session\b|use\b|end)[\w][\w.-]*))=(["'])([\s\S]*?)\3/g;
```

Update the `preprocess` function:

```javascript
import { formatAlpineValue, isAlpineAttribute } from "./alpine.mjs";

// In the parsers.blade object:
async preprocess(text, options) {
  // ... existing Dart formatting code ...
  let formatted = result.formatted;

  // Post-process: format Alpine.js attribute values
  if (options.bladeFormatAlpine !== false) {
    formatted = await formatAlpineAttributes(formatted, options);
  }

  return formatted;
},
```

Add the `formatAlpineAttributes` function:

```javascript
const ALPINE_ATTR_RE =
  /((?:x-(?:data|show|bind|text|html|model|modelable|if|id|init|on|effect)|:[\w][\w.-]*|@(?!if\b|else|foreach|forelse|for\b|while|switch|case|break|default|unless|isset|empty|auth|guest|can|cannot|canany|env|production|php|include|each|once|push|prepend|stack|props|inject|section|yield|extends|component|slot|class|style|checked|selected|disabled|readonly|required|error|csrf|method|dd|dump|vite|livewire|persist|teleport|session|use|end)[\w][\w.-]*))=(["'])([\s\S]*?)\3/g;

async function formatAlpineAttributes(text, options) {
  const matches = [...text.matchAll(ALPINE_ATTR_RE)];
  if (matches.length === 0) return text;

  // Process replacements from end to start to preserve positions
  let result = text;
  for (const match of matches.reverse()) {
    const [fullMatch, attrName, quote, value] = match;
    const offset = match.index;

    if (!isAlpineAttribute(attrName)) continue;

    // Calculate indent level from the line this attribute is on
    const lineStart = result.lastIndexOf("\n", offset) + 1;
    const lineText = result.slice(lineStart, offset);
    const leadingSpaces = lineText.match(/^(\s*)/)?.[1] ?? "";
    const indentLevel = options.useTabs
      ? leadingSpaces.split("\t").length - 1
      : Math.floor(leadingSpaces.length / options.tabWidth);

    const formatted = await formatAlpineValue(
      attrName, value, options, indentLevel + 1
    );

    if (formatted !== value) {
      const replacement = `${attrName}=${quote}${formatted}${quote}`;
      result =
        result.slice(0, offset) +
        replacement +
        result.slice(offset + fullMatch.length);
    }
  }

  return result;
}
```

Add the new option to the `options` export:

```javascript
bladeFormatAlpine: {
  type: "boolean",
  category: "Blade",
  default: true,
  description: "Format JavaScript expressions inside Alpine.js attribute values.",
},
```

**Step 2: Run the Alpine tests**

Run: `cd prettier-plugin-laravel-blade && node --test test/alpine.test.mjs`
Expected: Tests should pass

**Step 3: Run all plugin tests to check for regressions**

Run: `cd prettier-plugin-laravel-blade && npm test`
Expected: All existing tests + new Alpine tests pass

**Step 4: Commit**

```bash
git add prettier-plugin-laravel-blade/src/index.mjs
git commit -m "feat(plugin): wire Alpine.js formatting into Prettier preprocess"
```

---

### Task 4: Test idempotency and edge cases, fix issues

**Files:**
- Modify: `prettier-plugin-laravel-blade/test/alpine.test.mjs` (add more tests if needed)
- Modify: `prettier-plugin-laravel-blade/src/alpine.mjs` (fix any issues)

**Step 1: Run the full test suite**

Run: `cd prettier-plugin-laravel-blade && npm test`
Expected: All tests pass

**Step 2: Manually test with a complex Alpine template**

Create a temporary test to verify real-world usage:

```javascript
it("handles Chris Mellor's example", async () => {
  const input = `<div
    @if($isCompleted)
    x-cloak
    x-show="! showFilters"
    @endif
></div>`;
  const result = await format(input);
  const second = await format(result);
  assert.equal(first, second);
});

it("formats x-data with multiline object", async () => {
  const input = `<div x-data="{ expanded: false, activeTrack: null, filters: [], currentPage: 1, searchQuery: '' }"></div>`;
  const result = await format(input, { printWidth: 80 });
  const second = await format(result, { printWidth: 80 });
  assert.equal(result, second);
});
```

**Step 3: Fix any idempotency issues found**

Common issues to watch for:
- Trailing semicolons being added/removed on each pass
- Whitespace differences between passes
- Quote style conflicts (Prettier uses single quotes for JS, but the attribute uses double quotes)

**Step 4: Run all tests one final time**

Run: `cd prettier-plugin-laravel-blade && npm test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A prettier-plugin-laravel-blade/
git commit -m "test(plugin): add edge case tests for Alpine.js formatting"
```

---

### Task 5: Update the plugin version and verify full pipeline

**Files:**
- Modify: `prettier-plugin-laravel-blade/package.json` (bump patch version)

**Step 1: Bump version**

Change version from `0.4.1` to `0.5.0` (minor bump since this is a new feature).

**Step 2: Run the full plugin test suite one final time**

Run: `cd prettier-plugin-laravel-blade && npm test`
Expected: All tests pass

**Step 3: Commit**

```bash
git add prettier-plugin-laravel-blade/package.json
git commit -m "chore(plugin): bump version to 0.5.0 for Alpine.js formatting"
```
