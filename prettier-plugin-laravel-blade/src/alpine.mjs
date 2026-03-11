import prettier from "prettier";

// Blade directives that use @ prefix — must not be treated as Alpine event handlers.
// Shared between detection regex and the attribute-scanning regex in index.mjs.
export const BLADE_DIRECTIVES = [
  "if", "else", "elseif", "unless", "isset", "empty",
  "auth", "guest", "can", "cannot", "canany", "env", "production",
  "hasSection", "sectionMissing",
  "switch", "case", "break", "default",
  "for", "foreach", "forelse", "while", "continue",
  "php", "include", "includeIf", "includeWhen", "includeUnless", "includeFirst",
  "each", "once",
  "push", "pushOnce", "pushIf", "prepend", "prependOnce", "stack",
  "props", "aware", "inject",
  "fragment", "endfragment", "verbatim", "endverbatim",
  "section", "yield", "extends", "parent",
  "component", "endcomponent", "slot", "endslot",
  "class", "style", "checked", "selected", "disabled", "readonly", "required",
  "error", "csrf", "method", "dd", "dump", "vite",
  "livewire", "livewireStyles", "livewireScripts",
  "persist", "teleport", "endteleport", "session", "use",
  "end",
];

const bladeNeg = BLADE_DIRECTIVES.map((d) => `${d}\\b`).join("|");

// Expression attributes: value is a JS expression (object, boolean, etc.)
// These need the arrow-function wrapping trick to become valid JS programs.
const EXPRESSION_ATTR =
  /^(?:x-(?:data|show|bind|text|html|model|modelable|if|id)|:[\w][\w.-]*)$/;

// Statement attributes: value is JS code (function calls, assignments)
// These can be formatted directly as JS statements.
const STATEMENT_ATTR = new RegExp(
  `^(?:x-(?:init|on|effect)|@(?!${bladeNeg})[\\w][\\w.-]*)$`,
);

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
      trailingComma: "none", // Prevent trailing comma oscillation between multi-line and collapsed single-line
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
