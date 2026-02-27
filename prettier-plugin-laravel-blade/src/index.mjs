import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

// Load the compiled Dart formatter (sets globalThis.bladeFormatter)
require(join(__dirname, "..", "dist", "blade-formatter.js"));

/**
 * Format Blade template source using the compiled Dart formatter.
 * @param {string} text - Blade template source
 * @param {object} opts - Formatting options
 * @returns {{ formatted: string }}
 */
function formatBlade(text, opts = {}) {
  const result = JSON.parse(
    globalThis.__dartBladeFormatter(text, JSON.stringify(opts)),
  );
  if (result.error) {
    throw new Error(`blade-formatter: ${result.error}`);
  }
  return result;
}

/** @type {import("prettier").SupportLanguage[]} */
export const languages = [
  {
    name: "Blade",
    parsers: ["blade"],
    extensions: [".blade.php"],
    vscodeLanguageIds: ["blade"],
    since: "0.1.0",
  },
];

/** @type {Record<string, import("prettier").Parser>} */
export const parsers = {
  blade: {
    preprocess(text, options) {
      const formatOpts = {
        tabWidth: options.tabWidth,
        useTabs: options.useTabs,
        printWidth: options.printWidth,
        // Plugin-specific options
        quoteStyle: options.bladeQuoteStyle,
        directiveSpacing: options.bladeDirectiveSpacing,
        slotFormatting: options.bladeSlotFormatting,
        slotNameStyle: options.bladeSlotNameStyle,
        slotSpacing: options.bladeSlotSpacing,
        wrapAttributes: options.bladeWrapAttributes,
        attributeSort: options.bladeAttributeSort,
        closingBracketStyle: options.bladeClosingBracketStyle,
        selfClosingStyle: options.bladeSelfClosingStyle,
        htmlBlockSpacing: options.bladeHtmlBlockSpacing,
        echoSpacing: options.bladeEchoSpacing,
        trailingNewline: options.bladeTrailingNewline,
      };

      // Pass cursor offset if set
      if (options.cursorOffset >= 0) {
        formatOpts.cursorOffset = options.cursorOffset;
      }

      // Pass range if set
      if (options.rangeStart > 0 || options.rangeEnd < text.length) {
        if (options.rangeStart > 0) {
          formatOpts.rangeStart = options.rangeStart;
        }
        if (options.rangeEnd < text.length) {
          formatOpts.rangeEnd = options.rangeEnd;
        }
      }

      const result = formatBlade(text, formatOpts);

      // Store cursor offset for Prettier to pick up
      if (result.cursorOffset >= 0) {
        options.__bladeCursorOffset = result.cursorOffset;
      }

      return result.formatted;
    },

    parse(text) {
      return {
        type: "blade-formatter",
        body: text,
        start: 0,
        end: text.length,
      };
    },

    astFormat: "blade-ast",
    locStart: (node) => node.start,
    locEnd: (node) => node.end,
  },
};

/** @type {Record<string, import("prettier").Printer>} */
export const printers = {
  "blade-ast": {
    print(path) {
      const node = path.node ?? path.getValue();
      if (node.type === "blade-formatter") {
        return node.body;
      }
      return "";
    },
  },
};

