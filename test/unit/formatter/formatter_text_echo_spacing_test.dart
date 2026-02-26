import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/formatter_visitor.dart';

/// Regression tests for text+echo spacing.
/// Fixes: extra spaces or lost spaces between text and {{ echo }} expressions.
void main() {
  group('Formatter text+echo spacing', () {
    late BladeParser parser;
    late FormatterVisitor formatter;

    setUp(() {
      parser = BladeParser();
      formatter = FormatterVisitor(FormatterConfig());
    });

    String format(String input) {
      final result = parser.parse(input);
      return formatter.format(result.ast!);
    }

    void expectIdempotent(String input, {String? reason}) {
      final first = format(input);
      final second = format(first);
      expect(first, equals(second),
          reason: reason ?? 'Formatting should be idempotent');
    }

    // ── Inline elements (simple text+echo kept on one line) ──

    group('inline elements preserve spacing', () {
      test('text before echo', () {
        final output = format('<p>Name: {{ \$name }}</p>');
        expect(output, contains('Name: {{ \$name }}'));
        expectIdempotent('<p>Name: {{ \$name }}</p>');
      });

      test('echo before text', () {
        final output = format('<span>{{ \$count }} items</span>');
        expect(output, contains('{{ \$count }} items'));
        expectIdempotent('<span>{{ \$count }} items</span>');
      });

      test('text-echo-text', () {
        final output =
            format('<p>Hello {{ \$name }}, welcome!</p>');
        expect(output, contains('Hello {{ \$name }}, welcome!'));
        expectIdempotent('<p>Hello {{ \$name }}, welcome!</p>');
      });

      test('text-echo-text-echo-text', () {
        final output = format(
            '<p>Hello {{ \$name }}, you have {{ \$count }} messages</p>');
        expect(output, contains('Hello {{ \$name }}, you have {{ \$count }} messages'));
        expectIdempotent(
            '<p>Hello {{ \$name }}, you have {{ \$count }} messages</p>');
      });

      test('no space between text and echo', () {
        final output = format('<p>Total:{{ \$count }}</p>');
        expect(output, contains('Total:{{ \$count }}'));
        expectIdempotent('<p>Total:{{ \$count }}</p>');
      });

      test('echo-echo with no space', () {
        final output = format('<div>{{ \$a }}{{ \$b }}</div>');
        expect(output, contains('{{ \$a }}{{ \$b }}'));
        expectIdempotent('<div>{{ \$a }}{{ \$b }}</div>');
      });

      test('echo-echo with single space', () {
        final output = format('<div>{{ \$a }} {{ \$b }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }}'));
        expectIdempotent('<div>{{ \$a }} {{ \$b }}</div>');
      });

      test('echo-echo with multiple spaces collapses to single', () {
        final output = format('<div>{{ \$a }}     {{ \$b }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }}'));
        expect(output, isNot(contains('}}     {{')));
        expectIdempotent('<div>{{ \$a }}     {{ \$b }}</div>');
      });

      test('echo-echo with tab between', () {
        final output = format('<div>{{ \$a }}\t{{ \$b }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }}'));
        expectIdempotent('<div>{{ \$a }}\t{{ \$b }}</div>');
      });

      test('echo-echo with mixed whitespace', () {
        final output = format('<div>{{ \$a }}  \t  {{ \$b }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }}'));
        expectIdempotent('<div>{{ \$a }}  \t  {{ \$b }}</div>');
      });

      test('three echos with spaces between each', () {
        final output =
            format('<div>{{ \$a }} {{ \$b }} {{ \$c }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }} {{ \$c }}'));
        expectIdempotent('<div>{{ \$a }} {{ \$b }} {{ \$c }}</div>');
      });

      test('three echos with no spaces', () {
        final output =
            format('<div>{{ \$a }}{{ \$b }}{{ \$c }}</div>');
        expect(output, contains('{{ \$a }}{{ \$b }}{{ \$c }}'));
        expectIdempotent('<div>{{ \$a }}{{ \$b }}{{ \$c }}</div>');
      });

      test('three echos mixed: space then no space', () {
        final output =
            format('<div>{{ \$a }} {{ \$b }}{{ \$c }}</div>');
        expect(output, contains('{{ \$a }} {{ \$b }}{{ \$c }}'));
        expectIdempotent('<div>{{ \$a }} {{ \$b }}{{ \$c }}</div>');
      });

      test('text-echo-space-echo-text', () {
        final output =
            format('<span>Total: {{ \$a }} + {{ \$b }} items</span>');
        expect(output, contains('Total: {{ \$a }} + {{ \$b }} items'));
        expectIdempotent(
            '<span>Total: {{ \$a }} + {{ \$b }} items</span>');
      });

      test('raw echo with space before regular echo', () {
        final output =
            format('<div>{!! \$html !!} {{ \$label }}</div>');
        expect(output, contains('{!! \$html !!} {{ \$label }}'));
        expectIdempotent('<div>{!! \$html !!} {{ \$label }}</div>');
      });

      test('echo surrounded by text with spaces', () {
        final output = format('<p>A {{ \$x }} B</p>');
        expect(output, contains('A {{ \$x }} B'));
        expectIdempotent('<p>A {{ \$x }} B</p>');
      });

      test('leading whitespace before first echo is trimmed', () {
        final output = format('<div>   {{ \$a }}</div>');
        expect(output, contains('>{{ \$a }}<'));
        expectIdempotent('<div>   {{ \$a }}</div>');
      });

      test('trailing whitespace after last echo is trimmed', () {
        final output = format('<div>{{ \$a }}   </div>');
        expect(output, contains('>{{ \$a }}<'));
        expectIdempotent('<div>{{ \$a }}   </div>');
      });

      test('leading and trailing whitespace trimmed, inner preserved', () {
        final output =
            format('<div>  {{ \$a }} {{ \$b }}  </div>');
        expect(output, contains('>{{ \$a }} {{ \$b }}<'));
        expectIdempotent('<div>  {{ \$a }} {{ \$b }}  </div>');
      });
    });

    // ── Block elements (text+echo each on own indented line) ──

    group('block elements preserve spacing', () {
      test('text before echo in block div', () {
        final input = '<div>\n    Name: {{ \$name }}\n</div>';
        final output = format(input);
        expect(output, contains('Name: {{ \$name }}'));
        expect(output, isNot(contains('Name:    {{')),
            reason: 'No double-indentation between text and echo');
        expect(output, isNot(contains('Name:{{')),
            reason: 'Space between text and echo must be preserved');
        expectIdempotent(input);
      });

      test('text before raw echo in block div', () {
        final input = '<div>\n    HTML: {!! \$html !!}\n</div>';
        final output = format(input);
        expect(output, contains('HTML: {!! \$html !!}'));
        expect(output, isNot(contains('HTML:    {!!')));
        expectIdempotent(input);
      });

      test('no space between text and echo in block div', () {
        final input = '<div>\n    Total:{{ \$count }}\n</div>';
        final output = format(input);
        expect(output, contains('Total:{{ \$count }}'));
        expectIdempotent(input);
      });

      test('colon patterns common in Laravel', () {
        for (final pattern in [
          'Email: {{ \$user->email }}',
          'Status: {{ \$order->status }}',
          'Created: {{ \$created_at }}',
          'Tags: {{ implode(", ", \$tags) }}',
        ]) {
          final input = '<div>\n    $pattern\n</div>';
          final output = format(input);
          expect(output, contains(pattern),
              reason: 'Pattern "$pattern" should be preserved');
          expectIdempotent(input, reason: 'Pattern "$pattern" should be idempotent');
        }
      });

      test('special characters before echo', () {
        final input = '<div>\n    Price (\$): {{ \$price }}\n</div>';
        final output = format(input);
        expect(output, contains('Price (\$): {{ \$price }}'));
        expectIdempotent(input);
      });

      test('equals sign before echo', () {
        final input = '<div>\n    Result = {{ \$result }}\n</div>';
        final output = format(input);
        expect(output, contains('Result = {{ \$result }}'));
        expectIdempotent(input);
      });
    });

    // ── GC-Mark regression: @class with conditional arrays ──

    group('@class regression (GC-Mark)', () {
      test('text+echo after multiline @class', () {
        final input = r'''<div
    @class([
        'tw-items-center tw-border',
        'tw-bg-red-50' => $isClosingSoon,
        'tw-bg-gray-200' => ! $isClosingSoon,
    ])
>
    Deadline: {{ $opportunity->human_closing_date }}
</div>''';
        final output = format(input);
        expect(output, contains('Deadline: {{ \$opportunity->human_closing_date }}'));
        expect(output, isNot(contains('Deadline:    {{')));
        expectIdempotent(input);
      });

      test('@class array does not grow indentation across passes', () {
        final input = r'''<div
    @class([
        'card',
        'card-active' => $isActive,
    ])
>
    Title: {{ $title }}
</div>''';
        // Format 5 times and ensure stability
        var current = input;
        for (var i = 0; i < 5; i++) {
          current = format(current);
        }
        final finalOutput = current;
        // One more pass should produce identical output
        expect(format(finalOutput), equals(finalOutput),
            reason: '@class array indentation must not grow across passes');
      });
    });

    // ── Directive contexts ──

    group('directive contexts preserve spacing', () {
      test('text+echo inside @if', () {
        final input =
            '<div>\n    @if(\$show)\n        Label: {{ \$label }}\n    @endif\n</div>';
        final output = format(input);
        expect(output, contains('Label: {{ \$label }}'));
        expectIdempotent(input);
      });

      test('text+echo inside @auth', () {
        final input = '@auth\n    Welcome: {{ \$user->name }}\n@endauth';
        final output = format(input);
        expect(output, contains('Welcome: {{ \$user->name }}'));
        expectIdempotent(input);
      });

      test('text+echo inside @isset', () {
        final input =
            '@isset(\$notification)\n    Alert: {{ \$notification->message }}\n@endisset';
        final output = format(input);
        expect(output, contains('Alert: {{ \$notification->message }}'));
        expectIdempotent(input);
      });

      test('text+echo inside @section', () {
        final input =
            '@section("sidebar")\n    Navigation: {{ \$currentPage }}\n@endsection';
        final output = format(input);
        expect(output, contains('Navigation: {{ \$currentPage }}'));
        expectIdempotent(input);
      });

      test('text+echo inside @foreach', () {
        final input =
            '@foreach(\$products as \$product)\n    <div>\n        Name: {{ \$product->name }}\n    </div>\n@endforeach';
        final output = format(input);
        expect(output, contains('Name: {{ \$product->name }}'));
        expectIdempotent(input);
      });
    });

    // ── Component contexts ──

    group('component contexts preserve spacing', () {
      test('text+echo inside x-card', () {
        final input = '<x-card>\n    Title: {{ \$title }}\n</x-card>';
        final output = format(input);
        expect(output, contains('Title: {{ \$title }}'));
        expectIdempotent(input);
      });

      test('text+echo inside x-alert', () {
        final input =
            '<x-alert type="warning">\n    Warning: {{ \$message }}\n</x-alert>';
        final output = format(input);
        expect(output, contains('Warning: {{ \$message }}'));
        expectIdempotent(input);
      });
    });

    // ── Mixed directives and echo ──

    group('mixed directives and echo', () {
      test('inline directives between text+echo lines', () {
        final input =
            '<div>\n    @csrf\n    Name: {{ \$name }}\n    @method("PUT")\n    Updated: {{ \$updated_at }}\n</div>';
        final output = format(input);
        expect(output, contains('Name: {{ \$name }}'));
        expect(output, contains('Updated: {{ \$updated_at }}'));
        expectIdempotent(input);
      });
    });

    // ── Multiline text ending with echo ──

    group('multiline text with echo', () {
      test('paragraph ending with echo', () {
        final input =
            '<div>\n    This is a longer paragraph of text\n    and ends with a value: {{ \$value }}\n</div>';
        final output = format(input);
        expect(output, contains('value: {{ \$value }}'));
        expectIdempotent(input);
      });
    });
  });
}
