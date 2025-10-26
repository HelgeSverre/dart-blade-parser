# Blade Parser Examples

Visual demonstrations of the Blade parser features.

## Memory Visualization

Demonstrates memory usage patterns when parsing Blade templates of various sizes:

```bash
dart run example/memory_visualization.dart
```

**What it shows:**

- Memory usage for templates of different sizes (1KB to 1MB)
- AST node counts and structure
- Memory efficiency of the parser
- Performance characteristics

**Key Metrics:**

- Parse time vs file size
- Memory consumption patterns
- AST complexity analysis
- Token generation efficiency

## Running the Example

From the project root:

```bash
# Run memory visualization
dart run example/memory_visualization.dart
```

## What You'll See

The example parses templates of increasing complexity and displays:

- File size
- Parse duration
- Number of tokens generated
- Number of AST nodes
- Memory usage estimates

This helps understand the parser's performance characteristics and resource requirements for different template sizes.
