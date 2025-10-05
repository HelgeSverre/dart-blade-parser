import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Performance Benchmarks - Throughput', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    String generateTemplate(int lines) {
      final buffer = StringBuffer();
      for (var i = 0; i < lines; i++) {
        if (i % 10 == 0) {
          buffer.writeln('@if(\$condition$i)');
        } else if (i % 10 == 5) {
          buffer.writeln('@else');
        } else if (i % 10 == 9) {
          buffer.writeln('@endif');
        } else {
          buffer.writeln('  <p>Line $i: {{ \$data->item$i }}</p>');
        }
      }
      return buffer.toString();
    }

    test('Parse 1000 lines in ≤1 second (FR-027)', () {
      final template = generateTemplate(1000);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
        reason: 'Should parse 1000 lines in under 1 second. Took: ${stopwatch.elapsedMilliseconds}ms');

      final linesPerSecond = 1000 / (stopwatch.elapsedMilliseconds / 1000);
      print('Throughput: ${linesPerSecond.toStringAsFixed(0)} lines/sec');
      expect(linesPerSecond, greaterThanOrEqualTo(1000));
    });

    test('Parse 5000 lines maintains throughput', () {
      final template = generateTemplate(5000);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);

      final linesPerSecond = 5000 / (stopwatch.elapsedMilliseconds / 1000);
      print('Throughput (5000 lines): ${linesPerSecond.toStringAsFixed(0)} lines/sec');

      // Should still maintain ≥1000 lines/sec
      expect(linesPerSecond, greaterThanOrEqualTo(1000));
    });

    test('Parse 10000 lines in <10 seconds (FR-027)', () {
      final template = generateTemplate(10000);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);
      expect(stopwatch.elapsed.inSeconds, lessThan(10),
        reason: 'Should parse 10k lines in under 10 seconds. Took: ${stopwatch.elapsed.inSeconds}s');

      final linesPerSecond = 10000 / (stopwatch.elapsedMilliseconds / 1000);
      print('Throughput (10k lines): ${linesPerSecond.toStringAsFixed(0)} lines/sec');
    });

    test('Measure tokens per second', () {
      final template = generateTemplate(1000);

      final stopwatch = Stopwatch()..start();
      final lexer = BladeLexer(template);
      final tokens = lexer.tokenize();
      stopwatch.stop();

      final tokensPerSecond = tokens.length / (stopwatch.elapsedMilliseconds / 1000);
      print('Lexer throughput: ${tokensPerSecond.toStringAsFixed(0)} tokens/sec');

      expect(tokensPerSecond, greaterThan(1000)); // Should be very fast
    });

    test('Complex template with nested directives', () {
      final buffer = StringBuffer();
      for (var i = 0; i < 100; i++) {
        buffer.writeln('@foreach(\$items$i as \$item$i)');
        buffer.writeln('  @if(\$item$i->active)');
        buffer.writeln('    <div class="item">');
        buffer.writeln('      <h3>{{ \$item$i->title }}</h3>');
        buffer.writeln('      <p>{{ \$item$i->description }}</p>');
        buffer.writeln('    </div>');
        buffer.writeln('  @endif');
        buffer.writeln('@endforeach');
      }

      final template = buffer.toString();
      final lineCount = template.split('\n').length;

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);

      final linesPerSecond = lineCount / (stopwatch.elapsedMilliseconds / 1000);
      print('Complex template: ${linesPerSecond.toStringAsFixed(0)} lines/sec ($lineCount lines)');

      expect(linesPerSecond, greaterThanOrEqualTo(1000));
    });
  });
}
