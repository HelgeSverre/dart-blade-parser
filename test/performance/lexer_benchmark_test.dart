import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'benchmark_formatter.dart';

void main() {
  group('Lexer Performance Benchmarks', () {
    test('Pure text tokenization throughput', () {
      // Generate 1,000,000 characters of plain text (no Blade syntax)
      final text = 'a' * 1000000;

      // Warm-up: Run 3 times to stabilize JIT compilation
      for (var i = 0; i < 3; i++) {
        BladeLexer(text).tokenize();
      }

      // Benchmark: Run 10 iterations for accurate measurement
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(text).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      final totalChars = text.length * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final charsPerSec = totalChars / seconds;

      BenchmarkFormatter.printResult(
        label: 'Pure text throughput',
        metric: BenchmarkFormatter.formatThroughput(charsPerSec, 'chars/sec'),
        context:
            'Total: ${totalChars / 1000000}M chars in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 1M chars/sec
      expect(
        charsPerSec,
        greaterThan(1000000),
        reason: 'Should process > 1M chars/sec for plain text',
      );
    });

    test('Directive-heavy template throughput', () {
      // Generate template with 10,000 directives
      final buffer = StringBuffer();
      for (var i = 0; i < 2500; i++) {
        buffer.writeln('@if(\$condition$i)');
        buffer.writeln('  Content $i');
        buffer.writeln('@foreach(\$items$i as \$item)');
        buffer.writeln('    {{ \$item }}');
        buffer.writeln('@endforeach');
        buffer.writeln('@endif');
      }
      final template = buffer.toString();

      // Count actual directives
      final directiveCount = '@if'.allMatches(template).length +
          '@foreach'.allMatches(template).length +
          '@endforeach'.allMatches(template).length +
          '@endif'.allMatches(template).length;

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(template).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      final totalDirectives = directiveCount * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final directivesPerSec = totalDirectives / seconds;

      BenchmarkFormatter.printResult(
        label: 'Directive-heavy throughput',
        metric: BenchmarkFormatter.formatThroughput(
            directivesPerSec, 'directives/sec'),
        context:
            'Total: $directiveCount directives processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 5K directives/sec
      // (Directive parsing involves expression parsing which is more complex)
      expect(
        directivesPerSec,
        greaterThan(5000),
        reason: 'Should process > 5K directives/sec',
      );
    });

    test('Complex attribute-heavy HTML throughput', () {
      // Generate HTML with 5,000 elements, each with 10 attributes
      final buffer = StringBuffer();
      for (var i = 0; i < 5000; i++) {
        buffer.write('<div ');
        buffer.write('class="item-$i" ');
        buffer.write('id="element-$i" ');
        buffer.write('data-index="$i" ');
        buffer.write('data-name="name$i" ');
        buffer.write('x-data="{count: $i}" ');
        buffer.write('@click="handleClick($i)" ');
        buffer.write(':class="active$i" ');
        buffer.write('wire:click="save($i)" ');
        buffer.write('wire:loading.class="opacity-50" ');
        buffer.write('disabled');
        buffer.writeln('>Content $i</div>');
      }
      final template = buffer.toString();

      const elementCount = 5000;

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(template).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      const totalElements = elementCount * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final elementsPerSec = totalElements / seconds;

      BenchmarkFormatter.printResult(
        label: 'Attribute-heavy HTML',
        metric:
            BenchmarkFormatter.formatThroughput(elementsPerSec, 'elements/sec'),
        context:
            'Total: $elementCount elements (10 attrs each) processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 5K elements/sec
      expect(
        elementsPerSec,
        greaterThan(5000),
        reason: 'Should process > 5K complex elements/sec',
      );
    });

    test('Escape sequence heavy template throughput', () {
      // Generate template with 10,000 @@ escapes
      final buffer = StringBuffer();
      for (var i = 0; i < 10000; i++) {
        buffer.write('Email: user$i@@example.com ');
      }
      final template = buffer.toString();

      final escapeCount = '@@'.allMatches(template).length;

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(template).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      final totalEscapes = escapeCount * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final escapesPerSec = totalEscapes / seconds;

      BenchmarkFormatter.printResult(
        label: 'Escape sequences',
        metric:
            BenchmarkFormatter.formatThroughput(escapesPerSec, 'escapes/sec'),
        context:
            'Total: $escapeCount escapes processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 20K escapes/sec
      expect(
        escapesPerSec,
        greaterThan(20000),
        reason: 'Should process > 20K escapes/sec (StringBuffer optimization)',
      );
    });

    test('Memory usage for large files - linear growth', () {
      // Parse progressively larger files: 10KB, 100KB, 1MB, 10MB
      final testSizes = [
        10 * 1024,
        100 * 1024,
        1 * 1024 * 1024,
        10 * 1024 * 1024,
      ];
      final memoryPerMB = <double>[];

      print('Memory usage analysis:');

      for (final size in testSizes) {
        // Generate template of specific size
        final charsNeeded = size;
        final template = 'x' * charsNeeded;

        // Parse the template
        final lexer = BladeLexer(template);
        final tokens = lexer.tokenize();

        // Estimate memory usage (rough approximation)
        // Each token has: type, value (string), line/column info (6 ints)
        // String overhead: ~2 bytes per char
        // Int: 8 bytes each
        final estimatedMemoryPerToken =
            tokens.fold<int>(0, (sum, token) => sum + token.value.length * 2) +
                (tokens.length * 6 * 8); // 6 ints per token

        final estimatedMemoryKB = estimatedMemoryPerToken / 1024;
        final inputSizeMB = size / (1024 * 1024);
        final memoryPerInputMB = estimatedMemoryKB / 1024 / inputSizeMB;

        memoryPerMB.add(memoryPerInputMB);

        print(
          '  ${(size / 1024).toStringAsFixed(0)}KB input: '
          '${tokens.length} tokens, '
          '~${estimatedMemoryKB.toStringAsFixed(1)}KB memory, '
          '~${memoryPerInputMB.toStringAsFixed(2)}MB per MB input',
        );
      }

      // Check for linear growth (ratio should be relatively stable)
      // Compare smallest to largest - should not grow exponentially
      final firstRatio = memoryPerMB[0];
      final lastRatio = memoryPerMB[memoryPerMB.length - 1];
      final growthFactor = lastRatio / firstRatio;

      print('Memory growth factor: ${growthFactor.toStringAsFixed(2)}x');

      // Growth should be close to linear (< 2x variation)
      expect(
        growthFactor,
        lessThan(2.0),
        reason: 'Memory usage should grow linearly, not exponentially',
      );
    });

    test('Mixed content realistic template benchmark', () {
      // Realistic template with mixed Blade/HTML/Alpine/Livewire
      final buffer = StringBuffer();
      for (var i = 0; i < 100; i++) {
        buffer.writeln('<div class="container-$i" x-data="{open: false}">');
        buffer.writeln('  @if(\$user->isActive($i))');
        buffer.writeln('    <div class="user-card">');
        buffer.writeln('      <h2>{{ \$user->name$i }}</h2>');
        buffer.writeln('      <p>Contact: user$i@@example.com</p>');
        buffer.writeln('      @foreach(\$user->posts$i as \$post)');
        buffer.writeln(
          '        <article class="post" wire:key="post-{{\$post->id}}">',
        );
        buffer.writeln('          <h3>{{\$post->title}}</h3>');
        buffer.writeln('          <button wire:click="like({{\$post->id}})" ');
        buffer.writeln('                  @click="toggle" ');
        buffer.writeln('                  :disabled="loading">Like</button>');
        buffer.writeln('        </article>');
        buffer.writeln('      @endforeach');
        buffer.writeln('    </div>');
        buffer.writeln('  @else');
        buffer.writeln('    <p>User $i is inactive</p>');
        buffer.writeln('  @endif');
        buffer.writeln('</div>');
        buffer.writeln('{{-- Comment for section $i --}}');
      }
      final template = buffer.toString();

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 20;
      for (var i = 0; i < iterations; i++) {
        final tokens = BladeLexer(template).tokenize();
        expect(tokens.isNotEmpty, isTrue);
      }
      stopwatch.stop();

      // Calculate throughput
      final totalChars = template.length * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final charsPerSec = totalChars / seconds;
      final mbPerSec = (charsPerSec / 1024 / 1024);

      BenchmarkFormatter.printResult(
        label: 'Mixed realistic content',
        metric: '${mbPerSec.toStringAsFixed(2)} MB/sec',
        context:
            'Template size: ${(template.length / 1024).toStringAsFixed(2)}KB, processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 1MB/sec
      expect(
        mbPerSec,
        greaterThan(1.0),
        reason: 'Should process > 1MB/sec for realistic mixed content',
      );
    });

    test('Echo statement with nested braces throughput', () {
      // Generate template with complex echo statements containing nested braces
      final buffer = StringBuffer();
      for (var i = 0; i < 1000; i++) {
        buffer.writeln("{{ \$array[$i]['key']['nested'] }}");
        buffer.writeln('{!! \$html[$i] !!}');
        buffer.writeln('{{{ \$legacy[$i] }}}');
      }
      final template = buffer.toString();

      final echoCount = '{{'.allMatches(template).length +
          '{!!'.allMatches(template).length +
          '{{{'.allMatches(template).length;

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(template).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      final totalEchos = echoCount * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final echosPerSec = totalEchos / seconds;

      BenchmarkFormatter.printResult(
        label: 'Echo statements',
        metric: BenchmarkFormatter.formatThroughput(echosPerSec, 'echos/sec'),
        context:
            'Total: $echoCount echo statements processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 5K echos/sec
      expect(
        echosPerSec,
        greaterThan(5000),
        reason: 'Should process > 5K echo statements/sec',
      );
    });

    test('Component tags with attributes throughput', () {
      // Generate template with component tags and attributes
      final buffer = StringBuffer();
      for (var i = 0; i < 1000; i++) {
        buffer.writeln('<x-alert type="success" :message="\$msg$i" />');
        buffer.writeln(
          '<x-button color="primary" size="large" @click="handler$i">',
        );
        buffer.writeln('  Click me $i');
        buffer.writeln('</x-button>');
        buffer.writeln('<x-card :title="\$title$i" wire:loading>');
        buffer.writeln('  <x-slot:header>Header $i</x-slot:header>');
        buffer.writeln('  Content $i');
        buffer.writeln('  <x-slot:footer>Footer $i</x-slot:footer>');
        buffer.writeln('</x-card>');
      }
      final template = buffer.toString();

      final componentCount = '<x-'.allMatches(template).length +
          '</x-'.allMatches(template).length;

      // Warm-up
      for (var i = 0; i < 3; i++) {
        BladeLexer(template).tokenize();
      }

      // Benchmark
      final stopwatch = Stopwatch()..start();
      const iterations = 10;
      for (var i = 0; i < iterations; i++) {
        BladeLexer(template).tokenize();
      }
      stopwatch.stop();

      // Calculate throughput
      final totalComponents = componentCount * iterations;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final componentsPerSec = totalComponents / seconds;

      BenchmarkFormatter.printResult(
        label: 'Component tags',
        metric: BenchmarkFormatter.formatThroughput(
            componentsPerSec, 'components/sec'),
        context:
            'Total: $componentCount component tags processed $iterations times in ${seconds.toStringAsFixed(3)}s',
      );

      // Assert reasonable performance: > 5K components/sec
      expect(
        componentsPerSec,
        greaterThan(5000),
        reason: 'Should process > 5K component tags/sec',
      );
    });
  });
}
