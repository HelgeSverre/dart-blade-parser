import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('FormatterConfig', () {
    group('Constructor and Defaults', () {
      test('uses default values when no arguments provided', () {
        const config = FormatterConfig();

        expect(config.indentSize, 4);
        expect(config.indentStyle, IndentStyle.spaces);
        expect(config.formatPhpExpressions, false);
        expect(config.maxLineLength, 120);
        expect(config.quoteStyle, QuoteStyle.preserve);
      });

      test('allows custom indent size', () {
        const config = FormatterConfig(indentSize: 2);

        expect(config.indentSize, 2);
      });

      test('allows custom indent style', () {
        const config = FormatterConfig(indentStyle: IndentStyle.tabs);

        expect(config.indentStyle, IndentStyle.tabs);
      });

      test('allows custom quote style', () {
        const config = FormatterConfig(quoteStyle: QuoteStyle.single);

        expect(config.quoteStyle, QuoteStyle.single);
      });

      test('allows custom max line length', () {
        const config = FormatterConfig(maxLineLength: 80);

        expect(config.maxLineLength, 80);
      });

      test('allows custom formatPhpExpressions', () {
        const config = FormatterConfig(formatPhpExpressions: true);

        expect(config.formatPhpExpressions, true);
      });

      test('allows all custom values together', () {
        const config = FormatterConfig(
          indentSize: 2,
          indentStyle: IndentStyle.tabs,
          formatPhpExpressions: true,
          maxLineLength: 80,
          quoteStyle: QuoteStyle.double,
        );

        expect(config.indentSize, 2);
        expect(config.indentStyle, IndentStyle.tabs);
        expect(config.formatPhpExpressions, true);
        expect(config.maxLineLength, 80);
        expect(config.quoteStyle, QuoteStyle.double);
      });
    });

    group('Factory Constructors', () {
      test('defaults() creates config with default values', () {
        final config = FormatterConfig.defaults();

        expect(config.indentSize, 4);
        expect(config.indentStyle, IndentStyle.spaces);
        expect(config.formatPhpExpressions, false);
        expect(config.maxLineLength, 120);
        expect(config.quoteStyle, QuoteStyle.preserve);
      });

      test('compact() creates config with 2-space indentation', () {
        final config = FormatterConfig.compact();

        expect(config.indentSize, 2);
        expect(config.indentStyle, IndentStyle.spaces);
      });
    });

    group('fromMap() - Valid Input', () {
      test('creates config from map with all values', () {
        final config = FormatterConfig.fromMap({
          'indent_size': 2,
          'indent_style': 'tabs',
          'format_php_expressions': true,
          'max_line_length': 80,
          'quote_style': 'single',
        });

        expect(config.indentSize, 2);
        expect(config.indentStyle, IndentStyle.tabs);
        expect(config.formatPhpExpressions, true);
        expect(config.maxLineLength, 80);
        expect(config.quoteStyle, QuoteStyle.single);
      });

      test('creates config with spaces indent style', () {
        final config = FormatterConfig.fromMap({
          'indent_style': 'spaces',
        });

        expect(config.indentStyle, IndentStyle.spaces);
      });

      test('creates config with tabs indent style', () {
        final config = FormatterConfig.fromMap({
          'indent_style': 'tabs',
        });

        expect(config.indentStyle, IndentStyle.tabs);
      });

      test('parses quote_style single', () {
        final config = FormatterConfig.fromMap({
          'quote_style': 'single',
        });

        expect(config.quoteStyle, QuoteStyle.single);
      });

      test('parses quote_style double', () {
        final config = FormatterConfig.fromMap({
          'quote_style': 'double',
        });

        expect(config.quoteStyle, QuoteStyle.double);
      });

      test('parses quote_style preserve', () {
        final config = FormatterConfig.fromMap({
          'quote_style': 'preserve',
        });

        expect(config.quoteStyle, QuoteStyle.preserve);
      });
    });

    group('fromMap() - Missing/Null Values', () {
      test('uses defaults when map is empty', () {
        final config = FormatterConfig.fromMap({});

        expect(config.indentSize, 4);
        expect(config.indentStyle, IndentStyle.spaces);
        expect(config.formatPhpExpressions, false);
        expect(config.maxLineLength, 120);
        expect(config.quoteStyle, QuoteStyle.preserve);
      });

      test('uses default indent_size when null', () {
        final config = FormatterConfig.fromMap({
          'indent_size': null,
        });

        expect(config.indentSize, 4);
      });

      test('uses default indent_style when null', () {
        final config = FormatterConfig.fromMap({
          'indent_style': null,
        });

        expect(config.indentStyle, IndentStyle.spaces);
      });

      test('uses default quote_style when null', () {
        final config = FormatterConfig.fromMap({
          'quote_style': null,
        });

        expect(config.quoteStyle, QuoteStyle.preserve);
      });

      test('uses default format_php_expressions when null', () {
        final config = FormatterConfig.fromMap({
          'format_php_expressions': null,
        });

        expect(config.formatPhpExpressions, false);
      });

      test('uses default max_line_length when null', () {
        final config = FormatterConfig.fromMap({
          'max_line_length': null,
        });

        expect(config.maxLineLength, 120);
      });

      test('handles unknown quote_style by defaulting to preserve', () {
        final config = FormatterConfig.fromMap({
          'quote_style': 'unknown',
        });

        expect(config.quoteStyle, QuoteStyle.preserve);
      });

      test('handles unknown indent_style by defaulting to spaces', () {
        final config = FormatterConfig.fromMap({
          'indent_style': 'unknown',
        });

        expect(config.indentStyle, IndentStyle.spaces);
      });
    });

    group('fromMap() - Edge Cases', () {
      test('handles indent_size as zero', () {
        final config = FormatterConfig.fromMap({
          'indent_size': 0,
        });

        expect(config.indentSize, 0);
      });

      test('handles very large indent_size', () {
        final config = FormatterConfig.fromMap({
          'indent_size': 100,
        });

        expect(config.indentSize, 100);
      });

      test('handles very large max_line_length', () {
        final config = FormatterConfig.fromMap({
          'max_line_length': 1000,
        });

        expect(config.maxLineLength, 1000);
      });

      test('handles format_php_expressions as false', () {
        final config = FormatterConfig.fromMap({
          'format_php_expressions': false,
        });

        expect(config.formatPhpExpressions, false);
      });

      test('handles format_php_expressions as true', () {
        final config = FormatterConfig.fromMap({
          'format_php_expressions': true,
        });

        expect(config.formatPhpExpressions, true);
      });
    });

    group('toMap() - Serialization', () {
      test('serializes all values correctly', () {
        const config = FormatterConfig(
          indentSize: 2,
          indentStyle: IndentStyle.tabs,
          formatPhpExpressions: true,
          maxLineLength: 80,
          quoteStyle: QuoteStyle.single,
        );

        final map = config.toMap();

        expect(map['indent_size'], 2);
        expect(map['indent_style'], 'tabs');
        expect(map['format_php_expressions'], true);
        expect(map['max_line_length'], 80);
        expect(map['quote_style'], 'single');
      });

      test('serializes spaces indent style', () {
        const config = FormatterConfig(indentStyle: IndentStyle.spaces);
        final map = config.toMap();

        expect(map['indent_style'], 'spaces');
      });

      test('serializes tabs indent style', () {
        const config = FormatterConfig(indentStyle: IndentStyle.tabs);
        final map = config.toMap();

        expect(map['indent_style'], 'tabs');
      });

      test('serializes single quote style', () {
        const config = FormatterConfig(quoteStyle: QuoteStyle.single);
        final map = config.toMap();

        expect(map['quote_style'], 'single');
      });

      test('serializes double quote style', () {
        const config = FormatterConfig(quoteStyle: QuoteStyle.double);
        final map = config.toMap();

        expect(map['quote_style'], 'double');
      });

      test('serializes preserve quote style', () {
        const config = FormatterConfig(quoteStyle: QuoteStyle.preserve);
        final map = config.toMap();

        expect(map['quote_style'], 'preserve');
      });
    });

    group('Roundtrip Serialization', () {
      test('fromMap(toMap()) preserves all values', () {
        const original = FormatterConfig(
          indentSize: 2,
          indentStyle: IndentStyle.tabs,
          formatPhpExpressions: true,
          maxLineLength: 80,
          quoteStyle: QuoteStyle.single,
        );

        final map = original.toMap();
        final restored = FormatterConfig.fromMap(map);

        expect(restored.indentSize, original.indentSize);
        expect(restored.indentStyle, original.indentStyle);
        expect(restored.formatPhpExpressions, original.formatPhpExpressions);
        expect(restored.maxLineLength, original.maxLineLength);
        expect(restored.quoteStyle, original.quoteStyle);
      });

      test('fromMap(toMap()) preserves default values', () {
        final original = FormatterConfig.defaults();

        final map = original.toMap();
        final restored = FormatterConfig.fromMap(map);

        expect(restored.indentSize, original.indentSize);
        expect(restored.indentStyle, original.indentStyle);
        expect(restored.formatPhpExpressions, original.formatPhpExpressions);
        expect(restored.maxLineLength, original.maxLineLength);
        expect(restored.quoteStyle, original.quoteStyle);
      });

      test('fromMap(toMap()) works for compact config', () {
        final original = FormatterConfig.compact();

        final map = original.toMap();
        final restored = FormatterConfig.fromMap(map);

        expect(restored.indentSize, original.indentSize);
        expect(restored.indentStyle, original.indentStyle);
      });
    });

    group('toString()', () {
      test('includes all configuration values', () {
        const config = FormatterConfig(
          indentSize: 2,
          indentStyle: IndentStyle.tabs,
          formatPhpExpressions: true,
          maxLineLength: 80,
          quoteStyle: QuoteStyle.single,
        );

        final str = config.toString();

        expect(str, contains('indentSize: 2'));
        expect(str, contains('indentStyle: IndentStyle.tabs'));
        expect(str, contains('formatPhpExpressions: true'));
        expect(str, contains('maxLineLength: 80'));
        expect(str, contains('quoteStyle: QuoteStyle.single'));
      });

      test('is readable for default config', () {
        final config = FormatterConfig.defaults();
        final str = config.toString();

        expect(str, isNotEmpty);
        expect(str, contains('FormatterConfig'));
      });
    });

    group('Equality and Immutability', () {
      test('configs with same values are equal', () {
        const config1 = FormatterConfig(indentSize: 2);
        const config2 = FormatterConfig(indentSize: 2);

        // Note: FormatterConfig doesn't override == operator,
        // so this tests that they're immutable value types
        expect(config1.indentSize, config2.indentSize);
        expect(config1.indentStyle, config2.indentStyle);
        expect(config1.quoteStyle, config2.quoteStyle);
      });

      test('is immutable (const constructor works)', () {
        const config = FormatterConfig(indentSize: 2);

        // If it compiles with const, it's immutable
        expect(config.indentSize, 2);
      });
    });

    group('Real-world Scenarios', () {
      test('loads typical Laravel project config', () {
        final config = FormatterConfig.fromMap({
          'indent_size': 4,
          'indent_style': 'spaces',
          'quote_style': 'double',
          'max_line_length': 120,
        });

        expect(config.indentSize, 4);
        expect(config.indentStyle, IndentStyle.spaces);
        expect(config.quoteStyle, QuoteStyle.double);
        expect(config.maxLineLength, 120);
      });

      test('loads compact/minimalist config', () {
        final config = FormatterConfig.fromMap({
          'indent_size': 2,
        });

        expect(config.indentSize, 2);
        expect(config.indentStyle, IndentStyle.spaces); // Default
      });

      test('loads tab-based project config', () {
        final config = FormatterConfig.fromMap({
          'indent_style': 'tabs',
          'quote_style': 'single',
        });

        expect(config.indentStyle, IndentStyle.tabs);
        expect(config.quoteStyle, QuoteStyle.single);
      });

      test('handles config from JSON file', () {
        // Simulates JSON.decode() result
        final jsonData = <String, dynamic>{
          'indent_size': 4,
          'indent_style': 'spaces',
          'format_php_expressions': false,
          'max_line_length': 120,
          'quote_style': 'preserve',
        };

        final config = FormatterConfig.fromMap(jsonData);

        expect(config.indentSize, 4);
        expect(config.indentStyle, IndentStyle.spaces);
        expect(config.formatPhpExpressions, false);
      });
    });
  });

  group('IndentStyle Enum', () {
    test('has spaces value', () {
      expect(IndentStyle.spaces, isNotNull);
    });

    test('has tabs value', () {
      expect(IndentStyle.tabs, isNotNull);
    });

    test('toString() returns readable name', () {
      expect(IndentStyle.spaces.toString(), contains('spaces'));
      expect(IndentStyle.tabs.toString(), contains('tabs'));
    });
  });

  group('QuoteStyle Enum', () {
    test('has single value', () {
      expect(QuoteStyle.single, isNotNull);
    });

    test('has double value', () {
      expect(QuoteStyle.double, isNotNull);
    });

    test('has preserve value', () {
      expect(QuoteStyle.preserve, isNotNull);
    });

    test('toString() returns readable name', () {
      expect(QuoteStyle.single.toString(), contains('single'));
      expect(QuoteStyle.double.toString(), contains('double'));
      expect(QuoteStyle.preserve.toString(), contains('preserve'));
    });
  });
}
