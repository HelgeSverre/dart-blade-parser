import 'dart:async';
import 'dart:io';
import 'package:blade_parser/blade_parser.dart';

/// Visual demo of streaming parser showing incremental parsing.
///
/// This demo:
/// 1. Simulates reading a large Blade template chunk by chunk
/// 2. Shows each chunk being processed
/// 3. Emits AST nodes as they become complete
/// 4. Visualizes memory efficiency (only buffering incomplete nodes)
void main() async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║       Blade Parser - Streaming Mode Visualization         ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  // Create a large template split into chunks
  final template = '''
@if(\$user->isAdmin())
  <div class="admin-panel">
    <h1>Admin Dashboard</h1>
    
    @foreach(\$stats as \$stat)
      <div class="stat-card">
        <span>{{ \$stat->name }}</span>
        <span>{{ \$stat->value }}</span>
      </div>
    @endforeach
    
    <x-alert type="info">
      You have {{ \$notifications }} new notifications
    </x-alert>
  </div>
@endif

@section('footer')
  <p>Last updated: {{ \$timestamp }}</p>
@endsection
''';

  // Split into chunks (simulating reading lines from a file)
  final lines = template.split('\n');

  print(
    '📄 Template size: ${template.length} characters, ${lines.length} lines\n',
  );
  print('🔄 Starting streaming parse...\n');
  print('─' * 60);

  // Create stream controller to simulate file reading
  final controller = StreamController<String>();

  // Start streaming parser
  final streamingParser = StreamingParser();
  final nodeStream = streamingParser.parseStreaming(controller.stream);

  // Track what we've emitted
  var nodeCount = 0;
  var chunkCount = 0;

  // Listen to emitted nodes
  final subscription = nodeStream.listen(
    (node) {
      nodeCount++;
      print('\n✨ Node emitted: ${_formatNode(node)}');
      print(
        '   Position: Line ${node.startPosition.line}-${node.endPosition.line}',
      );
      print('   Memory: Node #$nodeCount (buffer cleared)');
    },
    onDone: () {
      print('\n${'─' * 60}');
      print('\n✅ Streaming parse complete!');
      print('   Total nodes emitted: $nodeCount');
      print('   Total chunks processed: $chunkCount');
      print('   Memory usage: O(buffered nodes) not O(file size)');
      print('\n💡 Key benefit: Nodes processed incrementally,');
      print('   not waiting for entire 10,000+ line file!\n');
    },
  );

  // Simulate streaming chunks with delays to visualize
  for (var i = 0; i < lines.length; i++) {
    chunkCount++;
    final chunk = '${lines[i]}\n';

    // Visual progress
    stdout.write('\r📦 Chunk $chunkCount/${lines.length}: ${_preview(chunk)}');

    controller.add(chunk);

    // Small delay to make it visible (remove in production)
    await Future<void>.delayed(Duration(milliseconds: 50));
  }

  // Close stream
  await controller.close();
  await subscription.asFuture<void>();
}

String _formatNode(AstNode node) {
  if (node is DirectiveNode) {
    final expr = node.expression != null
        ? '(${_truncate(node.expression!, 30)})'
        : '';
    return '@${node.name}$expr [${node.children.length} children]';
  } else if (node is ComponentNode) {
    return '<x-${node.name}> [${node.children.length} children]';
  } else if (node is EchoNode) {
    return '{{ ${_truncate(node.expression, 30)} }}';
  } else if (node is TextNode) {
    return 'Text: "${_truncate(node.content.trim(), 40)}"';
  }
  return node.runtimeType.toString();
}

String _preview(String text) {
  final preview = text.trim().replaceAll('\n', ' ');
  return _truncate(preview, 40);
}

String _truncate(String text, int length) {
  if (text.length <= length) return text;
  return '${text.substring(0, length - 3)}...';
}
