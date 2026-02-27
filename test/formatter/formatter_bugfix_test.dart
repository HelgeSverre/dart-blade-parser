import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Bug 4: @section/@show closing preserved', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('formatter preserves @show closing for @section', () {
      final input = '@section("sidebar")\n  <p>Sidebar content</p>\n@show';
      final output = formatter.format(input);
      expect(output, contains('@show'));
      expect(output, isNot(contains('@endsection')));
    });

    test('formatter preserves @endsection closing', () {
      final input = '@section("content")\n  <p>Content</p>\n@endsection';
      final output = formatter.format(input);
      expect(output, contains('@endsection'));
    });
  });

  group('Bug 7: O(n²) _output.toString() in hot loops', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('formatter handles large templates without behavior change', () {
      final lines = List.generate(100, (i) => '<div>Line $i</div>');
      final input = lines.join('\n');
      final output = formatter.format(input);
      expect(output, contains('Line 0'));
      expect(output, contains('Line 99'));
      expect('<div>Line'.allMatches(output).length, equals(100));
    });
  });

  group('Bug 9: Blank lines between ALL HTML siblings', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('formatter does not add blank lines between li elements', () {
      final input =
          '<ul>\n  <li>Item 1</li>\n  <li>Item 2</li>\n  <li>Item 3</li>\n</ul>';
      final output = formatter.format(input);
      expect(output, isNot(contains('</li>\n\n')));
    });

    test('formatter does not add blank lines between td elements', () {
      final input = '<tr>\n  <td>Cell 1</td>\n  <td>Cell 2</td>\n</tr>';
      final output = formatter.format(input);
      expect(output, isNot(contains('</td>\n\n')));
    });

    test('formatter adds blank lines between block-level elements', () {
      final input = '<div>Block 1</div>\n<div>Block 2</div>';
      final output = formatter.format(input);
      expect(output, contains('</div>\n\n<div'));
    });
  });

  group('Bug 10: EditorConfig path matching', () {
    test('EditorConfigSection matches path-based patterns', () {
      final section = EditorConfigSection(
        pattern: 'resources/views/*.blade.php',
        properties: {'indent_size': '2'},
      );

      expect(section.matches('resources/views/home.blade.php'), isTrue);
      expect(section.matches('home.blade.php'), isFalse);
    });

    test('EditorConfig.getProperties matches with relative path', () {
      final config = EditorConfig.parse('''
[resources/views/*.blade.php]
indent_size = 2
''');

      // When only basename is passed, path-based pattern should NOT match
      final basenameProps = config.getProperties('home.blade.php');
      expect(basenameProps['indent_size'], isNull);

      // When relative path is passed, pattern SHOULD match
      final relativeProps =
          config.getProperties('resources/views/home.blade.php');
      expect(relativeProps['indent_size'], equals('2'));
    });
  });

  group('Bug 17: FormatterConfig.toString() omits fields', () {
    test('FormatterConfig.toString() includes all fields', () {
      final config = FormatterConfig();
      final str = config.toString();
      expect(str, contains('closingBracketStyle'));
      expect(str, contains('selfClosingStyle'));
    });
  });

  group('Bug: @else/@elseif indented one level too deep', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('@else aligns with @if and @endif', () {
      final input =
          '<td>@if(\$user->isVerified())<span class="text-green-600">Verified</span>@else<span class="text-gray-400">Pending</span>@endif</td>';
      final output = formatter.format(input);
      expect(
        output,
        equals(
          '<td>\n'
          '    @if(\$user->isVerified())\n'
          '        <span class="text-green-600">Verified</span>\n'
          '    @else\n'
          '        <span class="text-gray-400">Pending</span>\n'
          '    @endif\n'
          '</td>\n',
        ),
      );
    });

    test('@elseif aligns with @if and @endif', () {
      final input =
          '<div>@if(\$a)<p>A</p>@elseif(\$b)<p>B</p>@else<p>C</p>@endif</div>';
      final output = formatter.format(input);
      expect(
        output,
        equals(
          '<div>\n'
          '    @if(\$a)\n'
          '        <p>A</p>\n'
          '    @elseif(\$b)\n'
          '        <p>B</p>\n'
          '    @else\n'
          '        <p>C</p>\n'
          '    @endif\n'
          '</div>\n',
        ),
      );
    });
  });

  group('Bug: duplicate name attribute in x-slot formatting', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('does not duplicate name attribute when converting slot syntax', () {
      const input = '<x-card><x-slot name="header">Content</x-slot></x-card>';
      final result = formatter.format(input);
      expect(result, contains('<x-slot:header>'));
      expect(result, isNot(contains('name="header"')));
    });
  });

  group('Bug 20: visitText hidden caller coupling', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('text content is properly terminated', () {
      final input = '<div>\n  Hello World\n</div>';
      final output = formatter.format(input);
      expect(
        output,
        equals(
          '<div>\n'
          '    Hello World\n'
          '</div>\n',
        ),
      );
    });
  });

  group('Bug: unknown/custom directives are preserved', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('preserves @inertia directive (no expression)', () {
      final output = formatter.format('@inertia');
      expect(output, contains('@inertia'));
    });

    test('preserves @inertiaHead directive (no expression)', () {
      final output = formatter.format('@inertiaHead');
      expect(output, contains('@inertiaHead'));
    });

    test('preserves @inertiaHead in HTML context', () {
      final input = '<head>\n@inertiaHead\n</head>';
      final output = formatter.format(input);
      expect(output, contains('@inertiaHead'));
      expect(output, contains('<head>'));
      expect(output, contains('</head>'));
    });

    test('preserves custom directive with expression', () {
      final output = formatter.format(r'@customDirective($page)');
      expect(output, contains('@customDirective'));
      expect(output, contains(r'$page'));
    });

    test('preserves @datetime with complex expression', () {
      final output = formatter.format(r'@datetime($post->created_at)');
      expect(output, contains('@datetime'));
      expect(output, contains(r'$post->created_at'));
    });

    test('preserves multiple unknown directives', () {
      final input = '@one\n<div>@two(\$x)</div>\n@three(\'a\', \'b\')';
      final output = formatter.format(input);
      expect(output, contains('@one'));
      expect(output, contains('@two'));
      expect(output, contains('@three'));
    });

    test('preserves unknown @end* directives (treated as inline)', () {
      final input = '@custom\nSome content\n@endcustom';
      final output = formatter.format(input);
      expect(output, contains('@custom'));
      expect(output, contains('@endcustom'));
    });

    test('preserves @vite directive (already supported)', () {
      final output = formatter.format("@vite(['resources/js/app.ts'])");
      expect(output, contains('@vite'));
    });

    test('preserves full Inertia layout with @inertiaHead and @inertia', () {
      final input = '''<!DOCTYPE html>
<html>
<head>
    @vite('resources/sass/app.scss')
    @inertiaHead
</head>
<body>
    @inertia
</body>
</html>''';
      final output = formatter.format(input);
      expect(output, contains('@inertiaHead'));
      expect(output, contains('@inertia'));
      expect(output, contains('@vite'));
    });
  });

  group('Custom block directives (@foo...@endfoo)', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('custom block directive with @endcard is nested properly', () {
      final input =
          "@card('primary')\n<h3>Title</h3>\n<p>Content</p>\n@endcard";
      final output = formatter.format(input);
      expect(output, contains("@card('primary')"));
      expect(output, contains('@endcard'));
      expect(output, contains('<h3>Title</h3>'));
    });

    test('custom block directive children are indented', () {
      final input = "@card('primary')\n<h3>Title</h3>\n@endcard";
      final output = formatter.format(input);
      expect(
          output, equals("@card('primary')\n    <h3>Title</h3>\n@endcard\n"));
    });

    test('nested custom block directives', () {
      final input = '@panel\n@card\n<p>Inner</p>\n@endcard\n@endpanel';
      final output = formatter.format(input);
      expect(output, contains('@panel'));
      expect(output, contains('@endpanel'));
      expect(output, contains('@card'));
      expect(output, contains('@endcard'));
      expect(output, contains('<p>Inner</p>'));
    });

    test('nested same-name custom block directives', () {
      final input = '@card\n@card\n<p>Inner</p>\n@endcard\n@endcard';
      final output = formatter.format(input);
      // Both @card and both @endcard must be present
      expect('@card'.allMatches(output).length, greaterThanOrEqualTo(2));
      expect('@endcard'.allMatches(output).length, equals(2));
    });

    test('custom block directive with known directives inside', () {
      final input =
          "@card('primary')\n@if(\$show)\n<p>Visible</p>\n@endif\n@endcard";
      final output = formatter.format(input);
      expect(output, contains("@card('primary')"));
      expect(output, contains('@if'));
      expect(output, contains('@endif'));
      expect(output, contains('@endcard'));
    });

    test('custom block without matching @end stays inline', () {
      final input = '@standalone\n<p>Text</p>';
      final output = formatter.format(input);
      expect(output, contains('@standalone'));
      expect(output, contains('<p>Text</p>'));
    });

    test('custom block directive without expression', () {
      final input = '@widget\n<div>Content</div>\n@endwidget';
      final output = formatter.format(input);
      expect(output, equals('@widget\n    <div>Content</div>\n@endwidget\n'));
    });

    test('@end* directive without matching opener stays inline', () {
      final output = formatter.format('@endfoo');
      expect(output, contains('@endfoo'));
    });

    test('custom block directive preserves complex expression', () {
      final input =
          "@modal('lg', ['backdrop' => true])\n<p>Modal body</p>\n@endmodal";
      final output = formatter.format(input);
      expect(output, contains("@modal('lg', ['backdrop' => true])"));
      expect(output, contains('@endmodal'));
    });
  });
}
