import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Parser Reuse Tests', () {
    test('tag stack is cleared between parse calls', () {
      final parser = BladeParser();

      // First parse with unclosed tag to leave stale entries
      parser.parse('<div><p>unclosed');

      // Second parse should be clean
      final result = parser.parse('<span>Hello</span>');
      expect(result.errors, isEmpty,
          reason: 'Stale tag stack should not affect second parse');
    });
  });
}
