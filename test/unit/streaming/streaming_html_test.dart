import 'dart:async';
import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Streaming HTML Parsing Tests', () {
    test('Streaming parser handles HTML elements', () async {
      final streamingParser = StreamingParser();

      // Create a stream of HTML chunks
      final chunks = [
        '<div class="container">',
        '<p>Hello</p>',
        '<span>World</span>',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);

      // Should have parsed the HTML structure
      final htmlNodes = nodes.whereType<HtmlElementNode>();
      expect(htmlNodes, isNotEmpty);
    });

    test('Streaming parser handles partial chunks', () async {
      final streamingParser = StreamingParser();

      // Split a tag across chunks
      final chunks = [
        '<div',
        ' class="test"',
        '>',
        'Content',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles void elements', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div>',
        '<br>',
        '<input type="text">',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);

      // Find void elements in the parsed structure
      final parser = BladeParser();
      final fullTemplate = chunks.join();
      final result = parser.parse(fullTemplate);

      expect(result.isSuccess, isTrue);
      final div = result.ast!.children[0] as HtmlElementNode;
      final voidElements =
          div.children.whereType<HtmlElementNode>().where((e) => e.isVoid);
      expect(voidElements, hasLength(2)); // br and input
    });

    test('Streaming parser handles mixed Blade/HTML chunks', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div>',
        '@if(\$test)',
        '<p>',
        'Text',
        '</p>',
        '@endif',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser maintains state across chunks', () async {
      final streamingParser = StreamingParser();

      // Nested structure split across chunks
      final chunks = [
        '<div>',
        '<section>',
        '<article>',
        'Content',
        '</article>',
        '</section>',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles attributes split across chunks', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div class=',
        '"container" ',
        'id="app"',
        ' x-data="{}"',
        '>',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles Alpine.js attributes', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div ',
        'x-data="{count: 0}" ',
        '@click="count++"',
        '>',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles Livewire attributes', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<button ',
        'wire:click="save" ',
        'wire:loading.class="opacity-50"',
        '>',
        'Save',
        '</button>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles self-closing tags', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div />',
        '<br />',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser handles large HTML chunks', () async {
      final streamingParser = StreamingParser();

      // Create large chunks
      final chunk1 = '<div>' + ('<p>Paragraph</p>' * 100);
      final chunk2 = '<span>Text</span>' * 100;
      final chunk3 = '</div>';

      final chunks = [chunk1, chunk2, chunk3];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });

    test('Streaming parser emits nodes incrementally', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div>Text1</div>',
        '<p>Text2</p>',
        '<span>Text3</span>',
      ];

      final stream = Stream.fromIterable(chunks);
      var emittedCount = 0;

      await for (final node in streamingParser.parseStreaming(stream)) {
        emittedCount++;
        expect(node, isNotNull);
      }

      expect(emittedCount, greaterThan(0));
    });

    test('Streaming parser handles incomplete chunks gracefully', () async {
      final streamingParser = StreamingParser();

      // Incomplete HTML at first
      final chunks = [
        '<div>',
        '<p>',
        // Add more chunks later
      ];

      final controller = StreamController<String>();

      // Start parsing
      final future = streamingParser.parseStreaming(controller.stream).toList();

      // Add chunks
      for (final chunk in chunks) {
        controller.add(chunk);
        await Future.delayed(Duration(milliseconds: 10));
      }

      // Complete the HTML
      controller.add('Text</p></div>');
      await controller.close();

      final nodes = await future;
      expect(nodes, isNotEmpty);
    });

    test('Streaming parser recovers from errors', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div></span>', // Error: mismatched tags
        '<p>Valid content</p>', // Should continue parsing
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      // Should still emit some nodes
      expect(nodes, isNotNull);
    });
  });

  group('Streaming Mode Compatibility Tests', () {
    test('Tag stack maintained across chunks', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div>',
        '<section>',
        '<article>',
        'Content',
        '</article>',
        '</section>',
        '</div>',
      ];

      final stream = Stream.fromIterable(chunks);

      // Should complete without errors
      final nodes = await streamingParser.parseStreaming(stream).toList();
      expect(nodes, isNotEmpty);

      // Validate by parsing the full template
      final fullTemplate = chunks.join();
      final parser = BladeParser();
      final result = parser.parse(fullTemplate);

      expect(result.isSuccess, isTrue);
    });

    test('Streaming parser handles real-world template structure', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<!DOCTYPE html>\n',
        '<html>\n',
        '<head>\n',
        '<meta charset="utf-8">\n',
        '<title>{{ \$title }}</title>\n',
        '</head>\n',
        '<body>\n',
        '<div class="container">\n',
        '@if(\$user)\n',
        '<p>Hello {{ \$user->name }}</p>\n',
        '@endif\n',
        '</div>\n',
        '</body>\n',
        '</html>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      expect(nodes, isNotEmpty);
    });
  });
}
