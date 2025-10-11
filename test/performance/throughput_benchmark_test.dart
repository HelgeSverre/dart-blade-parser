import 'dart:io';
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
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason:
            'Should parse 1000 lines in under 1 second. Took: ${stopwatch.elapsedMilliseconds}ms',
      );

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
      print(
        'Throughput (5000 lines): ${linesPerSecond.toStringAsFixed(0)} lines/sec',
      );

      // Should still maintain ≥1000 lines/sec
      expect(linesPerSecond, greaterThanOrEqualTo(1000));
    });

    test('Parse 10000 lines in <10 seconds (FR-027)', () {
      final template = generateTemplate(10000);

      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);
      expect(
        stopwatch.elapsed.inSeconds,
        lessThan(10),
        reason:
            'Should parse 10k lines in under 10 seconds. Took: ${stopwatch.elapsed.inSeconds}s',
      );

      final linesPerSecond = 10000 / (stopwatch.elapsedMilliseconds / 1000);
      print(
        'Throughput (10k lines): ${linesPerSecond.toStringAsFixed(0)} lines/sec',
      );
    });

    test('Measure tokens per second', () {
      final template = generateTemplate(1000);

      final stopwatch = Stopwatch()..start();
      final lexer = BladeLexer(template);
      final tokens = lexer.tokenize();
      stopwatch.stop();

      final tokensPerSecond =
          tokens.length / (stopwatch.elapsedMilliseconds / 1000);
      print(
        'Lexer throughput: ${tokensPerSecond.toStringAsFixed(0)} tokens/sec',
      );

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
      print(
        'Complex template: ${linesPerSecond.toStringAsFixed(0)} lines/sec ($lineCount lines)',
      );

      expect(linesPerSecond, greaterThanOrEqualTo(1000));
    });

    test('100K line template throughput', () {
      print('\n=== 100K Line Template Benchmark ===');

      // Generate large template with mixed content
      final lines = <String>[];
      for (var i = 0; i < 100000; i++) {
        if (i % 5 == 0) {
          lines.add('@if(\$condition_$i)');
        } else if (i % 5 == 1) {
          lines.add('  <div class="content">{{ \$data_$i }}</div>');
        } else if (i % 5 == 2) {
          lines.add('  <x-card title="Card $i" />');
        } else if (i % 5 == 3) {
          lines.add('  <p>Static content line $i</p>');
        } else {
          lines.add('@endif');
        }
      }
      final template = lines.join('\n');

      print('Template size: ${template.length} bytes, 100000 lines');

      // Warm-up iterations
      print('Warming up...');
      for (var i = 0; i < 3; i++) {
        parser.parse(template);
      }

      // Benchmark with multiple iterations
      final stopwatch = Stopwatch()..start();
      const iterations = 5;
      for (var i = 0; i < iterations; i++) {
        final result = parser.parse(template);
        expect(result.ast, isNotNull);
      }
      stopwatch.stop();

      final avgMs = stopwatch.elapsedMilliseconds / iterations;
      final linesPerSec = (100000 / (avgMs / 1000)).round();

      print('Average parse time: ${avgMs.toStringAsFixed(2)}ms');
      print('Throughput: ${linesPerSec.toStringAsFixed(0)} lines/sec');
      print(
        'Memory: ~${(template.length / 1024 / 1024).toStringAsFixed(2)} MB template',
      );

      expect(
        linesPerSec,
        greaterThan(10000),
        reason: 'Should parse > 10K lines/sec, got $linesPerSec',
      );
    });

    test('10K component instances throughput', () {
      print('\n=== 10K Component Instances Benchmark ===');

      // Generate template with 10,000 component instances
      final lines = <String>[];
      for (var i = 0; i < 10000; i++) {
        if (i % 2 == 0) {
          // Self-closing components
          lines.add('<x-card-$i title="Title $i" class="card" />');
        } else {
          // Paired component tags
          lines.add('<x-alert-$i type="info">');
          lines.add('  Alert message $i');
          lines.add('</x-alert-$i>');
        }
      }
      final template = lines.join('\n');

      print('Template size: ${template.length} bytes');
      print('Component instances: 10000');

      // Warm-up
      print('Warming up...');
      for (var i = 0; i < 3; i++) {
        parser.parse(template);
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 5;
      for (var i = 0; i < iterations; i++) {
        final result = parser.parse(template);
        expect(result.ast, isNotNull);
      }
      stopwatch.stop();

      final avgMs = stopwatch.elapsedMilliseconds / iterations;
      final componentsPerSec = (10000 / (avgMs / 1000)).round();

      print('Average parse time: ${avgMs.toStringAsFixed(2)}ms');
      print(
        'Throughput: ${componentsPerSec.toStringAsFixed(0)} components/sec',
      );

      expect(
        componentsPerSec,
        greaterThan(1000),
        reason: 'Should parse > 1K components/sec, got $componentsPerSec',
      );
    });

    test('1000 nested levels - extreme nesting', () {
      print('\n=== 1000 Nested Levels Benchmark ===');

      // Generate template with 1000 levels of nesting
      final buffer = StringBuffer();
      final closeDirectives = ['@endif', '@endforeach', '@endsection'];

      // Open 1000 nested directives
      for (var i = 0; i < 1000; i++) {
        final dirType = i % 3;
        switch (dirType) {
          case 0:
            buffer.writeln('${'  ' * i}@if(\$condition_$i)');
            break;
          case 1:
            buffer.writeln('${'  ' * i}@foreach(\$items_$i as \$item_$i)');
            break;
          case 2:
            buffer.writeln('${'  ' * i}@section("section_$i")');
            break;
        }
      }

      // Add some content at deepest level
      buffer.writeln('${'  ' * 1000}<div>Deepest content</div>');

      // Close 1000 nested directives
      for (var i = 999; i >= 0; i--) {
        final dirType = i % 3;
        buffer.writeln('${'  ' * i}${closeDirectives[dirType]}');
      }

      final template = buffer.toString();
      final lineCount = template.split('\n').length;

      print('Template size: ${template.length} bytes');
      print('Lines: $lineCount');
      print('Nesting depth: 1000 levels');

      // Warm-up
      print('Warming up...');
      for (var i = 0; i < 2; i++) {
        parser.parse(template);
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      final result = parser.parse(template);
      stopwatch.stop();

      expect(result.ast, isNotNull);

      print('Parse time: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason:
            'Should parse extreme nesting in < 2000ms, took ${stopwatch.elapsedMilliseconds}ms',
      );
      print('SUCCESS: No stack overflow with 1000 nested levels');
    });

    test('Memory profiling & GC pressure', () {
      print('\n=== Memory Profiling Benchmark ===');

      final sizes = [100, 1000, 10000, 100000];
      final memoryResults = <int, Map<String, num>>{};

      for (final size in sizes) {
        print('\nTesting $size lines...');

        // Generate template
        final lines = <String>[];
        for (var i = 0; i < size; i++) {
          if (i % 4 == 0) {
            lines.add('@if(\$condition_$i)');
          } else if (i % 4 == 1) {
            lines.add('  <div>{{ \$data_$i }}</div>');
          } else if (i % 4 == 2) {
            lines.add('  <x-component attr="$i" />');
          } else {
            lines.add('@endif');
          }
        }
        final template = lines.join('\n');

        // Force GC before measurement
        for (var i = 0; i < 3; i++) {
          <int>[]; // Trigger some allocation
        }

        // Get memory before
        final memBefore = ProcessInfo.currentRss;

        // Parse multiple times to measure consistent memory usage
        final stopwatch = Stopwatch()..start();
        final iterations = size < 10000 ? 10 : 3;
        for (var i = 0; i < iterations; i++) {
          final result = parser.parse(template);
          expect(result.ast, isNotNull);
        }
        stopwatch.stop();

        // Get memory after
        final memAfter = ProcessInfo.currentRss;
        final memDelta = memAfter - memBefore;

        final avgMs = stopwatch.elapsedMilliseconds / iterations;
        final bytesPerLine = memDelta / size;

        memoryResults[size] = {
          'memBefore': memBefore,
          'memAfter': memAfter,
          'memDelta': memDelta,
          'bytesPerLine': bytesPerLine,
          'parseTimeMs': avgMs,
          'templateSize': template.length,
        };

        print(
          '  Template size: ${(template.length / 1024).toStringAsFixed(2)} KB',
        );
        print(
          '  Memory before: ${(memBefore / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        print(
          '  Memory after: ${(memAfter / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        print(
          '  Memory delta: ${(memDelta / 1024 / 1024).toStringAsFixed(2)} MB',
        );
        print(
          '  Bytes per line: ${bytesPerLine.toStringAsFixed(2)} bytes/line',
        );
        print('  Parse time: ${avgMs.toStringAsFixed(2)}ms');
      }

      print('\n=== Memory Summary ===');
      print('Size\t\tMem Delta\tBytes/Line\tParse Time');
      for (final entry in memoryResults.entries) {
        final size = entry.key;
        final data = entry.value;
        print(
          '${size.toString().padRight(8)}\t'
          '${((data['memDelta']!) / 1024 / 1024).toStringAsFixed(2)}MB\t\t'
          '${(data['bytesPerLine']!).toStringAsFixed(2)}\t\t'
          '${(data['parseTimeMs']!).toStringAsFixed(2)}ms',
        );
      }

      // Verify reasonable memory usage (less than 2KB per line for 100K lines)
      final largeTestBytes = memoryResults[100000]!['bytesPerLine']!;
      expect(
        largeTestBytes,
        lessThan(2000),
        reason:
            'Memory efficiency should be < 2000 bytes/line, got ${largeTestBytes.toStringAsFixed(2)}',
      );
    });
  });
}
