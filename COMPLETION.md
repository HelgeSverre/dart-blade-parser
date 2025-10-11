# Shell Completion Setup

The `blade_parser` CLI supports shell autocompletion for bash, zsh, and fish shells.

## Prerequisites

1. Ensure `blade_parser` is installed and available in your PATH:
   ```bash
   dart pub global activate --source path .
   ```

2. Verify the command is accessible:
   ```bash
   blade_parser --help
   ```

## Installation

The `completion` package provides automatic shell completion installation. The CLI uses the `args` package with the `completion` integration.

### Automatic Installation (Recommended)

Run the built-in completion installer:

```bash
blade_parser completion install
```

This command will:
1. Detect your current shell (bash, zsh, or fish)
2. Generate the appropriate completion script
3. Add it to your shell's configuration

### Supported Shells

- **bash**: Generates bash completion scripts
- **zsh**: Generates zsh completion scripts
- **fish**: Generates fish completion scripts

### Apply Changes

After installation, reload your shell configuration:

```bash
# For bash
source ~/.bashrc

# For zsh
source ~/.zshrc

# For fish (completion is loaded automatically on next shell start)
exec fish
```

## Uninstallation

To remove the completion scripts:

```bash
blade_parser completion uninstall
```

## Usage

Once installed, you can use tab completion with the `blade_parser` command:

```bash
# Press TAB to see available options
blade_parser <TAB>

# Complete option names
blade_parser --<TAB>

# Available completions:
#   --json
#   --tree
#   --stdin
#   --help
```

## Troubleshooting

### Completion not working

1. Ensure the command is in your PATH:
   ```bash
   which blade_parser
   ```

2. Reload your shell configuration:
   ```bash
   source ~/.bashrc  # or ~/.zshrc for zsh
   ```

3. For bash users, you may need `bash-completion` installed:
   ```bash
   # macOS
   brew install bash-completion

   # Ubuntu/Debian
   apt-get install bash-completion
   ```

### Manual Installation

The completion package handles installation automatically. If you encounter issues, please ensure:

1. The `blade_parser` command is available in your PATH
2. You have the latest version of the package installed
3. Your shell is one of the supported shells (bash, zsh, fish)

For advanced manual setup, refer to the [completion package documentation](https://pub.dev/packages/completion).

## What Gets Completed

The completion system provides suggestions for:
- Command options: `--json`, `--tree`, `--stdin`, `--help`, `-h`
- Subcommands: `completion`
- File paths with `.blade.php` extension (if supported by your shell)
