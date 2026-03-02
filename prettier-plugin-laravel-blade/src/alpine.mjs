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
