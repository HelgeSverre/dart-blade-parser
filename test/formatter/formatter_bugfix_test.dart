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
      final input =
          '@section("content")\n  <p>Content</p>\n@endsection';
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

  group('Bug 20: visitText hidden caller coupling', () {
    late BladeFormatter formatter;

    setUp(() {
      formatter = BladeFormatter();
    });

    test('text content is properly terminated', () {
      final input = '<div>\n  Hello World\n</div>';
      final output = formatter.format(input);
      expect(output, contains('Hello World'));
      expect(output, contains('</div>'));
    });
  });
}
