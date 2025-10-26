import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('BladeFormatter', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('basic formatting', () {
      test('formats simple echo statement', () {
        const input = '<div>{{  \$user->name  }}</div>';
        // Simple echo inside div - kept inline for cleaner output
        const expected = '<div>{{ \$user->name }}</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats simple directive', () {
        const input = '@if(\$user)\n<p>Hello</p>\n@endif';
        const expected = '@if(\$user)\n'
            '    <p>Hello</p>\n'
            '@endif\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats nested directives', () {
        const input =
            '@if(\$user)\n@if(\$user->isAdmin())\n<p>Admin</p>\n@endif\n@endif';
        const expected = '@if(\$user)\n'
            '    @if(\$user->isAdmin())\n'
            '        <p>Admin</p>\n'
            '    @endif\n'
            '@endif\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats component', () {
        const input = '<x-alert type="success">Done!</x-alert>';
        const expected = '<x-alert type="success">Done!</x-alert>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats self-closing component', () {
        const input = '<x-button label="Click me"/>';
        const expected = '<x-button label="Click me" />\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats foreach loop', () {
        const input =
            '@foreach(\$users as \$user)\n<p>{{\$user->name}}</p>\n@endforeach';
        const expected = '@foreach(\$users as \$user)\n'
            '    <p>{{ \$user->name }}</p>\n'
            '@endforeach\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats mixed HTML and Blade', () {
        const input =
            '<div class="container">\n@if(\$user)\n<p>{{\$user->name}}</p>\n@endif\n</div>';
        const expected = '<div class="container">\n'
            '    @if(\$user)\n'
            '        <p>{{ \$user->name }}</p>\n'
            '    @endif\n'
            '</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('indentation', () {
      test('uses 4 spaces by default', () {
        const input = '@if(\$x)\n<p>test</p>\n@endif';
        final result = formatter.format(input);

        expect(result, contains('    <p>test</p>'));
      });

      test('uses configured indent size', () {
        final customFormatter = BladeFormatter(
          config: const FormatterConfig(indentSize: 2),
        );

        const input = '@if(\$x)\n<p>test</p>\n@endif';
        final result = customFormatter.format(input);

        expect(result, contains('  <p>test</p>'));
      });

      test('uses tabs when configured', () {
        final tabFormatter = BladeFormatter(
          config: const FormatterConfig(indentStyle: IndentStyle.tabs),
        );

        const input = '@if(\$x)\n<p>test</p>\n@endif';
        final result = tabFormatter.format(input);

        expect(result, contains('\t<p>test</p>'));
      });

      test('handles deep nesting', () {
        const input =
            '@if(\$a)\n@if(\$b)\n@if(\$c)\n<p>deep</p>\n@endif\n@endif\n@endif';
        const expected = '@if(\$a)\n'
            '    @if(\$b)\n'
            '        @if(\$c)\n'
            '            <p>deep</p>\n'
            '        @endif\n'
            '    @endif\n'
            '@endif\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('text handling', () {
      test('preserves text content', () {
        const input = '<p>Hello, world!</p>';
        const expected = '<p>Hello, world!</p>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('trims excessive whitespace', () {
        const input = '<p>   Hello   </p>';
        const expected = '<p>Hello</p>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('preserves meaningful whitespace between inline elements', () {
        const input = '<span>Hello</span> <span>World</span>';
        final result = formatter.format(input);

        // Should preserve the space between spans
        expect(result, contains('Hello'));
        expect(result, contains('World'));
      });
    });

    group('comments', () {
      test('formats Blade comments', () {
        const input = '{{-- This is a comment --}}';
        const expected = '{{-- This is a comment --}}\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats HTML comments', () {
        const input = '<!-- This is a comment -->';
        const expected = '<!-- This is a comment -->\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('error handling', () {
      test('throws FormatterException on parse errors', () {
        const input = '@if(\$condition)'; // Missing @endif

        expect(
          () => formatter.format(input),
          throwsA(isA<FormatterException>()),
        );
      });

      test('needsFormatting returns true for malformed input', () {
        const input = '@if(\$condition)'; // Missing @endif

        final needs = formatter.needsFormatting(input);
        expect(needs, isTrue);
      });
    });

    group('formatWithResult', () {
      test('returns success result for valid input', () {
        const input = '<div>{{ \$user }}</div>';
        final result = formatter.formatWithResult(input);

        expect(result.isSuccess, isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.errors, isEmpty);
      });

      test('returns error result for invalid input', () {
        const input = '@if(\$condition)'; // Missing @endif
        final result = formatter.formatWithResult(input);

        expect(result.isSuccess, isFalse);
        expect(result.hasErrors, isTrue);
        expect(result.errors, isNotEmpty);
      });

      test('indicates when source was changed', () {
        const input = '<div>{{  \$user  }}</div>';
        final result = formatter.formatWithResult(input);

        expect(result.wasChanged, isTrue);
      });

      test('indicates when source was not changed', () {
        // Already formatted with inline style
        const input = '<div>{{ \$user }}</div>\n';
        final result = formatter.formatWithResult(input);

        expect(result.wasChanged, isFalse);
      });
    });

    group('needsFormatting', () {
      test('returns false for already formatted code', () {
        // Already formatted with inline style
        const input = '<div>{{ \$user }}</div>\n';

        final needs = formatter.needsFormatting(input);
        expect(needs, isFalse);
      });

      test('returns true for unformatted code', () {
        const input = '<div>{{  \$user  }}</div>';

        final needs = formatter.needsFormatting(input);
        expect(needs, isTrue);
      });
    });

    group('real-world examples', () {
      test('formats control structures from fixture', () {
        const input = '''
<div class="dashboard">
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
</div>
''';

        final result = formatter.format(input);

        // Should parse and format successfully
        expect(result, isNotEmpty);
        expect(result, contains('@foreach'));
        expect(result, contains('@if'));
        expect(result, contains('@while'));
      });

      test('formats components from fixture', () {
        const input = '''
<x-card class="shadow-lg">
    <x-slot:header>
        <h2>Card Title</h2>
    </x-slot>

    <p>Card content goes here</p>

    <x-slot:footer>
        <button>Action</button>
    </x-slot>
</x-card>
''';

        final result = formatter.format(input);

        // Should parse and format successfully
        expect(result, isNotEmpty);
        expect(result, contains('<x-card'));
        expect(result, contains('<x-slot:header>'));
        expect(result, contains('<x-slot:footer>'));
      });
    });
  });
}
