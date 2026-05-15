import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';
import 'dart:io';

/// Targeted idempotency tests for the specific pattern of inline text
/// followed by inline HTML elements (br, span, strong, label, etc.)
/// and closing tags (</x-slot>, </p>, etc.)
///
/// These test the root cause: visitText doesn't write a trailing newline
/// on the last line, and visitHtmlElement unconditionally writes indent,
/// causing whitespace to grow on each re-format pass.
void main() {
  group('Formatter Inline Text + Element Idempotency', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    void expectIdempotent(String input, {String? description}) {
      final formatted1 = formatter.format(input);
      final formatted2 = formatter.format(formatted1);

      if (formatted1 != formatted2) {
        print('=== IDEMPOTENCY FAILURE ===');
        print('Description: ${description ?? "N/A"}');
        print('--- Pass 1 ---');
        print(_escapeWhitespace(formatted1));
        print('--- Pass 2 ---');
        print(_escapeWhitespace(formatted2));
        print('===========================');
      }

      expect(
        formatted2,
        equals(formatted1),
        reason: description ?? 'format(format(x)) should equal format(x)',
      );
    }

    group('text followed by void elements', () {
      test('text followed by <br>', () {
        expectIdempotent(
          '<div>Some text.<br></div>',
          description: 'text + <br>',
        );
      });

      test('text followed by <br><br>', () {
        expectIdempotent(
          '<div>Some text.<br><br></div>',
          description: 'text + <br><br>',
        );
      });

      test('text followed by <br> with more text', () {
        expectIdempotent(
          '<div>Line one.<br>Line two.</div>',
          description: 'text + <br> + text',
        );
      });

      test('text followed by <hr>', () {
        expectIdempotent(
          '<div>Content above<hr></div>',
          description: 'text + <hr>',
        );
      });
    });

    group('text followed by inline elements', () {
      test('text followed by <span>', () {
        expectIdempotent(
          '<div>Selected: <span x-text="selectedItem"></span></div>',
          description: 'text + <span>',
        );
      });

      test('text followed by <strong>', () {
        expectIdempotent(
          '<div>Note: <strong>important</strong></div>',
          description: 'text + <strong>',
        );
      });

      test('text followed by <a>', () {
        expectIdempotent(
          '<div>Click <a href="/link">here</a></div>',
          description: 'text + <a>',
        );
      });

      test('text followed by <label>', () {
        expectIdempotent(
          '<div>Field: <label>Name</label></div>',
          description: 'text + <label>',
        );
      });
    });

    group('text followed by closing tags', () {
      test('text before </p> closing', () {
        expectIdempotent(
          '<div><p>active tasks</p></div>',
          description: 'text + </p>',
        );
      });

      test('text before </label> closing', () {
        expectIdempotent(
          '<div><label>Email</label></div>',
          description: 'text + </label>',
        );
      });
    });

    group('realistic fixture patterns', () {
      test('laravel5 error message with <br> (login/register pattern)', () {
        expectIdempotent('''
<div class="alert alert-danger">
    <strong>Whoops!</strong> There were some problems with your input.<br><br>
    <ul>
        @foreach (\$errors->all() as \$error)
            <li>{{ \$error }}</li>
        @endforeach
    </ul>
</div>
''', description: 'laravel5 error message with <br>');
      });

      test('component slot text (billing pattern)', () {
        expectIdempotent('''
<x-layouts.base>
    <x-slot:title>Fakturainnstillinger</x-slot>
</x-layouts.base>
''', description: 'slot text content');
      });

      test('Alpine x-text span after text', () {
        expectIdempotent('''
<div x-data="{ selectedItem: null }">
    <p>Selected: <span x-text="selectedItem"></span></p>
</div>
''', description: 'Alpine x-text after text');
      });

      test('label with text content closing tag', () {
        expectIdempotent('''
<div>
    <label>
        <input type="checkbox" wire:model="agree">
        Email
    </label>
</div>
''', description: 'label with text and input');
      });

      test('directive inside tag head indentation', () {
        expectIdempotent('''
<input
    type="text"
    @if(\$disabled) disabled @endif
>
''', description: 'directive in tag head');
      });

      test('strong element after text in section', () {
        expectIdempotent('''
@section('content')
    <p>This is <strong class="text-bold">important</strong> text.</p>
@endsection
''', description: 'strong after text in section');
      });

      test('span with x-text after text count', () {
        expectIdempotent('''
<div>
    <p>Scroll count: <span x-text="scrollCount"></span></p>
</div>
''', description: 'span x-text after count text');
      });

      test('nested text with inline elements', () {
        expectIdempotent('''
<div>
    <p>Cart (<span x-text="itemCount"></span> items)</p>
</div>
''', description: 'nested inline elements with text');
      });

      test('span after text in combination template', () {
        expectIdempotent('''
<div>
    <p>Status: <span class="text-green-500">Active</span></p>
</div>
''', description: 'span class after text');
      });
    });

    group('inline elements should stay inline with text', () {
      test('text<span>text</span> preserves no-space', () {
        final formatted = formatter.format('<p>Word<span>Suffix</span></p>');
        expect(formatted.trim(), equals('<p>Word<span>Suffix</span></p>'));
        expectIdempotent(
          '<p>Word<span>Suffix</span></p>',
          description: 'no space between text and span',
        );
      });

      test('text <a>link</a> text stays inline', () {
        final formatted =
            formatter.format('<p>Click <a href="/">here</a> for more.</p>');
        expect(formatted, contains('Click <a href="/">here</a> for more.'));
        expectIdempotent(
          '<p>Click <a href="/">here</a> for more.</p>',
          description: 'inline link in prose',
        );
      });

      test('text <strong>text</strong> text stays inline', () {
        final formatted =
            formatter.format('<p>Hello <strong>world</strong> goodbye</p>');
        expect(formatted, contains('Hello <strong>world</strong> goodbye'));
        expectIdempotent(
          '<p>Hello <strong>world</strong> goodbye</p>',
          description: 'inline strong in prose',
        );
      });

      test('text <em>text</em> text stays inline', () {
        final formatted =
            formatter.format('<p>This is <em>very</em> important.</p>');
        expect(formatted, contains('This is <em>very</em> important.'));
        expectIdempotent(
          '<p>This is <em>very</em> important.</p>',
          description: 'inline em in prose',
        );
      });

      test('text<br>text stays inline', () {
        final formatted = formatter.format('<p>Line one.<br>Line two.</p>');
        expect(formatted, contains('Line one.<br>Line two.'));
        expectIdempotent(
          '<p>Line one.<br>Line two.</p>',
          description: 'inline br between text',
        );
      });

      test('adjacent inline elements stay inline', () {
        final formatted =
            formatter.format('<p><span>A</span><span>B</span></p>');
        expect(formatted, contains('<span>A</span><span>B</span>'));
        expectIdempotent(
          '<p><span>A</span><span>B</span></p>',
          description: 'adjacent spans',
        );
      });

      test('text: <span x-text> stays inline', () {
        final formatted =
            formatter.format('<p>Selected: <span x-text="item"></span></p>');
        expect(formatted, contains('Selected: <span x-text="item"></span>'));
        expectIdempotent(
          '<p>Selected: <span x-text="item"></span></p>',
          description: 'text colon span inline',
        );
      });

      test('nested inline: <a><strong>text</strong></a>', () {
        final formatted = formatter
            .format('<p>Click <a href="/"><strong>here</strong></a></p>');
        expect(
            formatted, contains('Click <a href="/"><strong>here</strong></a>'));
        expectIdempotent(
          '<p>Click <a href="/"><strong>here</strong></a></p>',
          description: 'nested inline elements',
        );
      });

      test('block child forces block formatting', () {
        final formatted =
            formatter.format('<div>Text <div>block</div> more</div>');
        // Block elements inside should NOT be kept inline
        expect(formatted, isNot(contains('Text <div>')));
        expectIdempotent(
          '<div>Text <div>block</div> more</div>',
          description: 'block child forces block',
        );
      });
    });

    group('text followed by echo (should stay inline)', () {
      test('text followed by echo stays inline', () {
        final input = '@if(\$x)\n    Deadline: {{ \$date }}\n@endif';
        final formatted = formatter.format(input);
        expect(formatted, contains('Deadline: {{ \$date }}'));
        expectIdempotent(input, description: 'text + echo inline');
      });

      test('text followed by raw echo stays inline', () {
        final input = '@if(\$x)\n    Content: {!! \$html !!}\n@endif';
        final formatted = formatter.format(input);
        expect(formatted, contains('Content: {!! \$html !!}'));
        expectIdempotent(input, description: 'text + raw echo inline');
      });
    });

    group('benchmark fixture idempotency', () {
      final fixtureFiles = [
        'benchmark/fixtures/legacy/laravel5-auth-login.blade.php',
        'benchmark/fixtures/legacy/laravel5-auth-register.blade.php',
        'benchmark/fixtures/components/02-billing.blade.php',
        'benchmark/fixtures/synthetic/03-alpine/data-reactivity/01-x-data-basic.blade.php',
      ];

      for (final path in fixtureFiles) {
        test('fixture: ${path.split('/').last}', () {
          final file = File(path);
          if (!file.existsSync()) {
            print('Fixture not found: $path');
            return;
          }
          expectIdempotent(
            file.readAsStringSync(),
            description: path.split('/').last,
          );
        });
      }
    });

    group('issue #17: inline text around echo and component', () {
      // Pre-fix, visitEcho and the self-closing branch of visitComponent
      // always emitted a trailing newline, breaking `text {{ $x }} more text`
      // across three lines and forcing inline components onto their own line.

      test('text + echo + text stays on one line', () {
        final formatted =
            formatter.format('Some text {{ \$variable }} more text');
        expect(
          formatted.trim(),
          equals('Some text {{ \$variable }} more text'),
        );
      });

      test('two echoes interleaved with text stay on one line', () {
        final formatted = formatter
            .format('Some text {{ \$variable }} to {{ \$otherVariable }}?');
        expect(
          formatted.trim(),
          equals('Some text {{ \$variable }} to {{ \$otherVariable }}?'),
        );
      });

      test('text + self-closing component + text stays on one line', () {
        final formatted =
            formatter.format('Click <x-foo :bar="\$baz" /> here');
        expect(
          formatted.trim(),
          equals('Click <x-foo :bar="\$baz" /> here'),
        );
      });

      test('text + echo + text inside HTML stays on one line', () {
        final formatted = formatter
            .format('<p>Some text {{ \$variable }} more text</p>');
        expect(
          formatted,
          contains('Some text {{ \$variable }} more text'),
        );
      });

      test('inline echo+text is idempotent', () {
        expectIdempotent(
          'Some text {{ \$variable }} more text',
          description: 'echo between text',
        );
      });

      test('inline component+text is idempotent', () {
        expectIdempotent(
          'Click <x-foo :bar="\$baz" /> here',
          description: 'self-closing component between text',
        );
      });
    });
  });
}

String _escapeWhitespace(String s) {
  return s.replaceAll('\t', '→').replaceAll(' ', '·').replaceAll('\r', '↵');
}
