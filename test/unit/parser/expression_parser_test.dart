import 'package:test/test.dart';
import 'package:blade_parser/src/parser/expression_parser.dart';
import 'package:blade_parser/src/lexer/lexer.dart';
import 'package:blade_parser/src/lexer/token_type.dart';

void main() {
  group('Expression Parser Tests', () {
    String parseExpression(String input) {
      // Tokenize just the expression content
      final lexer = BladeLexer('@if($input)');
      final tokens = lexer.tokenize();

      // Find the expression token
      final exprToken = tokens.firstWhere(
        (t) => t.type == TokenType.expression,
        orElse: () => throw Exception('No expression token found'),
      );

      // Parse the expression
      final parser = ExpressionParser([exprToken]);
      return parser.parse();
    }

    test('Parse simple variable', () {
      final result = parseExpression('\$user');
      expect(result, contains('\$user'));
    });

    test('Parse binary operation with correct precedence', () {
      final result = parseExpression('\$a + \$b * \$c');
      expect(result, contains('\$a + \$b * \$c'));
      // Multiplication should bind tighter than addition
    });

    test('Parse comparison operators', () {
      final result = parseExpression('\$count > 5');
      expect(result, contains('\$count > 5'));
    });

    test('Parse logical AND operator', () {
      final result = parseExpression('\$a && \$b');
      expect(result, contains('\$a && \$b'));
    });

    test('Parse logical OR operator', () {
      final result = parseExpression('\$a || \$b');
      expect(result, contains('\$a || \$b'));
    });

    test('Parse ternary operator', () {
      final result = parseExpression('\$x ? "yes" : "no"');
      expect(result, contains('?'));
      expect(result, contains(':'));
    });

    test('Parse property access', () {
      final result = parseExpression('\$user->name');
      expect(result, contains('\$user->name'));
    });

    test('Parse method call', () {
      final result = parseExpression('\$user->getName()');
      expect(result, contains('\$user->getName()'));
    });

    test('Parse array access', () {
      final result = parseExpression('\$items[0]');
      expect(result, contains('\$items[0]'));
    });

    test('Parse parenthesized expression', () {
      final result = parseExpression('(\$a + \$b) * \$c');
      expect(result, contains('(\$a + \$b) * \$c'));
    });

    test('Parse complex nested expression', () {
      final result = parseExpression(
          '\$user->posts()->where("status", "published")->count() > 0');
      expect(result, isNotEmpty);
      expect(result, contains('->'));
    });

    test('Parse string literal in expression', () {
      final result = parseExpression('\$name == "John"');
      expect(result, contains('"John"'));
    });

    test('Parse numeric literal', () {
      final result = parseExpression('\$count === 42');
      expect(result, contains('42'));
    });

    test('Parse null coalescing operator', () {
      final result = parseExpression('\$value ?? "default"');
      expect(result, contains('??'));
    });

    test('Parse not operator', () {
      final result = parseExpression('!\$isActive');
      expect(result, contains('!'));
    });

    test('Parse complex boolean expression', () {
      final result =
          parseExpression('(\$age >= 18 && \$verified) || \$isAdmin');
      expect(result, isNotEmpty);
      expect(result, contains('&&'));
      expect(result, contains('||'));
    });
  });
}
