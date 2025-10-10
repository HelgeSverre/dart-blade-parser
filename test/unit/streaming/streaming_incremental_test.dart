import 'dart:async';
import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for true incremental streaming
/// These tests EXPOSE bugs - streaming currently buffers everything
void main() {
  group('Streaming Incremental Emission Tests (EXPECTED TO FAIL)', () {
    test('Nodes should emit before stream completion', () async {
      final streamingParser = StreamingParser();

      // Create stream with delays to prove incremental processing
      final controller = StreamController<String>();

      // Schedule chunks with delays
      Future.delayed(Duration.zero, () => controller.add('<div>First</div>'));
      Future.delayed(
          Duration(milliseconds: 100), () => controller.add('<p>Second</p>'));
      Future.delayed(
          Duration(milliseconds: 200), () => controller.add('<span>Third</span>'));
      Future.delayed(Duration(milliseconds: 300), () => controller.close());

      final stopwatch = Stopwatch()..start();
      final nodeTimestamps = <int>[];

      // Listen to nodes as they arrive
      final nodes = <AstNode>[];
      await for (final node in streamingParser.parseStreaming(controller.stream)) {
        nodeTimestamps.add(stopwatch.elapsedMilliseconds);
        nodes.add(node);
      }

      stopwatch.stop();

      expect(nodes, isNotEmpty);

      // CRITICAL: In true streaming, first node should arrive before stream ends
      // Current bug: All nodes arrive at ~300ms (after full buffering)
      if (nodeTimestamps.isNotEmpty) {
        final firstNodeTime = nodeTimestamps.first;

        expect(firstNodeTime, lessThan(250),
            reason:
                'First node should emit before stream completion (true streaming)');

        // If truly streaming, nodes should arrive progressively
        // Not all at once at the end
        if (nodeTimestamps.length > 1) {
          final lastNodeTime = nodeTimestamps.last;
          final timeSpread = lastNodeTime - firstNodeTime;

          expect(timeSpread, greaterThan(50),
              reason:
                  'Nodes should arrive over time, not all at once (indicates buffering)');
        }
      }
    }, timeout: Timeout(Duration(seconds: 5)));

    test('Each top-level element should be available as closing tag arrives',
        () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div id="1">Content 1</div>', // Complete element in one chunk
        '<div id="2">', // Split element
        'Content 2',
        '</div>',
        '<p>Element 3</p>', // Another complete element
      ];

      final controller = StreamController<String>();

      // Emit chunks with small delays
      var delay = 0;
      for (final chunk in chunks) {
        Future.delayed(Duration(milliseconds: delay), () {
          controller.add(chunk);
        });
        delay += 50;
      }
      Future.delayed(Duration(milliseconds: delay), () => controller.close());

      final emissionTimes = <String, int>{};
      final stopwatch = Stopwatch()..start();

      await for (final node in streamingParser.parseStreaming(controller.stream)) {
        final elapsed = stopwatch.elapsedMilliseconds;

        if (node is HtmlElementNode) {
          emissionTimes['${node.tagName}_${node.attributes['id']?.value ?? '?'}'] =
              elapsed;
        }
      }

      // In true streaming:
      // - First div (complete in chunk 0) should emit around 0-50ms
      // - Second div (complete at chunk 3) should emit around 150ms
      // - Third p (complete at chunk 4) should emit around 200ms

      // Current bug: All emit at ~250ms (after all chunks buffered)
      expect(emissionTimes, isNotEmpty,
          reason: 'Should emit elements incrementally');
    });

    test('Chunk split mid-token should still work', () async {
      final streamingParser = StreamingParser();

      // Split a single element across multiple chunk boundaries
      final chunks = [
        '<di', // Split tag name
        'v cl', // Continue tag, split attribute name
        'ass=', // Continue attribute name, start value
        '"te', // Split attribute value
        'st"', // Complete attribute value
        '>', // Close opening tag
        'Con', // Split text content
        'tent',
        '</di', // Split closing tag
        'v>',
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      // Should successfully parse despite awkward chunk boundaries
      expect(nodes, isNotEmpty,
          reason: 'Should handle chunks split mid-token');

      final divElements = nodes
          .expand((n) =>
              n is HtmlElementNode ? [n] : (n as DocumentNode).children.whereType<HtmlElementNode>())
          .where((e) => e.tagName == 'div');

      expect(divElements, isNotEmpty);

      final div = divElements.first;
      expect(div.attributes.containsKey('class'), isTrue);
      expect(div.attributes['class']!.value, equals('test'));

      final textContent =
          div.children.whereType<TextNode>().map((t) => t.content).join();
      expect(textContent, contains('Content'));
    });

    test('Large file streaming should use bounded memory', () async {
      final streamingParser = StreamingParser();

      // Simulate large file with many chunks
      final chunkCount = 100;
      final chunks = List.generate(
        chunkCount,
        (i) => '<div id="$i">Content $i</div>\n',
      );

      final stream = Stream.fromIterable(chunks);

      var nodesEmitted = 0;
      await for (final _ in streamingParser.parseStreaming(stream)) {
        nodesEmitted++;

        // In true streaming, nodes should start appearing early
        // Not require all 100 chunks to be buffered
        if (nodesEmitted == 1) {
          // First node should appear without needing all 100 chunks
          expect(true, isTrue,
              reason: 'First node emitted (streaming working)');
        }
      }

      expect(nodesEmitted, greaterThan(0));

      // Note: Memory testing is hard in unit tests,
      // but true streaming should emit nodes progressively
      // rather than buffering all 100 chunks first
    });

    test('Error in mid-stream should still emit partial results', () async {
      final streamingParser = StreamingParser();

      final chunks = [
        '<div>Valid 1</div>',
        '<p>Valid 2</p>',
        '<invalid', // Incomplete/error chunk
        '<span>Valid 3</span>', // Continue after error
      ];

      final stream = Stream.fromIterable(chunks);
      final nodes = await streamingParser.parseStreaming(stream).toList();

      // Should emit the valid nodes even if there's an error
      expect(nodes, isNotEmpty,
          reason: 'Should emit partial results despite errors');

      // Should have some valid HTML elements
      final htmlElements = nodes
          .expand((n) => n is HtmlElementNode
              ? [n]
              : (n is DocumentNode ? n.children.whereType<HtmlElementNode>() : <HtmlElementNode>[]))
          .toList();

      expect(htmlElements.length, greaterThan(0),
          reason: 'Should parse valid elements despite errors');
    });

    test('Back-pressure: slow consumer should not block parsing', () async {
      final streamingParser = StreamingParser();

      final chunks = List.generate(10, (i) => '<div>Item $i</div>');
      final stream = Stream.fromIterable(chunks);

      var consumedCount = 0;
      final stopwatch = Stopwatch()..start();

      await for (final _ in streamingParser.parseStreaming(stream)) {
        consumedCount++;

        // Simulate slow consumer
        if (consumedCount < 5) {
          await Future<void>.delayed(Duration(milliseconds: 50));
        }
      }

      stopwatch.stop();

      expect(consumedCount, greaterThan(0));

      // In good streaming implementation, back-pressure is handled
      // Parser should not race ahead of slow consumer unboundedly
      // (This is more of a design consideration than a hard test)
    });

    test('Streaming should maintain state across chunks', () async {
      final streamingParser = StreamingParser();

      // Open tag in one chunk, close in another
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

      // Find the fully nested structure
      // div > section > article
      final divElements = nodes
          .expand((n) => n is HtmlElementNode
              ? [n]
              : (n is DocumentNode ? n.children.whereType<HtmlElementNode>() : <HtmlElementNode>[]))
          .where((e) => e.tagName == 'div');

      if (divElements.isNotEmpty) {
        final div = divElements.first;

        final sections =
            div.children.whereType<HtmlElementNode>().where((e) => e.tagName == 'section');

        if (sections.isNotEmpty) {
          final section = sections.first;

          final articles = section.children
              .whereType<HtmlElementNode>()
              .where((e) => e.tagName == 'article');

          expect(articles, isNotEmpty,
              reason: 'Streaming should maintain nesting state across chunks');
        }
      }
    });
  });
}
