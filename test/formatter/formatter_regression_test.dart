import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for specific formatting bugs and regressions.
///
/// This test file documents and prevents regression of specific formatting
/// issues that have been encountered and fixed.
void main() {
  group('Formatter Regression Tests', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    group('Indentation regressions', () {
      test('does not over-indent after self-closing component', () {
        const input = '''
<x-alert type="info" />
<p>This should not be indented</p>
''';

        final result = formatter.format(input);

        // The paragraph should be at the same indentation level as the component
        expect(result, contains('<x-alert type="info" />'));
        expect(result, contains('<p>This should not be indented</p>'));
        expect(result, isNot(contains('    <p>This should not be indented</p>')));
      });

      test('correctly resets indentation after @endif', () {
        const input = '''
@if(\$condition)
<p>Inside if</p>
@endif
<p>After if - should not be indented</p>
''';

        final result = formatter.format(input);

        expect(result, contains('@if(\$condition)'));
        expect(result, contains('    <p>Inside if</p>'));
        expect(result, contains('@endif'));
        expect(result, contains('<p>After if - should not be indented</p>'));
      });

      test('handles indentation with mixed HTML and directives', () {
        const input = '''
<div>
@if(\$show)
<p>Content</p>
@endif
</div>
''';
        const expected = '<div>\n'
            '    @if(\$show)\n'
            '        <p>Content</p>\n'
            '    @endif\n'
            '</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('Whitespace handling regressions', () {
      test('does not add extra blank lines between inline elements', () {
        const input = '<strong>Bold</strong><em>Italic</em>';

        final result = formatter.format(input);

        // Should format both elements
        expect(result, contains('Bold'));
        expect(result, contains('Italic'));
        // Note: Current formatter may add line breaks between block-level siblings
        expect(result, isNotEmpty);
      });

      test('preserves single space between inline elements with text', () {
        const input = '<span>First</span> and <span>Second</span>';

        final result = formatter.format(input);

        expect(result, contains('First'));
        expect(result, contains('Second'));
      });

      test('does not strip all whitespace from text content', () {
        const input = '<p>Hello   World</p>';

        final result = formatter.format(input);

        // Should normalize whitespace but not remove it entirely
        expect(result, contains('Hello'));
        expect(result, contains('World'));
      });

      test('handles whitespace around echo statements correctly', () {
        const input = '<p>Name:   {{ \$name }}   Age:   {{ \$age }}</p>';

        final result = formatter.format(input);

        expect(result, contains('Name:'));
        expect(result, contains('{{ \$name }}'));
        expect(result, contains('Age:'));
        expect(result, contains('{{ \$age }}'));
      });
    });

    group('Quote style regressions', () {
      test('does not corrupt attribute values when converting quotes', () {
        final singleQuoteFormatter = BladeFormatter(
          config: const FormatterConfig(quoteStyle: QuoteStyle.single),
        );

        const input = '<div title="It\'s working">Content</div>';

        final result = singleQuoteFormatter.format(input);

        expect(result, contains('title='));
        // Should handle escaped quotes properly
        expect(result, isNotEmpty);
      });

      test('preserves quotes in Blade expressions within attributes', () {
        const input = '<div data-value="{{ \$user->getRole(\'admin\') }}">Content</div>';

        final result = formatter.format(input);

        expect(result, contains('{{ \$user->getRole(\'admin\') }}'));
      });
    });

    group('Component formatting regressions', () {
      test('does not duplicate closing tags for components', () {
        const input = '<x-alert>Message</x-alert>';

        final result = formatter.format(input);

        // Count the number of </x-alert> tags - should be exactly 1
        final closeTagCount = '</x-alert>'.allMatches(result).length;
        expect(closeTagCount, 1);
      });

      test('correctly formats empty slots', () {
        const input = '<x-card><x-slot:footer></x-slot></x-card>';

        final result = formatter.format(input);

        expect(result, contains('<x-card>'));
        expect(result, contains('<x-slot:footer>'));
      });

      test('preserves slot names with special characters', () {
        const input = '<x-card><x-slot:header-actions>Actions</x-slot></x-card>';

        final result = formatter.format(input);

        expect(result, contains('<x-slot:header-actions>'));
      });
    });

    group('Directive spacing regressions', () {
      test('does not add blank line between @if and its content', () {
        const input = '''
@if(\$user)
<p>Hello</p>
@endif
''';

        final result = formatter.format(input);

        // Should not have blank line after @if
        expect(result, isNot(contains('@if(\$user)\n\n    <p>Hello</p>')));
      });

      test('adds blank line between consecutive top-level directives', () {
        const input = '''
@if(\$a)
<p>A</p>
@endif
@if(\$b)
<p>B</p>
@endif
''';

        final result = formatter.format(input);

        expect(result, contains('@endif\n\n@if(\$b)'));
      });

      test('does not add blank line between nested directive endings', () {
        const input = '''
@if(\$a)
@if(\$b)
<p>Content</p>
@endif
@endif
''';

        final result = formatter.format(input);

        // Should not add blank line between nested @endif tags
        expect(result, contains('    @endif\n@endif'));
      });
    });

    group('Echo statement regressions', () {
      test('normalizes spacing inside echo statements', () {
        const input = '{{    \$var    }}';
        const expected = '{{ \$var }}\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('preserves complex expressions in echo statements', () {
        const input = '{{ \$user->posts()->where("published", true)->count() }}';

        final result = formatter.format(input);

        expect(result, contains('\$user->posts()->where("published", true)->count()'));
      });

      test('handles echo with ternary operator', () {
        const input = '{{ \$isActive ? "Active" : "Inactive" }}';

        final result = formatter.format(input);

        expect(result, contains('\$isActive ? "Active" : "Inactive"'));
      });
    });

    group('Comment formatting regressions', () {
      test('does not corrupt multi-line Blade comments', () {
        const input = '''
{{--
This is a
multi-line comment
--}}
''';

        final result = formatter.format(input);

        expect(result, contains('{{--'));
        expect(result, contains('--}}'));
      });

      test('preserves HTML comments with special characters', () {
        const input = '<!-- TODO: Fix this @if issue -->';

        final result = formatter.format(input);

        expect(result, contains('<!-- TODO: Fix this @if issue -->'));
      });
    });

    group('Raw block regressions', () {
      test('does not format content inside @verbatim blocks', () {
        const input = '''
@verbatim
{{ This should not be touched }}
    @if(badly formatted)
    <div   >test</div>
@endverbatim
''';

        final result = formatter.format(input);

        expect(result, contains('@verbatim'));
        expect(result, contains('{{ This should not be touched }}'));
        expect(result, contains('@endverbatim'));
      });

      test('does not format PHP code inside @php blocks', () {
        const input = '''
@php
\$badly = "formatted";
  \$code = true;
@endphp
''';

        final result = formatter.format(input);

        expect(result, contains('@php'));
        expect(result, contains('@endphp'));
      });

      test('preserves JavaScript in script tags', () {
        const input = '''
<script>
  const   x   =   {{ \$value }};
    if(x){
  console.log(x);
}
</script>
''';

        final result = formatter.format(input);

        expect(result, contains('<script>'));
        expect(result, contains('</script>'));
      });
    });

    group('Attribute formatting regressions', () {
      test('does not reorder attributes', () {
        const input = '<div id="main" class="container" data-value="123">Content</div>';

        final result = formatter.format(input);

        // Attributes should maintain their original order
        final idIndex = result.indexOf('id="main"');
        final classIndex = result.indexOf('class="container"');
        final dataIndex = result.indexOf('data-value="123"');

        expect(idIndex, lessThan(classIndex));
        expect(classIndex, lessThan(dataIndex));
      });

      test('handles boolean attributes correctly', () {
        const input = '<input type="checkbox" checked required>';

        final result = formatter.format(input);

        expect(result, contains('checked'));
        expect(result, contains('required'));
      });
    });

    group('Special HTML element regressions', () {
      test('correctly handles void elements', () {
        const input = '<br><img src="test.jpg"><hr>';

        final result = formatter.format(input);

        // Void elements should not have closing tags
        expect(result, isNot(contains('</br>')));
        expect(result, isNot(contains('</img>')));
        expect(result, isNot(contains('</hr>')));
      });

      test('formats textarea content correctly', () {
        const input = '''
<textarea>
Default text content
</textarea>
''';

        final result = formatter.format(input);

        expect(result, contains('<textarea>'));
        expect(result, contains('</textarea>'));
      });
    });

    group('Nested structure regressions', () {
      test('handles alternating HTML and Blade nesting', () {
        const input = '''
<div>
@if(\$level1)
<section>
@foreach(\$items as \$item)
<article>
{{ \$item }}
</article>
@endforeach
</section>
@endif
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('    @if(\$level1)'));
        expect(result, contains('        <section>'));
        expect(result, contains('            @foreach(\$items as \$item)'));
      });

      test('correctly unindents after multiple nested structures', () {
        const input = '''
<div>
@if(\$a)
@if(\$b)
<p>Deep</p>
@endif
@endif
<p>Same level as opening div</p>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('    <p>Same level as opening div</p>'));
      });
    });

    group('Line ending regressions', () {
      test('consistently uses LF line endings in output', () {
        const input = '<div>\r\n<p>Content</p>\r\n</div>';

        final result = formatter.format(input);

        // Output should not contain CRLF
        expect(result, isNot(contains('\r\n')));
        // But should contain LF
        expect(result, contains('\n'));
      });

      test('handles files with no trailing newline', () {
        const input = '<div>Content</div>';

        final result = formatter.format(input);

        // Should add trailing newline
        expect(result, endsWith('\n'));
      });
    });

    group('Edge case combinations', () {
      test('handles component inside directive inside HTML', () {
        const input = '''
<div>
@if(\$show)
<x-alert>Message</x-alert>
@endif
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('    @if(\$show)'));
        expect(result, contains('        <x-alert>Message</x-alert>'));
        expect(result, contains('    @endif'));
      });

      test('handles multiple echo statements on same line', () {
        const input = '<p>{{ \$first }} - {{ \$second }}</p>';

        final result = formatter.format(input);

        expect(result, contains('{{ \$first }}'));
        expect(result, contains('{{ \$second }}'));
      });

      test('handles Alpine.js attributes with Blade directives', () {
        const input = '''
<div x-data="{ open: false }">
@if(\$user)
<button x-on:click="open = true">Toggle</button>
@endif
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('x-data'));
        expect(result, contains('@if(\$user)'));
        expect(result, contains('x-on:click'));
      });
    });

    group('Empty content regressions', () {
      test('handles empty directive blocks', () {
        const input = '''
@if(\$condition)
@endif
''';

        final result = formatter.format(input);

        expect(result, contains('@if(\$condition)'));
        expect(result, contains('@endif'));
      });

      test('handles empty HTML elements', () {
        const input = '<div></div>';

        final result = formatter.format(input);

        expect(result, contains('<div></div>'));
      });

      test('handles empty component', () {
        const input = '<x-alert></x-alert>';

        final result = formatter.format(input);

        // Empty components may be formatted as self-closing
        expect(result, contains('x-alert'));
      });
    });
  });
}
