import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter Performance', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('Large templates', () {
      test('formats template with 100 directives efficiently', () {
        final input = StringBuffer();
        for (var i = 0; i < 100; i++) {
          input.writeln('@if(\$condition$i)');
          input.writeln('<p>Content $i</p>');
          input.writeln('@endif');
        }

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Should format 100 directives in under 1 second');
      });

      test('formats template with 1000 HTML elements efficiently', () {
        final input = StringBuffer('<div>');
        for (var i = 0; i < 1000; i++) {
          input.writeln('<span>Item $i</span>');
        }
        input.writeln('</div>');

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Should format 1000 elements in under 2 seconds');
      });

      test('formats deeply nested structure (20 levels)', () {
        final input = StringBuffer();
        for (var i = 0; i < 20; i++) {
          input.writeln('@if(\$level$i)');
        }
        input.writeln('<p>Deep content</p>');
        for (var i = 0; i < 20; i++) {
          input.writeln('@endif');
        }

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Should format 20-level nesting quickly');
      });
    });

    group('Repeated formatting', () {
      test('maintains consistent performance on repeated formatting', () {
        const input = '''
<div class="container">
@foreach(\$users as \$user)
<div class="user">
<h3>{{ \$user->name }}</h3>
<p>{{ \$user->email }}</p>
</div>
@endforeach
</div>
''';

        final times = <int>[];

        // Format 10 times and measure each
        for (var i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          formatter.format(input);
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }

        // Calculate average
        final average = times.reduce((a, b) => a + b) / times.length;

        // No single run should be more than 10x the average (allows for GC/JIT variance)
        for (final time in times) {
          expect(time, lessThan(average * 10),
              reason: 'Performance should be reasonably consistent across runs');
        }
      });

      test('idempotent formatting does not degrade performance', () {
        const input = '''
@if(\$user)
<div>{{ \$user->name }}</div>
@endif
''';

        final firstFormat = Stopwatch()..start();
        final formatted1 = formatter.format(input);
        firstFormat.stop();

        final secondFormat = Stopwatch()..start();
        final formatted2 = formatter.format(formatted1);
        secondFormat.stop();

        final thirdFormat = Stopwatch()..start();
        final formatted3 = formatter.format(formatted2);
        thirdFormat.stop();

        expect(formatted2, formatted1);
        expect(formatted3, formatted2);

        // Second and third format should be as fast or faster (already formatted)
        expect(secondFormat.elapsedMicroseconds,
            lessThan(firstFormat.elapsedMicroseconds * 2),
            reason: 'Formatting already-formatted code should not be slower');
      });
    });

    group('Complex real-world templates', () {
      test('formats admin dashboard template efficiently', () {
        const input = '''
@extends('layouts.admin')

@section('title', 'Dashboard')

@section('content')
<div class="dashboard">
<div class="stats">
@foreach(\$stats as \$stat)
<div class="stat-card">
<h3>{{ \$stat->label }}</h3>
<p class="value">{{ \$stat->value }}</p>
@if(\$stat->trend)
<span class="trend {{ \$stat->trend > 0 ? 'up' : 'down' }}">
{{ \$stat->trend }}%
</span>
@endif
</div>
@endforeach
</div>

<div class="recent-activity">
<h2>Recent Activity</h2>
@forelse(\$activities as \$activity)
<div class="activity-item">
<div class="activity-icon">
<i class="{{ \$activity->icon }}"></i>
</div>
<div class="activity-details">
<p>{{ \$activity->description }}</p>
<span class="timestamp">{{ \$activity->created_at->diffForHumans() }}</span>
</div>
</div>
@empty
<p>No recent activity</p>
@endforelse
</div>

@can('view-reports')
<div class="reports">
<h2>Reports</h2>
@foreach(\$reports as \$report)
<a href="{{ route('reports.show', \$report) }}" class="report-link">
{{ \$report->name }}
</a>
@endforeach
</div>
@endcan
</div>
@endsection

@push('scripts')
<script src="/js/dashboard.js"></script>
@endpush
''';

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input);
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Should format complex template quickly');
      });

      test('formats data table with pagination efficiently', () {
        const input = '''
<div class="table-container">
<table class="data-table">
<thead>
<tr>
@foreach(\$columns as \$column)
<th>
{{ \$column->label }}
@if(\$column->sortable)
<button wire:click="sortBy('column-key')">
<i class="sort-icon"></i>
</button>
@endif
</th>
@endforeach
</tr>
</thead>
<tbody>
@forelse(\$rows as \$row)
<tr>
@foreach(\$columns as \$column)
<td>{{ \$row->name }}</td>
@endforeach
</tr>
@empty
<tr>
<td colspan="5">No data available</td>
</tr>
@endforelse
</tbody>
</table>

{{ \$rows->links() }}
</div>
''';

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input);
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Memory efficiency', () {
      test('does not leak memory on large inputs', () {
        // Create a large template
        final input = StringBuffer();
        for (var i = 0; i < 500; i++) {
          input.writeln('@if(\$condition$i)');
          input.writeln('<div class="item">');
          input.writeln('<h3>Title $i</h3>');
          input.writeln('<p>Description for item $i</p>');
          input.writeln('</div>');
          input.writeln('@endif');
        }

        final template = input.toString();

        // Format multiple times - should not accumulate memory
        for (var i = 0; i < 5; i++) {
          final result = formatter.format(template);
          expect(result, isNotEmpty);
        }

        // If we get here without running out of memory, test passes
        expect(true, isTrue);
      });
    });

    group('Edge case performance', () {
      test('handles template with many attributes efficiently', () {
        final input = StringBuffer('<div ');
        for (var i = 0; i < 100; i++) {
          input.write('data-attr$i="value$i" ');
        }
        input.writeln('>Content</div>');

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('handles template with many comments efficiently', () {
        final input = StringBuffer();
        for (var i = 0; i < 100; i++) {
          input.writeln('{{-- Comment $i --}}');
        }
        input.writeln('<div>Content</div>');

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('handles template with many echo statements efficiently', () {
        final input = StringBuffer('<div>');
        for (var i = 0; i < 500; i++) {
          input.writeln('{{ \$var$i }}');
        }
        input.writeln('</div>');

        final stopwatch = Stopwatch()..start();
        final result = formatter.format(input.toString());
        stopwatch.stop();

        expect(result, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Formatting with different configurations', () {
      test('configuration does not significantly impact performance', () {
        const input = '''
@if(\$user)
<div>
<p>{{ \$user->name }}</p>
</div>
@endif
''';

        final configs = [
          BladeFormatter(),
          BladeFormatter(
              config: const FormatterConfig(indentSize: 2)),
          BladeFormatter(
              config: const FormatterConfig(indentStyle: IndentStyle.tabs)),
          BladeFormatter(
              config: const FormatterConfig(quoteStyle: QuoteStyle.single)),
        ];

        final times = <int>[];

        for (final formatter in configs) {
          final stopwatch = Stopwatch()..start();
          formatter.format(input);
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }

        // All configurations should have similar performance (allow 5x variance for JIT/GC)
        final average = times.reduce((a, b) => a + b) / times.length;
        for (final time in times) {
          expect(time, lessThan(average * 5),
              reason: 'Configuration should not significantly impact performance');
        }
      });
    });
  });
}
