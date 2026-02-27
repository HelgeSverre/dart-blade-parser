import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('EchoSpacing config', () {
    group('EchoSpacing.spaced (default)', () {
      final formatter = BladeFormatter();

      test('adds spaces inside echo braces', () {
        final result = formatter.format('{{\$var}}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('normalizes existing spacing', () {
        final result = formatter.format('{{  \$var  }}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('adds spaces inside raw echo braces', () {
        final result = formatter.format('{!!\$var!!}');
        expect(result.trim(), '{!! \$var !!}');
      });
    });

    group('EchoSpacing.compact', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(echoSpacing: EchoSpacing.compact),
      );

      test('removes spaces inside echo braces', () {
        final result = formatter.format('{{ \$var }}');
        expect(result.trim(), '{{\$var}}');
      });

      test('removes spaces inside raw echo braces', () {
        final result = formatter.format('{!! \$var !!}');
        expect(result.trim(), '{!!\$var!!}');
      });

      test('works inline in HTML elements', () {
        final result = formatter.format('<p>{{ \$name }}</p>');
        expect(result.trim(), '<p>{{\$name}}</p>');
      });
    });

    group('EchoSpacing.preserve', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(echoSpacing: EchoSpacing.preserve),
      );

      test('preserves spaces when present', () {
        final result = formatter.format('{{ \$var }}');
        expect(result.trim(), '{{ \$var }}');
      });

      test('preserves no spaces when absent', () {
        final result = formatter.format('{{\$var}}');
        expect(result.trim(), '{{\$var}}');
      });

      test('preserves raw echo spacing', () {
        final result = formatter.format('{!!\$var!!}');
        expect(result.trim(), '{!!\$var!!}');
      });
    });
  });
}
