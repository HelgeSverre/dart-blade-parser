# Editor Setup

How to set up `prettier-plugin-laravel-blade` in your editor for automatic Blade template formatting.

## Prerequisites

Install Prettier and the plugin in your Laravel project:

```bash
npm install --save-dev prettier-plugin-laravel-blade prettier
```

Create a `.prettierrc` in your project root:

```json
{
  "plugins": ["prettier-plugin-laravel-blade"]
}
```

You can also add Blade-specific overrides:

```json
{
  "plugins": ["prettier-plugin-laravel-blade"],
  "overrides": [
    {
      "files": "*.blade.php",
      "options": {
        "tabWidth": 4,
        "printWidth": 120,
        "bladeWrapAttributes": "auto",
        "bladeAttributeSort": "by_type"
      }
    }
  ]
}
```

See the [plugin README](../prettier-plugin-laravel-blade/README.md) for the full list of Blade-specific options.

Verify the setup works from the command line before configuring your editor:

```bash
npx prettier --write "resources/views/**/*.blade.php"
```

---

## VS Code (+ Cursor, Windsurf)

Install the [Prettier extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) (`esbenp.prettier-vscode`) from the Extensions panel.

> **Note:** VS Code does not recognize `.blade.php` as a distinct language by default. Install a Blade syntax extension such as [Laravel Blade Snippets](https://marketplace.visualstudio.com/items?itemName=onecentlin.laravel-blade) (`onecentlin.laravel-blade`) to register the `blade` language identifier.

Add to your `settings.json` (Cmd+Shift+P > "Preferences: Open User Settings (JSON)"):

```json
{
  "files.associations": {
    "*.blade.php": "blade"
  },
  "[blade]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  }
}
```

Format manually with Shift+Alt+F (Windows/Linux) or Shift+Option+F (macOS).

**Cursor and Windsurf** are VS Code forks that support the same extension format. The `esbenp.prettier-vscode` extension is available on [Open VSX](https://open-vsx.org/extension/esbenp/prettier-vscode), which both editors use as their extension registry. The configuration above works identically in all three editors.

---

## PHPStorm / JetBrains IDEs

### Using built-in Prettier support

PHPStorm has native Prettier integration. Open **Settings** (Ctrl+Alt+S / Cmd+,) and navigate to:

**Languages & Frameworks > JavaScript > Prettier**

1. Select **Automatic Prettier configuration** (auto-detects your `.prettierrc`) or point to a specific Prettier installation manually.
2. Check **Run on save**.
3. Update the **Run for files** glob to include Blade templates:
   ```
   **/*.{js,ts,jsx,tsx,vue,css,html,blade.php}
   ```
4. Click **Apply**.

PHPStorm will now format Blade files on save using your project's Prettier and `.prettierrc` configuration.

### Using the CLI as an External Tool

If you prefer not to use the built-in Prettier integration (e.g. you want a dedicated keybinding or menu entry for Blade formatting only):

1. Open **Settings** > **Tools** > **External Tools**.
2. Click **+** to add a new tool:
   - **Name:** `Format Blade`
   - **Program:** `npx`
   - **Arguments:** `prettier --write $FilePath$`
   - **Working directory:** `$ProjectFileDir$`
3. Click **OK**.

You can now run it from **Tools > External Tools > Format Blade**, or bind it to a keyboard shortcut via **Settings > Keymap** (search for "Format Blade").

---

## Neovim

### conform.nvim (recommended)

[conform.nvim](https://github.com/stevearc/conform.nvim) is a lightweight formatter plugin for Neovim.

First, register `blade` as a filetype. Add this to your `init.lua` (or an early-loading config file):

```lua
vim.filetype.add({
  pattern = {
    [".*%.blade%.php"] = "blade",
  },
})
```

Then configure conform.nvim:

```lua
require("conform").setup({
  formatters_by_ft = {
    blade = { "prettier" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})
```

conform.nvim resolves `prettier` from your project's `node_modules` automatically, reads your `.prettierrc`, and pipes the buffer through stdin/stdout.

Format manually with `:lua require("conform").format()`, or bind it to a key:

```lua
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true })
end)
```

### Alternative: none-ls.nvim

[none-ls.nvim](https://github.com/nvimtools/none-ls.nvim) (community fork of the deprecated null-ls.nvim) can also run Prettier as a formatting source through Neovim's LSP mechanism. Use conform.nvim for new setups unless you already have a none-ls configuration.

---

## Vim

[vim-prettier](https://github.com/prettier/vim-prettier) provides Prettier integration for Vim 8+ and Neovim.

Install with vim-plug:

```vim
Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }
```

Enable auto-formatting on save:

```vim
let g:prettier#autoformat = 1
let g:prettier#autoformat_require_pragma = 0
```

vim-prettier resolves the Prettier binary from your project's `node_modules` and reads your `.prettierrc` (including plugins). Format manually with `:Prettier` or `:PrettierAsync`.

> **Note:** vim-prettier is minimally maintained (last updated October 2023). For Neovim users, conform.nvim is the recommended alternative.

---

## Zed

Zed supports external formatters configured in `settings.json`. Install the [Blade extension](https://zed.dev/extensions/blade) for syntax highlighting, then configure the formatter.

Open your settings (Cmd+, or Ctrl+,) and add:

```json
{
  "languages": {
    "Blade": {
      "formatter": {
        "external": {
          "command": "npx",
          "arguments": ["prettier", "--stdin-filepath", "{buffer_path}"]
        }
      },
      "format_on_save": "on"
    }
  }
}
```

This can go in your global settings (`~/.config/zed/settings.json`) or per-project (`.zed/settings.json`).

---

## Helix

Helix supports external formatters configured in `languages.toml`. Helix already includes built-in syntax highlighting for Blade templates, so you only need to add a formatter.

Create or edit `~/.config/helix/languages.toml`:

```toml
[[language]]
name = "blade"
formatter = { command = "npx", args = ["prettier", "--stdin-filepath", "file.blade.php"] }
auto-format = true
```

Helix pipes the buffer contents to the formatter's stdin and reads the result from stdout. The `--stdin-filepath` argument tells Prettier to treat the input as a `.blade.php` file so it uses the correct plugin and parser.

---

## Emacs

### apheleia (recommended)

[apheleia](https://github.com/radian-software/apheleia) is a universal code formatter for Emacs that runs formatters asynchronously without moving your cursor.

apheleia ships with a built-in `prettier` formatter and already maps `web-mode` to it. If you use `web-mode` for Blade files (which is the standard choice), formatting works out of the box once apheleia-mode is enabled.

Add to your Emacs config:

```elisp
;; Open .blade.php files in web-mode
(add-to-list 'auto-mode-alist '("\\.blade\\.php\\'" . web-mode))

;; Enable apheleia globally
(apheleia-global-mode +1)
```

That's it. apheleia resolves Prettier from your project's `node_modules` (via its `apheleia-npx` wrapper) and reads your `.prettierrc` automatically.

### Alternative: prettier-js

[prettier-js](https://github.com/prettier/prettier-emacs) is a lighter-weight option if you only need Prettier:

```elisp
(require 'prettier-js)
(add-hook 'web-mode-hook 'prettier-js-mode)
```

To use the project-local Prettier binary:

```elisp
(setq prettier-js-use-modules-bin t)
```

---

## Nova

Install the [Prettier](https://extensions.panic.com/extensions/alexanderweiss/alexanderweiss.prettier/) extension by Alexander Weiss from the Extensions Library (Extensions > Extensions Library, search "Prettier").

The extension automatically detects your `.prettierrc` and uses the Prettier installation from your project's `node_modules`. No additional configuration is needed beyond the [Prerequisites](#prerequisites).

Format on save is enabled by default. Format manually with Option+Shift+F.

Alternatively, [Prettier+](https://extensions.panic.com/extensions/stonerl/stonerl.prettier/) by stonerl is a drop-in replacement that bundles additional language plugins (including Laravel Blade support built-in). If you use Prettier+, disable the original Prettier extension to avoid conflicts.

---

## Lapce

Install the `lapce-prettier` plugin from the [plugin registry](https://plugins.lapce.dev/) (Command Palette > "Install Plugin", search "prettier").

> **Note:** The Lapce Prettier plugin ([hbina/lapce-prettier](https://github.com/hbina/lapce-prettier)) is community-maintained and has limited adoption. If you encounter issues, fall back to running Prettier from the command line:
> ```bash
> npx prettier --write "resources/views/**/*.blade.php"
> ```
