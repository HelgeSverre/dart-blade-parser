import 'dart:async';
import 'package:blade_parser/blade_parser.dart';

/// Side-by-side comparison: Regular vs Streaming parsing
void main() async {
  print('\n╔════════════════════════════════════════════════════════════╗');
  print('║    Regular Parsing vs Streaming Parsing Comparison        ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  // Create a template with multiple top-level nodes
  final template = generateLargeTemplate(100);

  print(
      'Template: ${template.split('\n').length} lines, ${template.length} characters\n');
  print('═' * 60);

  // REGULAR PARSING
  print('\n📋 REGULAR PARSING (Full Parse Mode)');
  print('─' * 60);
  final regularStart = DateTime.now();

  final parser = BladeParser();
  final result = parser.parse(template);

  final regularEnd = DateTime.now();
  final regularTime = regularEnd.difference(regularStart).inMilliseconds;

  print('⏱️  Parse time: ${regularTime}ms');
  print('💾 Memory: Entire AST in memory at once');
  print('📊 Nodes: ${result.ast!.children.length} nodes');
  print('⚠️  Limitation: Must wait for entire file before processing');

  // STREAMING PARSING
  print('\n\n🌊 STREAMING PARSING (Incremental Mode)');
  print('─' * 60);

  final streamingStart = DateTime.now();
  var streamedNodeCount = 0;
  final emittedNodes = <String>[];

  // Create stream from template chunks
  final controller = StreamController<String>();
  final streamingParser = StreamingParser();

  // Start listening before adding chunks
  final streamFuture =
      streamingParser.parseStreaming(controller.stream).forEach((node) {
    streamedNodeCount++;
    final timestamp = DateTime.now().difference(streamingStart).inMilliseconds;
    emittedNodes
        .add('  [$timestamp ms] Node #$streamedNodeCount: ${_nodeType(node)}');
  });

  // Simulate streaming chunks
  final lines = template.split('\n');
  for (final line in lines) {
    controller.add('$line\n');
    await Future<void>.delayed(Duration.zero); // Allow stream to process
  }

  await controller.close();
  await streamFuture;

  final streamingEnd = DateTime.now();
  final streamingTime = streamingEnd.difference(streamingStart).inMilliseconds;

  print('⏱️  Parse time: ${streamingTime}ms');
  print('💾 Memory: Only buffered incomplete nodes');
  print('📊 Nodes emitted: $streamedNodeCount');
  print('✅ Benefit: Process nodes as they arrive!');

  print('\n📦 Emission timeline:');
  for (final emission in emittedNodes.take(5)) {
    print(emission);
  }
  if (emittedNodes.length > 5) {
    print('  ... and ${emittedNodes.length - 5} more nodes');
  }

  // COMPARISON
  print('\n\n📊 COMPARISON');
  print('═' * 60);
  print('│ Metric              │ Regular  │ Streaming            │');
  print('├─────────────────────┼──────────┼──────────────────────┤');
  print(
      '│ Parse Time          │ ${regularTime.toString().padRight(8)} │ ${streamingTime.toString().padRight(20)} │');
  print('│ Memory Usage        │ O(n)     │ O(buffered)          │');
  print('│ First Node Ready    │ ${regularTime}ms    │ ~0ms (immediate)     │');
  print('│ Processing Model    │ Batch    │ Incremental          │');
  print('│ Use Case            │ Small    │ Large files (10k+)   │');
  print('└─────────────────────┴──────────┴──────────────────────┘');

  print('\n💡 Key Insight:');
  print('   Streaming mode lets you process nodes BEFORE the entire');
  print('   file is read, crucial for 10,000+ line templates!\n');
}

String generateLargeTemplate(int sections) {
  final buffer = StringBuffer();
  for (var i = 0; i < sections; i++) {
    buffer.writeln('@if(\$condition_$i)');
    buffer.writeln('  <div>Content $i</div>');
    buffer.writeln('@endif');
    buffer.writeln();
  }
  return buffer.toString();
}

String _nodeType(AstNode node) {
  if (node is DirectiveNode) return '@${node.name}';
  if (node is ComponentNode) return '<x-${node.name}>';
  if (node is EchoNode) return '{{ echo }}';
  if (node is TextNode) return 'text';
  return node.runtimeType.toString();
}
