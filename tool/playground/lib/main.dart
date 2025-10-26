import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  runApp(const BladePlaygroundApp());
}

class BladePlaygroundApp extends StatelessWidget {
  const BladePlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blade Parser Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'JetBrains Mono',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'JetBrains Mono'),
          bodySmall: TextStyle(fontFamily: 'JetBrains Mono'),
          labelLarge: TextStyle(fontFamily: 'JetBrains Mono'),
        ),
      ),
      home: const PlaygroundPage(),
    );
  }
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final _controller = TextEditingController(
    text: '''<div class="dashboard">
    @foreach(\$widgets as \$widget)
        @if(\$widget->isVisible())
            <div class="widget">
                <h3>{{ \$widget->title }}</h3>
                <p>{{ \$widget->content }}</p>
            </div>
        @endif
    @endforeach

    @while(\$count > 0)
        <p>Count: {{ \$count }}</p>
    @endwhile
</div>''',
  );

  ParseResult? _result;
  Duration? _parseDuration;
  String _selectedTab = 'json';

  final _parser = BladeParser();

  @override
  void initState() {
    super.initState();
    _parse();
    _controller.addListener(_parse);
  }

  void _parse() {
    final stopwatch = Stopwatch()..start();
    final result = _parser.parse(_controller.text);
    stopwatch.stop();

    setState(() {
      _result = result;
      _parseDuration = stopwatch.elapsed;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildEditorPanel(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: _buildOutputPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.grey[900],
          child: Row(
            children: [
              const Text(
                'Input',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.code_rounded, size: 20),
                tooltip: 'Examples',
                onSelected: _loadExample,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'simple',
                    child: Text('Simple Echo'),
                  ),
                  const PopupMenuItem(
                    value: 'control',
                    child: Text('Control Structures'),
                  ),
                  const PopupMenuItem(
                    value: 'components',
                    child: Text('Components & Slots'),
                  ),
                  const PopupMenuItem(
                    value: 'alpine',
                    child: Text('Alpine.js Attributes'),
                  ),
                  const PopupMenuItem(
                    value: 'nested',
                    child: Text('Nested Directives'),
                  ),
                  const PopupMenuItem(
                    value: 'verbatim',
                    child: Text('Verbatim Blocks'),
                  ),
                  const PopupMenuItem(
                    value: 'errors',
                    child: Text('Multiple Errors'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              height: 1.6,
              letterSpacing: 0,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Enter Blade template here...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          color: Colors.grey[900],
          child: Row(
            children: [
              _buildTabButton('JSON', 'json'),
              _buildTabButton('Tree', 'tree'),
              _buildTabButton('Errors', 'errors'),
              const Spacer(),
              if (_parseDuration != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTimingChip(),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatusChip(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedTab == value;
    return TextButton(
      onPressed: () => setState(() => _selectedTab = value),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.grey,
        backgroundColor: isSelected ? Colors.blue : Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      child: Text(label),
    );
  }

  Widget _buildStatusChip() {
    final hasErrors = _result?.errors.isNotEmpty ?? false;
    return Chip(
      avatar: Icon(
        hasErrors ? Icons.error : Icons.check_circle,
        size: 16,
        color: hasErrors ? Colors.red : Colors.green,
      ),
      label: Text(
        hasErrors ? '${_result!.errors.length} errors' : 'Valid',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: hasErrors
          ? Colors.red.withOpacity(0.2)
          : Colors.green.withOpacity(0.2),
    );
  }

  Widget _buildTimingChip() {
    if (_parseDuration == null) {
      return const SizedBox.shrink();
    }

    final milliseconds = _parseDuration!.inMicroseconds / 1000.0;
    final formattedTime = milliseconds.toStringAsFixed(2);

    return Chip(
      avatar: const Icon(
        Icons.timer,
        size: 16,
        color: Colors.blue,
      ),
      label: Text(
        '${formattedTime}ms',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue.withOpacity(0.2),
    );
  }

  Widget _buildTabContent() {
    if (_result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _getTabContent(),
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          height: 1.6,
          letterSpacing: 0,
        ),
      ),
    );
  }

  String _getTabContent() {
    switch (_selectedTab) {
      case 'json':
        return _formatJson(_result!.ast!.toJson());
      case 'tree':
        return _buildTreeView(_result!.ast!, 0);
      case 'errors':
        return _formatErrors();
      default:
        return '';
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  String _buildTreeView(AstNode node, int depth) {
    final indent = '  ' * depth;
    final buffer = StringBuffer();

    buffer.writeln('$indent${node.runtimeType}');

    if (node is DirectiveNode) {
      buffer.writeln('$indent  name: @${node.name}');
      if (node.expression != null) {
        buffer.writeln('$indent  expression: ${node.expression}');
      }
    } else if (node is EchoNode) {
      buffer.writeln('$indent  expression: ${node.expression}');
      buffer.writeln('$indent  isRaw: ${node.isRaw}');
    } else if (node is TextNode) {
      buffer.writeln('$indent  text: "${node.content}"');
    }

    for (final child in node.children) {
      buffer.write(_buildTreeView(child, depth + 1));
    }

    return buffer.toString();
  }

  String _formatErrors() {
    if (_result!.errors.isEmpty) {
      return 'No errors found! ✨';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < _result!.errors.length; i++) {
      final error = _result!.errors[i];
      buffer.writeln('Error ${i + 1}:');
      buffer.writeln('  Message: ${error.message}');
      buffer.writeln(
        '  Location: line ${error.position.line}, column ${error.position.column}',
      );
      if (error.hint != null) {
        buffer.writeln('  Hint: ${error.hint}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _loadExample(String example) {
    final templates = {
      'simple': '{{ \$user->name }}',
      'control': '''<div class="dashboard">
    @foreach(\$widgets as \$widget)
        @if(\$widget->isVisible())
            <div class="widget">
                <h3>{{ \$widget->title }}</h3>
                <p>{{ \$widget->content }}</p>
            </div>
        @endif
    @endforeach

    @while(\$count > 0)
        <p>Count: {{ \$count }}</p>
    @endwhile
</div>''',
      'components': '''<x-card class="shadow-lg">
    <x-slot:header>
        <h2>Card Title</h2>
    </x-slot>

    <p>Card content goes here</p>

    <x-slot:footer>
        <button>Action</button>
    </x-slot>
</x-card>''',
      'alpine': '''<div x-data="{ open: false }" class="dropdown">
    <button @click="open = !open">Toggle</button>
    <div x-show="open" x-transition>
        <a href="#" :class="{ 'active': isActive }">Link</a>
    </div>
</div>''',
      'nested': '''@if(\$level1)
    @if(\$level2)
        @if(\$level3)
            @if(\$level4)
                @if(\$level5)
                    <p>5 levels deep!</p>
                @endif
            @endif
        @endif
    @endif
@endif''',
      'verbatim': '''@verbatim
    {{ This should not be parsed }}
    {!! Also literal !!}
    @if(\$test)
        This directive is literal too
    @endif
@endverbatim''',
      'errors': '''@if(\$condition)
    <p>Content</p>
    <!-- Missing @endif -->

{{ \$unclosed

@foreach(\$items as \$item)
    {{ \$item }}
    <!-- Missing @endforeach -->''',
    };

    _controller.text = templates[example] ?? '';
  }
}
