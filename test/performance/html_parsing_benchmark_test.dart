import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('HTML Parsing Performance Benchmark Tests', () {
    test('Parser maintains ≥1000 lines/sec throughput for HTML', () {
      final parser = BladeParser();

      // Create a template with 1000 lines of HTML
      final template = '<div class="container"></div>\n' * 1000;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      final linesPerSecond = 1000 / (stopwatch.elapsedMilliseconds / 1000);

      print('Performance: ${linesPerSecond.toStringAsFixed(2)} lines/sec');
      print('Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(linesPerSecond, greaterThanOrEqualTo(1000),
          reason: 'Parser should handle at least 1000 lines/sec');
    });

    test('Parser handles complex mixed Blade/HTML at speed', () {
      final parser = BladeParser();

      // Create a realistic template with mixed content (100 iterations)
      final template = '''
        <div class="container">
          @if(\$user->isActive)
            <div class="user-card" x-data="{open: false}">
              <h2>{{\$user->name}}</h2>
              <p>{{\$user->email}}</p>
              @foreach(\$user->posts as \$post)
                <article class="post">
                  <h3>{{\$post->title}}</h3>
                  <button wire:click="like({{\$post->id}})">Like</button>
                </article>
              @endforeach
            </div>
          @endif
        </div>
      ''' *
          100;

      final lineCount = template.split('\n').length;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      final linesPerSecond = lineCount / (stopwatch.elapsedMilliseconds / 1000);

      print(
          'Complex template performance: ${linesPerSecond.toStringAsFixed(2)} lines/sec');
      print('Lines: $lineCount, Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(linesPerSecond, greaterThanOrEqualTo(1000),
          reason: 'Parser should maintain speed with complex templates');
    });

    test('Parser handles deeply nested HTML efficiently', () {
      final parser = BladeParser();

      // Create deeply nested structure (20 levels deep)
      var template = '';
      for (var i = 0; i < 20; i++) {
        template += '<div class="level-$i">';
      }
      template += 'Content';
      for (var i = 0; i < 20; i++) {
        template += '</div>';
      }

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      print('Nested HTML parsing time: ${stopwatch.elapsedMilliseconds}ms');

      // Should complete in reasonable time (< 100ms for 20 levels)
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Deeply nested HTML should parse efficiently');
    });

    test('Parser handles large number of attributes efficiently', () {
      final parser = BladeParser();

      // Create element with many attributes
      var template = '<div ';
      for (var i = 0; i < 50; i++) {
        template += 'data-attr-$i="value-$i" ';
      }
      template += '></div>';

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      final element = result.ast!.children[0] as HtmlElementNode;
      expect(element.attributes.length, 50);

      print('Attribute parsing time: ${stopwatch.elapsedMilliseconds}ms');

      // Should complete quickly (< 50ms for 50 attributes)
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Attribute parsing should be efficient');
    });

    test('Parser handles large documents without memory issues', () {
      final parser = BladeParser();

      // Create a large template (5000 lines)
      final template = '''
        <div class="container">
          <p class="text">Some content here</p>
          <span class="highlight">Highlighted text</span>
          <input type="text" name="field" required>
          <button type="submit">Submit</button>
        </div>
      ''' *
          1000; // 5000+ lines

      final lineCount = template.split('\n').length;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);

      final linesPerSecond = lineCount / (stopwatch.elapsedMilliseconds / 1000);

      print(
          'Large document: $lineCount lines in ${stopwatch.elapsedMilliseconds}ms');
      print('Performance: ${linesPerSecond.toStringAsFixed(2)} lines/sec');

      expect(linesPerSecond, greaterThanOrEqualTo(1000),
          reason: 'Parser should maintain speed with large documents');
    });

    test('No performance regression from baseline', () {
      final parser = BladeParser();

      // Baseline: pure Blade template (no HTML)
      final bladeTemplate = '@if(\$test)\n  {{ \$value }}\n@endif\n' * 500;

      final bladeStopwatch = Stopwatch()..start();
      final bladeResult = parser.parse(bladeTemplate);
      bladeStopwatch.stop();

      expect(bladeResult.isSuccess, isTrue);

      // HTML template with similar complexity
      final htmlTemplate = '<div>\n  <p>Text</p>\n</div>\n' * 500;

      final htmlStopwatch = Stopwatch()..start();
      final htmlResult = parser.parse(htmlTemplate);
      htmlStopwatch.stop();

      expect(htmlResult.isSuccess, isTrue);

      print('Blade template: ${bladeStopwatch.elapsedMilliseconds}ms');
      print('HTML template: ${htmlStopwatch.elapsedMilliseconds}ms');

      // HTML parsing should be comparable to Blade parsing (within 2x)
      expect(htmlStopwatch.elapsedMilliseconds,
          lessThan(bladeStopwatch.elapsedMilliseconds * 2),
          reason: 'HTML parsing should not significantly slow down the parser');
    });

    test('Void element recognition is fast', () {
      final parser = BladeParser();

      // Template with many void elements
      final template = '''
        <br>
        <input type="text">
        <img src="image.jpg">
        <hr>
        <meta charset="utf-8">
        <link rel="stylesheet">
      ''' *
          100;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      print('Void element parsing: ${stopwatch.elapsedMilliseconds}ms');

      // Should be very fast (< 100ms for 600 void elements)
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Void element recognition should be O(1)');
    });

    test('Attribute categorization performance', () {
      final parser = BladeParser();

      // Template with mixed attribute types
      final template = '''
        <div
          class="container"
          id="app"
          data-user="123"
          x-data="{count: 0}"
          @click="increment"
          :class="active"
          wire:click="save"
          wire:loading.class="opacity-50"
          disabled>
        </div>
      ''' *
          100;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);

      print('Attribute categorization: ${stopwatch.elapsedMilliseconds}ms');

      // Should categorize efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Attribute categorization should be pattern-based and fast');
    });
  });
}
