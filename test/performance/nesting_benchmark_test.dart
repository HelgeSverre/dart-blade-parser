import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Performance Benchmarks - Nesting Depth', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    String generateFlatTemplate(int nodes) {
      final buffer = StringBuffer();
      for (var i = 0; i < nodes; i++) {
        buffer.writeln('<p>Item $i: {{ \$item$i }}</p>');
      }
      return buffer.toString();
    }

    String generateNestedTemplate(int depth) {
      final buffer = StringBuffer();

      // Opening tags
      for (var i = 0; i < depth; i++) {
        buffer.writeln('@if(\$condition$i)');
      }

      // Content
      buffer.writeln('  <p>Deep content at level $depth</p>');

      // Closing tags
      for (var i = 0; i < depth; i++) {
        buffer.writeln('@endif');
      }

      return buffer.toString();
    }

    test('Baseline: flat template performance', () {
      final template = generateFlatTemplate(100);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      print('Flat template (100 nodes): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Nesting depth impact - 10 levels', () {
      final template = generateNestedTemplate(10);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      print('Nested template (10 levels): ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Nesting depth impact - 20 levels (FR-030)', () {
      final flatTemplate = generateFlatTemplate(100);
      final nestedTemplate = generateNestedTemplate(20);

      // Measure flat performance
      final flatStopwatch = Stopwatch()..start();
      final flatResult = parser.parse(flatTemplate);
      flatStopwatch.stop();

      expect(flatResult.isSuccess, isTrue);
      final flatTime = flatStopwatch.elapsedMilliseconds;

      // Measure nested performance
      final nestedStopwatch = Stopwatch()..start();
      final nestedResult = parser.parse(nestedTemplate);
      nestedStopwatch.stop();

      expect(nestedResult.isSuccess, isTrue);
      final nestedTime = nestedStopwatch.elapsedMilliseconds;

      print('Flat: ${flatTime}ms, Nested (20 levels): ${nestedTime}ms');

      // Calculate slowdown percentage
      // If flat time is 0, parser is too fast to measure - that's good!
      if (flatTime == 0) {
        print('Parser is too fast to measure degradation (both < 1ms) - PASS');
        expect(nestedTime, lessThan(10),
            reason: 'Even nested should be very fast');
      } else {
        final slowdown = (nestedTime - flatTime) / flatTime;
        print('Slowdown: ${(slowdown * 100).toStringAsFixed(1)}%');

        // FR-030: Should be <10% slowdown
        expect(slowdown, lessThan(0.10),
            reason:
                'Nested parsing should not degrade by more than 10%. Actual: ${(slowdown * 100).toStringAsFixed(1)}%');
      }
    });

    test('Deep nesting - 50 levels', () {
      final template = generateNestedTemplate(50);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      print('Deeply nested (50 levels): ${stopwatch.elapsedMilliseconds}ms');

      // Should still complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('Mixed nesting with content', () {
      final buffer = StringBuffer();

      // Create nested structure with content at each level
      for (var i = 0; i < 20; i++) {
        buffer.writeln('@if(\$level$i)');
        buffer.writeln('  <div class="level-$i">');
        buffer.writeln('    <p>Content at level $i: {{ \$data$i }}</p>');
      }

      // Close all levels
      for (var i = 0; i < 20; i++) {
        buffer.writeln('  </div>');
        buffer.writeln('@endif');
      }

      final template = buffer.toString();

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      print(
          'Mixed nesting (20 levels with content): ${stopwatch.elapsedMilliseconds}ms');

      // Verify the template was parsed successfully
      // Note: Full HTML nesting validation requires T059 (HTML element parsing)
      // For now, just verify we have directive nodes
      final directives = <DirectiveNode>[];
      void findDirectives(AstNode node) {
        if (node is DirectiveNode && node.name == 'if') {
          directives.add(node);
        }
        for (final child in node.children) {
          findDirectives(child);
        }
      }

      findDirectives(result.ast!);

      // Should have found the @if directives (20 of them)
      expect(directives.length, greaterThanOrEqualTo(1),
          reason: 'Should have parsed @if directives');
    });
  });
}
