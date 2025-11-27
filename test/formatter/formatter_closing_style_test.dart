import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter - Closing Bracket Style', () {
    group('ClosingBracketStyle.sameLine (default)', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          wrapAttributes: WrapAttributes.always,
          closingBracketStyle: ClosingBracketStyle.sameLine,
        ),
      );

      test('places closing bracket on same line as last attribute', () {
        const input = '<div class="container" id="main"></div>';
        final result = formatter.format(input);

        expect(result, contains('id="main">'));
        expect(result, isNot(contains('id="main"\n>')));
      });

      test('works with HTML elements', () {
        // Use element with content to see the full wrapping behavior
        const input = '<div class="foo" id="bar"><span>Content</span></div>';
        final result = formatter.format(input);

        // Last attribute should have > on same line
        expect(result, contains('id="bar">'));
      });

      test('works with components', () {
        const input = '<x-alert type="warning" message="Hello">Content</x-alert>';
        final result = formatter.format(input);

        expect(result, contains('message="Hello">'));
      });

      test('works with self-closing tags', () {
        const input = '<x-icon name="check" size="large" />';
        final result = formatter.format(input);

        expect(result, contains('size="large" />'));
      });
    });

    group('ClosingBracketStyle.newLine', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          wrapAttributes: WrapAttributes.always,
          closingBracketStyle: ClosingBracketStyle.newLine,
        ),
      );

      test('places closing bracket on new line', () {
        const input = '<div class="container" id="main"></div>';
        final result = formatter.format(input);

        // Should have bracket on its own line
        expect(result, contains('id="main"\n>'));
      });

      test('aligns bracket with tag indentation', () {
        // Use element with content to see full wrapping behavior
        const input = '<div class="foo" id="bar"><span>Content</span></div>';
        final result = formatter.format(input);

        // Bracket should be at same indentation as opening tag
        final lines = result.trim().split('\n');
        expect(lines[0], equals('<div'));
        expect(lines[1], equals('    class="foo"'));
        expect(lines[2], equals('    id="bar"'));
        expect(lines[3], equals('>'));
        // Content on next line
        expect(lines[4], contains('span'));
      });

      test('works with components', () {
        const input = '<x-alert type="warning" message="Hello">Content</x-alert>';
        final result = formatter.format(input);

        expect(result, contains('message="Hello"\n>'));
      });

      test('works with self-closing tags', () {
        const input = '<x-icon name="check" size="large" />';
        final result = formatter.format(input);

        expect(result, contains('size="large"\n/>'));
      });

      test('does not affect single-line attributes', () {
        final singleLineFormatter = BladeFormatter(
          config: const FormatterConfig(
            wrapAttributes: WrapAttributes.never,
            closingBracketStyle: ClosingBracketStyle.newLine,
          ),
        );

        const input = '<div class="foo" id="bar"></div>';
        final result = singleLineFormatter.format(input);

        // Single line should not have bracket on new line
        expect(result.trim(), equals('<div class="foo" id="bar"></div>'));
      });
    });

    group('nested elements', () {
      test('newLine style with nested elements', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            wrapAttributes: WrapAttributes.always,
            closingBracketStyle: ClosingBracketStyle.newLine,
          ),
        );

        const input = '''
<div class="outer" id="container">
    <span class="inner" data-value="test">Text</span>
</div>''';
        final result = formatter.format(input);

        // Both elements should have bracket on new line
        expect(result, contains('id="container"\n>'));
        expect(result, contains('data-value="test"\n    >'));
      });
    });

    group('configuration', () {
      test('fromMap parses closing_bracket_style correctly', () {
        final config = FormatterConfig.fromMap({
          'closing_bracket_style': 'new_line',
        });
        expect(config.closingBracketStyle, equals(ClosingBracketStyle.newLine));
      });

      test('fromMap defaults to sameLine', () {
        final config = FormatterConfig.fromMap({});
        expect(config.closingBracketStyle, equals(ClosingBracketStyle.sameLine));
      });

      test('toMap serializes closing_bracket_style correctly', () {
        const config = FormatterConfig(
          closingBracketStyle: ClosingBracketStyle.newLine,
        );
        final map = config.toMap();
        expect(map['closing_bracket_style'], equals('new_line'));
      });
    });
  });
}
