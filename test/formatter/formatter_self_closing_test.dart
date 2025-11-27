import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:test/test.dart';

void main() {
  group('Formatter - Self-closing Style', () {
    group('SelfClosingStyle.preserve (default)', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          selfClosingStyle: SelfClosingStyle.preserve,
        ),
      );

      test('preserves self-closing div', () {
        const input = '<div class="empty" />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty" />'));
      });

      test('preserves explicit close on empty div', () {
        const input = '<div class="empty"></div>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty"></div>'));
      });

      test('preserves self-closing component', () {
        const input = '<x-alert type="info" />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<x-alert type="info" />'));
      });

      test('preserves explicit close on empty component', () {
        const input = '<x-alert type="info"></x-alert>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<x-alert type="info"></x-alert>'));
      });
    });

    group('SelfClosingStyle.always', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          selfClosingStyle: SelfClosingStyle.always,
        ),
      );

      test('converts empty div to self-closing', () {
        const input = '<div class="empty"></div>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty" />'));
      });

      test('keeps already self-closing div', () {
        const input = '<div class="empty" />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty" />'));
      });

      test('converts empty component to self-closing', () {
        const input = '<x-alert type="info"></x-alert>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<x-alert type="info" />'));
      });

      test('does not affect elements with content', () {
        const input = '<div class="has-content">Hello</div>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="has-content">Hello</div>'));
      });

      test('does not affect void elements', () {
        const input = '<img src="image.png" alt="test">';
        final result = formatter.format(input);

        // Void elements should stay as-is
        expect(result.trim(), equals('<img src="image.png" alt="test">'));
      });

      test('converts empty span to self-closing', () {
        const input = '<span></span>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<span />'));
      });
    });

    group('SelfClosingStyle.never', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(
          selfClosingStyle: SelfClosingStyle.never,
        ),
      );

      test('converts self-closing div to explicit close', () {
        const input = '<div class="empty" />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty"></div>'));
      });

      test('keeps already explicit close div', () {
        const input = '<div class="empty"></div>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="empty"></div>'));
      });

      test('converts self-closing component to explicit close', () {
        const input = '<x-alert type="info" />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<x-alert type="info"></x-alert>'));
      });

      test('does not affect elements with content', () {
        const input = '<div class="has-content">Hello</div>';
        final result = formatter.format(input);

        expect(result.trim(), equals('<div class="has-content">Hello</div>'));
      });

      test('does not affect void elements', () {
        const input = '<img src="image.png" alt="test">';
        final result = formatter.format(input);

        // Void elements should stay as-is (always self-closing)
        expect(result.trim(), equals('<img src="image.png" alt="test">'));
      });

      test('converts self-closing span to explicit close', () {
        const input = '<span />';
        final result = formatter.format(input);

        expect(result.trim(), equals('<span></span>'));
      });
    });

    group('combined with other options', () {
      test('works with attribute wrapping (always style)', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            selfClosingStyle: SelfClosingStyle.always,
            wrapAttributes: WrapAttributes.always,
          ),
        );

        const input = '<div class="empty" id="test"></div>';
        final result = formatter.format(input);

        expect(result, contains(' />'));
        expect(result, contains('class="empty"'));
        expect(result, contains('id="test"'));
      });

      test('works with closing bracket newLine style', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            selfClosingStyle: SelfClosingStyle.always,
            wrapAttributes: WrapAttributes.always,
            closingBracketStyle: ClosingBracketStyle.newLine,
          ),
        );

        const input = '<div class="empty" id="test"></div>';
        final result = formatter.format(input);

        // Should have bracket on new line and be self-closing
        expect(result, contains('id="test"\n/>'));
      });

      test('works with attribute sorting', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            selfClosingStyle: SelfClosingStyle.always,
            attributeSort: AttributeSort.alphabetical,
          ),
        );

        const input = '<div id="test" class="empty"></div>';
        final result = formatter.format(input);

        // Should sort and be self-closing
        expect(result.trim(), equals('<div class="empty" id="test" />'));
      });
    });

    group('configuration', () {
      test('fromMap parses self_closing_style correctly - always', () {
        final config = FormatterConfig.fromMap({
          'self_closing_style': 'always',
        });
        expect(config.selfClosingStyle, equals(SelfClosingStyle.always));
      });

      test('fromMap parses self_closing_style correctly - never', () {
        final config = FormatterConfig.fromMap({
          'self_closing_style': 'never',
        });
        expect(config.selfClosingStyle, equals(SelfClosingStyle.never));
      });

      test('fromMap defaults to preserve', () {
        final config = FormatterConfig.fromMap({});
        expect(config.selfClosingStyle, equals(SelfClosingStyle.preserve));
      });

      test('toMap serializes self_closing_style correctly', () {
        const config = FormatterConfig(
          selfClosingStyle: SelfClosingStyle.always,
        );
        final map = config.toMap();
        expect(map['self_closing_style'], equals('always'));
      });
    });

    group('edge cases', () {
      test('handles whitespace-only content as empty', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            selfClosingStyle: SelfClosingStyle.always,
          ),
        );

        const input = '<div class="test">   </div>';
        final result = formatter.format(input);

        // Whitespace-only content should be treated as empty
        expect(result.trim(), equals('<div class="test" />'));
      });

      test('preserves component with slot content', () {
        final formatter = BladeFormatter(
          config: const FormatterConfig(
            selfClosingStyle: SelfClosingStyle.always,
          ),
        );

        const input = '<x-card>Some content</x-card>';
        final result = formatter.format(input);

        // Should not convert to self-closing because it has content
        expect(result.trim(), equals('<x-card>Some content</x-card>'));
      });
    });
  });
}
