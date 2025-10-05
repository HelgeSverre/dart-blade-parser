# Blade Parser Examples

Visual demonstrations of the Blade parser features.

## Streaming Parser Visualization

### 1. Basic Streaming Demo
Shows how the streaming parser processes templates incrementally:

```bash
dart run examples/streaming_demo.dart
```

**Output:**
- Real-time progress as chunks are processed
- AST nodes emitted as they become complete
- Memory efficiency visualization

**What it shows:**
- 📦 Each chunk being read
- ✨ Nodes being emitted immediately when complete
- 💾 Memory usage staying low (buffering only incomplete nodes)

### 2. Regular vs Streaming Comparison
Side-by-side comparison of parsing modes:

```bash
dart run examples/streaming_comparison.dart
```

**Comparison Table:**
```
│ Metric              │ Regular  │ Streaming            │
├─────────────────────┼──────────┼──────────────────────┤
│ Parse Time          │ 5ms      │ 20ms                 │
│ Memory Usage        │ O(n)     │ O(buffered)          │
│ First Node Ready    │ 5ms      │ ~0ms (immediate)     │
│ Processing Model    │ Batch    │ Incremental          │
│ Use Case            │ Small    │ Large files (10k+)   │
└─────────────────────┴──────────┴──────────────────────┘
```

## When to Use Streaming Mode

✅ **Use streaming when:**
- Processing files >10,000 lines
- Memory is constrained (<100MB available)
- You need to start processing before entire file is read
- Building real-time tools (editors, linters)

❌ **Use regular parsing when:**
- Files are <5,000 lines
- You need the complete AST immediately
- Simpler code is preferred
- Performance overhead of streaming isn't worth it

## Key Benefits of Streaming

1. **Memory Efficiency**: O(buffered nodes) instead of O(file size)
2. **Faster Time-to-First-Node**: Start processing immediately
3. **Large File Support**: Handle 100,000+ line templates
4. **Real-time Processing**: Perfect for IDE integrations

## Example Output

From `streaming_demo.dart`:
```
📦 Chunk 16/21: @endif
✨ Node emitted: @if(($user->isAdmin())) [8 children]
   Position: Line 1-16
   Memory: Node #1 (buffer cleared)
```

The emoji-based visualization makes it easy to see:
- 📦 = Chunks being read
- ✨ = Complete nodes being emitted
- 💾 = Memory state
- ⏱️ = Timing information
