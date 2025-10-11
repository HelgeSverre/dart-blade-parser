import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Parser Contract Tests', () {
    test('parse returns ParseResult', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$test }}');

      expect(result, isA<ParseResult>());
    });

    test('parse never throws for syntax errors', () {
      final parser = BladeParser();

      // Should not throw even with invalid syntax
      expect(
        () => parser.parse('@if(\$x)'), // Missing @endif
        returnsNormally,
      );
    });

    test('ParseResult has ast, errors, and isSuccess', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$test }}');

      expect(result.ast, isA<DocumentNode?>());
      expect(result.errors, isA<List<ParseError>>());
      expect(result.isSuccess, isA<bool>());
    });

    test('isSuccess is true when errors list is empty', () {
      final parser = BladeParser();
      final result = parser.parse('hello');

      if (result.errors.isEmpty) {
        expect(result.isSuccess, isTrue);
      }
    });
  });
}