/** @type {Record<string, import("prettier").SupportOption>} */
export const options = {
  bladeQuoteStyle: {
    type: "choice",
    category: "Blade",
    default: "preserve",
    description: "Quote style for HTML attributes in Blade templates.",
    choices: [
      { value: "single", description: "Use single quotes" },
      { value: "double", description: "Use double quotes" },
      { value: "preserve", description: "Preserve original quote style" },
    ],
  },
  bladeDirectiveSpacing: {
    type: "choice",
    category: "Blade",
    default: "between_blocks",
    description: "Spacing between Blade directive blocks.",
    choices: [
      {
        value: "between_blocks",
        description: "Add blank line between directive blocks",
      },
      { value: "none", description: "No blank lines between directives" },
      { value: "preserve", description: "Preserve original spacing" },
    ],
  },
  bladeSlotFormatting: {
    type: "choice",
    category: "Blade",
    default: "compact",
    description: "Formatting style for component slots.",
    choices: [
      {
        value: "compact",
        description: "Compact for simple slots, block for complex",
      },
      {
        value: "block",
        description: "Always use block formatting with extra newlines",
      },
    ],
  },
  bladeSlotNameStyle: {
    type: "choice",
    category: "Blade",
    default: "colon",
    description: "How slot names are rendered (colon vs attribute syntax).",
    choices: [
      { value: "colon", description: "Use colon syntax: <x-slot:header>" },
      {
        value: "attribute",
        description: 'Use attribute syntax: <x-slot name="header">',
      },
      { value: "preserve", description: "Preserve original syntax" },
    ],
  },
  bladeSlotSpacing: {
    type: "choice",
    category: "Blade",
    default: "after",
    description: "Spacing (blank lines) around slot elements.",
    choices: [
      { value: "none", description: "No blank lines around slots" },
      { value: "after", description: "Blank line after slots" },
      { value: "before", description: "Blank line before slots" },
      { value: "around", description: "Blank lines before and after slots" },
    ],
  },
  bladeWrapAttributes: {
    type: "choice",
    category: "Blade",
    default: "auto",
    description: "When to wrap HTML/component attributes to multiple lines.",
    choices: [
      {
        value: "auto",
        description: "Wrap when line exceeds print width",
      },
      {
        value: "always",
        description: "Always wrap attributes (one per line)",
      },
      { value: "never", description: "Never wrap attributes" },
    ],
  },
  bladeAttributeSort: {
    type: "choice",
    category: "Blade",
    default: "none",
    description: "How to sort attributes on HTML elements and components.",
    choices: [
      { value: "none", description: "Preserve original order" },
      { value: "alphabetical", description: "Sort alphabetically" },
      {
        value: "by_type",
        description: "Sort by type (HTML > data-* > Alpine > Livewire)",
      },
    ],
  },
  bladeClosingBracketStyle: {
    type: "choice",
    category: "Blade",
    default: "same_line",
    description:
      "Where the closing bracket appears when attributes are wrapped.",
    choices: [
      {
        value: "same_line",
        description: "On same line as last attribute",
      },
      { value: "new_line", description: "On its own line" },
    ],
  },
  bladeSelfClosingStyle: {
    type: "choice",
    category: "Blade",
    default: "preserve",
    description: "How to format empty elements.",
    choices: [
      { value: "preserve", description: "Preserve original style" },
      { value: "always", description: "Use self-closing syntax" },
      { value: "never", description: "Use explicit close tags" },
    ],
  },
  bladeHtmlBlockSpacing: {
    type: "choice",
    category: "Blade",
    default: "between_blocks",
    description: "Blank lines between block-level HTML element siblings.",
    choices: [
      {
        value: "between_blocks",
        description: "Add blank line between block elements",
      },
      { value: "none", description: "No blank lines between block elements" },
      { value: "preserve", description: "Preserve original spacing" },
    ],
  },
  bladeEchoSpacing: {
    type: "choice",
    category: "Blade",
    default: "spaced",
    description: "Spacing inside echo braces {{ }} and {!! !!}.",
    choices: [
      { value: "spaced", description: "Always add spaces: {{ $var }}" },
      { value: "compact", description: "No spaces: {{$var}}" },
      { value: "preserve", description: "Preserve original spacing" },
    ],
  },
  bladeTrailingNewline: {
    type: "boolean",
    category: "Blade",
    default: true,
    description: "Add a trailing newline at the end of formatted output.",
  },
};

/** @type {Record<string, any>} */
export const defaultOptions = {
  tabWidth: 4,
  printWidth: 120,
};
