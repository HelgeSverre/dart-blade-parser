import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('trailingNewline config', () {
    test('default adds trailing newline', () {
      final formatter = BladeFormatter();
      final result = formatter.format('<div></div>');
      expect(result, endsWith('\n'));
    });

    test('trailingNewline: false omits trailing newline', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: false),
      );
      final result = formatter.format('<div></div>');
      expect(result, isNot(endsWith('\n')));
      expect(result, equals('<div></div>'));
    });

    test('trailingNewline: false with multiple elements', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: false),
      );
      final result = formatter.format('<div></div>\n<p>Hello</p>');
      expect(result, isNot(endsWith('\n')));
    });

    test('trailingNewline: true explicitly adds trailing newline', () {
      final formatter = BladeFormatter(
        config: const FormatterConfig(trailingNewline: true),
      );
      final result = formatter.format('<div></div>');
      expect(result, endsWith('\n'));
      expect(result, isNot(endsWith('\n\n')));
    });
  });
}
