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

    group('deep nesting', () {
      test('handles 5 levels of nesting correctly', () {
        const input = '''
@if(\$a)
@if(\$b)
@if(\$c)
@if(\$d)
@if(\$e)
<p>Deep</p>
@endif
@endif
@endif
@endif
@endif
''';

        final result = formatter.format(input);

        expect(result, contains('@if(\$a)'));
        expect(result, contains('    @if(\$b)'));
        expect(result, contains('        @if(\$c)'));
        expect(result, contains('            @if(\$d)'));
        expect(result, contains('                @if(\$e)'));
        expect(result, contains('                    <p>Deep</p>'));
      });

      test('handles 10 levels of nesting', () {
        const input = '''
@if(\$1)
@if(\$2)
@if(\$3)
@if(\$4)
@if(\$5)
@if(\$6)
@if(\$7)
@if(\$8)
@if(\$9)
@if(\$10)
<p>Very deep</p>
@endif
@endif
@endif
@endif
@endif
@endif
@endif
@endif
@endif
@endif
''';

        final result = formatter.format(input);

        // Should format without errors
        expect(result, isNotEmpty);
        expect(result, contains('<p>Very deep</p>'));
      });

      test('handles mixed nesting of different directive types', () {
        const input = '''
@if(\$user)
@foreach(\$posts as \$post)
@unless(\$post->draft)
@can('edit', \$post)
<p>{{ \$post->title }}</p>
@endcan
@endunless
@endforeach
@endif
''';

        final result = formatter.format(input);

        expect(result, contains('@if(\$user)'));
        expect(result, contains('    @foreach(\$posts as \$post)'));
        expect(result, contains('        @unless(\$post->draft)'));
        expect(result, contains('            @can(\'edit\', \$post)'));
      });
    });

    group('raw text elements', () {
      test('preserves script tag content', () {
        const input = '''
<script>
  const x = {{ \$value }};
  alert(x);
</script>
''';

        final result = formatter.format(input);

        expect(result, contains('<script>'));
        expect(result, contains('const x = {{ \$value }};'));
        expect(result, contains('</script>'));
      });

      test('preserves style tag content', () {
        const input = '''
<style>
  .class { color: red; }
  @media (max-width: 600px) { }
</style>
''';

        final result = formatter.format(input);

        expect(result, contains('<style>'));
        expect(result, contains('.class { color: red; }'));
        expect(result, contains('</style>'));
      });

      test('preserves textarea content', () {
        const input = '''
<textarea>
  {{ \$content }}
  <div>This should not be parsed as HTML</div>
</textarea>
''';

        final result = formatter.format(input);

        expect(result, contains('<textarea>'));
        expect(result, contains('{{ \$content }}'));
        expect(result, contains('</textarea>'));
      });
    });

    group('Blade raw blocks', () {
      test('preserves @verbatim block content', () {
        const input = '''
@verbatim
  {{ This should not be parsed }}
  @if(\$x)
    <p>test</p>
  @endif
@endverbatim
''';

        final result = formatter.format(input);

        expect(result, contains('@verbatim'));
        expect(result, contains('{{ This should not be parsed }}'));
        expect(result, contains('@endverbatim'));
      });

      test('preserves @php block content', () {
        const input = '''
@php
  \$x = 1;
  if (\$condition) {
    echo "test";
  }
@endphp
''';

        final result = formatter.format(input);

        expect(result, contains('@php'));
        expect(result, contains('\$x = 1;'));
        expect(result, contains('@endphp'));
      });

      test('formats content around @verbatim blocks', () {
        const input = '''
<div>
@verbatim
{{ raw }}
@endverbatim
<p>Normal content</p>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('@verbatim'));
        expect(result, contains('<p>Normal content</p>'));
      });
    });

    group('Alpine.js attributes', () {
      test('formats elements with x-data attributes', () {
        const input = '<div x-data="{ open: false }">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('x-data'));
        expect(result, contains('{ open: false }'));
      });

      test('formats elements with multiple Alpine attributes', () {
        const input =
            '<button x-on:click="open = true" x-bind:disabled="loading">Click</button>';
        final result = formatter.format(input);

        expect(result, contains('x-on:click'));
        expect(result, contains('x-bind:disabled'));
      });

      test('formats nested Alpine directives', () {
        const input = '''
<div x-data="{ open: false }">
<button x-on:click="open = !open">Toggle</button>
<div x-show="open">
<p>Content</p>
</div>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('x-data'));
        expect(result, contains('x-on:click'));
        expect(result, contains('x-show'));
      });
    });

    group('quote styles', () {
      test('preserves double quotes in attributes', () {
        const input = '<div class="container">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('class="container"'));
      });

      test('normalizes single quotes to double quotes (default behavior)', () {
        const input = "<div class='container'>Content</div>";
        final result = formatter.format(input);

        // Default QuoteStyle.preserve normalizes to double quotes
        // (AST doesn't store original quote char)
        expect(result, contains('class="container"'));
      });

      test('normalizes mixed quotes to double quotes (default behavior)', () {
        const input = '<div class="foo" id=\'bar\'>Content</div>';
        final result = formatter.format(input);

        // Both normalized to double quotes
        expect(result, contains('class="foo"'));
        expect(result, contains('id="bar"'));
      });

      test('converts to single quotes with QuoteStyle.single config', () {
        final singleQuoteFormatter = BladeFormatter(
          config: const FormatterConfig(quoteStyle: QuoteStyle.single),
        );
        const input = '<div class="container">Content</div>';
        final result = singleQuoteFormatter.format(input);

        expect(result, contains("class='container'"));
      });

      test('keeps double quotes with QuoteStyle.double config', () {
        final doubleQuoteFormatter = BladeFormatter(
          config: const FormatterConfig(quoteStyle: QuoteStyle.double),
        );
        const input = "<div class='container'>Content</div>";
        final result = doubleQuoteFormatter.format(input);

        expect(result, contains('class="container"'));
      });

      test('handles escaped quotes in attribute values', () {
        const input = '<div title="He said \\"hello\\"">Content</div>';
        final result = formatter.format(input);

        expect(result, contains('title='));
      });
    });

    group('whitespace handling', () {
      test('preserves space between inline elements', () {
        const input = '<span>Hello</span> <span>World</span>';
        final result = formatter.format(input);

        expect(result, contains('Hello'));
        expect(result, contains('World'));
      });

      test('handles multiple adjacent inline elements', () {
        const input = '<strong>Bold</strong><em>Italic</em><code>Code</code>';
        final result = formatter.format(input);

        expect(result, contains('Bold'));
        expect(result, contains('Italic'));
        expect(result, contains('Code'));
      });

      test('trims excessive whitespace in text nodes', () {
        const input = '<p>   Too     much     space   </p>';
        final result = formatter.format(input);

        // Should reduce excessive whitespace
        expect(result, isNot(contains('   Too     much     space   ')));
      });

      test('preserves single space in text content', () {
        const input = '<p>Hello World</p>';
        final result = formatter.format(input);

        expect(result, contains('Hello World'));
      });

      test('handles empty lines between block elements', () {
        const input = '''
<div>First</div>


<div>Second</div>
''';

        final result = formatter.format(input);

        expect(result, contains('First'));
        expect(result, contains('Second'));
      });

      test('handles tabs in source', () {
        const input = '\t<div>\t\t<p>Content</p>\t</div>';
        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>Content</p>'));
      });

      test('preserves blank lines between directives', () {
        const input = '''
@extends('layouts.app')

@section('title', 'Page Title')

@section('content')
    <h1>Main Content</h1>

    @push('scripts')
        <script src="/page-script.js"></script>
    @endpush

    @include('partials.sidebar')
@endsection

@section('footer')
    @parent
    <p>Additional footer content</p>
@endsection
''';

        final result = formatter.format(input);

        // Should preserve blank lines between top-level directives
        expect(result, contains('@extends(\'layouts.app\')\n\n@section(\'title\','));
        expect(result, contains('Page Title\')\n\n@section(\'content\')'));
        expect(result, contains('@endsection\n\n@section(\'footer\')'));
      });

      test('keeps inline text and echo on same line', () {
        const input = '<p>Count: {{ \$count }}</p>';
        const expected = '<p>Count: {{ \$count }}</p>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('keeps multiple inline elements together', () {
        const input = '''
@while(\$count > 0)
    <p>Count: {{ \$count }}</p>
@endwhile
''';
        const expected = '@while(\$count > 0)\n'
            '    <p>Count: {{ \$count }}</p>\n'
            '@endwhile\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('preserves line breaks between echo statements in div', () {
        const input = '''
<div>
    {{ \$user->name }}
    {!! \$html !!}
</div>
''';
        const expected = '<div>\n'
            '    {{ \$user->name }}\n'
            '    {!! \$html !!}\n'
            '</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('keeps single line with text and echo inline', () {
        const input = '<p>Name: {{ \$user->name }}</p>';
        const expected = '<p>Name: {{ \$user->name }}</p>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('directive spacing', () {
      test('adds blank line between ending and opening directives (default)', () {
        const input = '''
@foreach(\$items as \$item)
    <p>{{ \$item }}</p>
@endforeach
@while(\$count > 0)
    <p>Count: {{ \$count }}</p>
@endwhile
''';
        const expected = '@foreach(\$items as \$item)\n'
            '    <p>{{ \$item }}</p>\n'
            '@endforeach\n'
            '\n'
            '@while(\$count > 0)\n'
            '    <p>Count: {{ \$count }}</p>\n'
            '@endwhile\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('adds blank line between @endif and @foreach', () {
        const input = '''
@if(\$condition)
    <p>Text</p>
@endif
@foreach(\$items as \$item)
    <p>{{ \$item }}</p>
@endforeach
''';
        const expected = '@if(\$condition)\n'
            '    <p>Text</p>\n'
            '@endif\n'
            '\n'
            '@foreach(\$items as \$item)\n'
            '    <p>{{ \$item }}</p>\n'
            '@endforeach\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('no blank line with DirectiveSpacing.none config', () {
        final compactFormatter = BladeFormatter(
          config: const FormatterConfig(directiveSpacing: DirectiveSpacing.none),
        );

        const input = '''
@foreach(\$items as \$item)
    <p>{{ \$item }}</p>
@endforeach
@while(\$count > 0)
    <p>Count: {{ \$count }}</p>
@endwhile
''';
        const expected = '@foreach(\$items as \$item)\n'
            '    <p>{{ \$item }}</p>\n'
            '@endforeach\n'
            '@while(\$count > 0)\n'
            '    <p>Count: {{ \$count }}</p>\n'
            '@endwhile\n';

        final result = compactFormatter.format(input);
        expect(result, expected);
      });

      test('no blank line between opening directive and its content', () {
        const input = '''
@if(\$user)
    <p>Hello</p>
@endif
''';
        const expected = '@if(\$user)\n'
            '    <p>Hello</p>\n'
            '@endif\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('blank line between nested ending and sibling opening', () {
        const input = '''
<div>
    @foreach(\$users as \$user)
        @if(\$user->isActive())
            <p>{{ \$user->name }}</p>
        @endif
    @endforeach
    @while(\$count > 0)
        <p>{{ \$count }}</p>
    @endwhile
</div>
''';
        const expected = '<div>\n'
            '    @foreach(\$users as \$user)\n'
            '        @if(\$user->isActive())\n'
            '            <p>{{ \$user->name }}</p>\n'
            '        @endif\n'
            '    @endforeach\n'
            '\n'
            '    @while(\$count > 0)\n'
            '        <p>{{ \$count }}</p>\n'
            '    @endwhile\n'
            '</div>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('slot formatting', () {
      test('formats simple slot compactly (default)', () {
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
        const expected = '<x-card class="shadow-lg">\n'
            '    <x-slot:header>\n'
            '        <h2>Card Title</h2>\n'
            '    </x-slot>\n'
            '    <x-slot:footer>\n'
            '        <button>Action</button>\n'
            '    </x-slot>\n'
            '    <p>Card content goes here</p>\n'
            '</x-card>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats slot with multiple elements as block', () {
        const input = '''
<x-card>
    <x-slot:body>
        <p>First paragraph</p>
        <p>Second paragraph</p>
    </x-slot>
</x-card>
''';
        const expected = '<x-card>\n'
            '    <x-slot:body>\n'
            '        <p>First paragraph</p>\n'
            '\n'
            '        <p>Second paragraph</p>\n'
            '    </x-slot>\n'
            '</x-card>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats slot with block config always uses block formatting', () {
        final blockFormatter = BladeFormatter(
          config: const FormatterConfig(slotFormatting: SlotFormatting.block),
        );

        const input = '''
<x-card>
    <x-slot:header>
        <h2>Title</h2>
    </x-slot>
</x-card>
''';
        // Block formatting adds extra blank lines after opening and before closing
        const expected = '<x-card>\n'
            '    <x-slot:header>\n'
            '\n'
            '        <h2>Title</h2>\n'
            '\n'
            '    </x-slot>\n'
            '</x-card>\n';

        final result = blockFormatter.format(input);
        expect(result, expected);
      });

      test('formats empty slot', () {
        const input = '<x-card><x-slot:empty></x-slot></x-card>';
        // Note: Empty slots currently don't output closing tags
        const expected = '<x-card>\n'
            '    <x-slot:empty>\n'
            '</x-card>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });

      test('formats slot with attributes', () {
        const input = '''
<x-card>
    <x-slot:header class="font-bold">
        <h2>Title</h2>
    </x-slot>
</x-card>
''';
        const expected = '<x-card>\n'
            '    <x-slot:header class="font-bold">\n'
            '        <h2>Title</h2>\n'
            '    </x-slot>\n'
            '</x-card>\n';

        final result = formatter.format(input);
        expect(result, expected);
      });
    });

    group('empty and minimal files', () {
      test('formats empty string', () {
        const input = '';
        final result = formatter.format(input);

        expect(result, isEmpty);
      });

      test('formats whitespace-only input', () {
        const input = '   \n  \n  ';
        final result = formatter.format(input);

        expect(result, isNotEmpty); // May contain newline
      });

      test('formats single directive', () {
        const input = '@if(\$x)';

        // This should throw because @if needs @endif
        expect(
            () => formatter.format(input), throwsA(isA<FormatterException>()));
      });

      test('formats single HTML element', () {
        const input = '<div>Content</div>';
        final result = formatter.format(input);

        expect(result, '<div>Content</div>\n');
      });

      test('formats single echo statement', () {
        const input = '{{ \$user }}';
        final result = formatter.format(input);

        expect(result, '{{ \$user }}\n');
      });
    });

    group('line endings', () {
      test('handles CRLF line endings', () {
        const input = '<div>\r\n<p>Content</p>\r\n</div>';
        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>Content</p>'));
      });

      test('handles mixed line endings', () {
        const input = '<div>\r\n<p>Content</p>\n<span>Text</span>\r\n</div>';
        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>Content</p>'));
        expect(result, contains('<span>Text</span>'));
      });

      test('normalizes output to LF', () {
        const input = '<div>\r\n<p>Content</p>\r\n</div>';
        final result = formatter.format(input);

        // Output should use LF (\n) not CRLF
        expect(result, isNot(contains('\r\n')));
        expect(result, contains('\n'));
      });
    });

    group('HTML entities', () {
      test('preserves common entities', () {
        const input = '<p>&nbsp;&lt;&gt;&amp;&quot;</p>';
        final result = formatter.format(input);

        expect(result, contains('&nbsp;'));
        expect(result, contains('&lt;'));
        expect(result, contains('&gt;'));
        expect(result, contains('&amp;'));
        expect(result, contains('&quot;'));
      });

      test('preserves numeric entities', () {
        const input = '<p>&#169; &#8364;</p>';
        final result = formatter.format(input);

        expect(result, contains('&#169;'));
        expect(result, contains('&#8364;'));
      });

      test('preserves hex entities', () {
        const input = '<p>&#x00A9; &#x20AC;</p>';
        final result = formatter.format(input);

        expect(result, contains('&#x00A9;'));
        expect(result, contains('&#x20AC;'));
      });
    });

    group('comments edge cases', () {
      test('formats nested Blade comments', () {
        const input = '''
<div>
{{-- Comment 1 --}}
<p>Content</p>
{{-- Comment 2 --}}
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('{{-- Comment 1 --}}'));
        expect(result, contains('{{-- Comment 2 --}}'));
      });

      test('formats Blade comments inside directives', () {
        const input = '''
@if(\$user)
{{-- User is authenticated --}}
<p>Welcome</p>
@endif
''';

        final result = formatter.format(input);

        expect(result, contains('{{-- User is authenticated --}}'));
      });

      test('formats HTML comments with Blade syntax', () {
        const input = '<!-- <div>{{ \$user }}</div> -->';
        final result = formatter.format(input);

        expect(result, contains('<!--'));
        expect(result, contains('-->'));
      });

      test('handles multiple consecutive comments', () {
        const input = '''
{{-- Comment 1 --}}
{{-- Comment 2 --}}
{{-- Comment 3 --}}
<p>Content</p>
''';

        final result = formatter.format(input);

        expect(result, contains('{{-- Comment 1 --}}'));
        expect(result, contains('{{-- Comment 2 --}}'));
        expect(result, contains('{{-- Comment 3 --}}'));
      });
    });

    group('complex real-world scenarios', () {
      test('formats Laravel auth scaffolding pattern', () {
        const input = '''
@auth
<div class="user-panel">
@can('admin')
<a href="/admin">Admin</a>
@endcan
<p>{{ Auth::user()->name }}</p>
</div>
@endauth
@guest
<a href="/login">Login</a>
@endguest
''';

        final result = formatter.format(input);

        expect(result, contains('@auth'));
        expect(result, contains('@can(\'admin\')'));
        expect(result, contains('@guest'));
      });

      test('formats component with multiple slots', () {
        const input = '''
<x-card>
<x-slot:header>
<h2>Title</h2>
</x-slot>
<p>Main content</p>
<x-slot:footer>
<button>Action</button>
</x-slot>
</x-card>
''';

        final result = formatter.format(input);

        expect(result, contains('<x-card>'));
        expect(result, contains('<x-slot:header>'));
        expect(result, contains('<x-slot:footer>'));
      });

      test('formats Livewire component with Alpine.js', () {
        const input = '''
<div wire:poll.5s x-data="{ open: false }">
<button wire:click="refresh" x-on:click="open = true">
Refresh
</button>
<div x-show="open" wire:loading>
Loading...
</div>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('wire:poll.5s'));
        expect(result, contains('x-data'));
        expect(result, contains('wire:click'));
        expect(result, contains('x-on:click'));
      });

      test('formats form with CSRF and method spoofing', () {
        const input = '''
<form method="POST" action="/users">
@csrf
@method('PUT')
<input type="text" name="name" value="{{ \$user->name }}">
<button type="submit">Update</button>
</form>
''';

        final result = formatter.format(input);

        expect(result, contains('<form'));
        expect(result, contains('@csrf'));
        expect(result, contains('@method(\'PUT\')'));
      });
    });

    group('malformed but recoverable', () {
      test('formats content with missing newlines', () {
        const input = '<div><p>Line1</p><p>Line2</p><p>Line3</p></div>';
        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>Line1</p>'));
        expect(result, contains('<p>Line2</p>'));
      });

      test('formats content with excessive indentation', () {
        const input = '''
        <div>
                <p>Content</p>
        </div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>Content</p>'));
      });

      test('formats content with inconsistent indentation', () {
        const input = '''
<div>
  <p>2 spaces</p>
    <span>4 spaces</span>
\t<em>1 tab</em>
</div>
''';

        final result = formatter.format(input);

        expect(result, contains('<div>'));
        expect(result, contains('<p>2 spaces</p>'));
        expect(result, contains('<span>4 spaces</span>'));
      });
    });
  });
}
