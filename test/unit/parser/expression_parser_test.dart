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
        '\$user->posts()->where("status", "published")->count() > 0',
      );
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
      final result = parseExpression(
        '(\$age >= 18 && \$verified) || \$isAdmin',
      );
      expect(result, isNotEmpty);
      expect(result, contains('&&'));
      expect(result, contains('||'));
    });

    // Additional test coverage

    test('Parse array literal', () {
      final result = parseExpression('[1, 2, 3]');
      expect(result, contains('['));
      expect(result, contains(']'));
      expect(result, contains(','));
    });

    test('Parse empty array literal', () {
      final result = parseExpression('[]');
      expect(result, contains('[]'));
    });

    test('Parse nested array literal', () {
      final result = parseExpression('[1, [2, 3], 4]');
      expect(result, contains('['));
      expect(result, contains(']'));
    });

    test('Parse bitwise AND operator', () {
      final result = parseExpression('\$flags & 0x0F');
      expect(result, contains('&'));
    });

    test('Parse bitwise OR operator', () {
      final result = parseExpression('\$a | \$b');
      expect(result, contains('|'));
    });

    test('Parse bitwise XOR operator', () {
      final result = parseExpression('\$a ^ \$b');
      expect(result, contains('^'));
    });

    test('Parse bitwise NOT operator', () {
      final result = parseExpression('~\$flags');
      expect(result, contains('~'));
    });

    test('Parse left shift operator', () {
      final result = parseExpression('\$value << 2');
      expect(result, contains('<<'));
    });

    test('Parse right shift operator', () {
      final result = parseExpression('\$value >> 2');
      expect(result, contains('>>'));
    });

    test('Parse spaceship operator', () {
      final result = parseExpression('\$a <=> \$b');
      expect(result, contains('<=>'));
    });

    test('Parse unary minus', () {
      final result = parseExpression('-\$count');
      expect(result, contains('-'));
    });

    test('Parse unary plus', () {
      final result = parseExpression('+\$count');
      expect(result, contains('+'));
    });

    test('Parse true literal', () {
      final result = parseExpression('true');
      expect(result, contains('true'));
    });

    test('Parse false literal', () {
      final result = parseExpression('false');
      expect(result, contains('false'));
    });

    test('Parse null literal', () {
      final result = parseExpression('null');
      expect(result, contains('null'));
    });

    test('Parse empty function call', () {
      final result = parseExpression('doSomething()');
      expect(result, contains('doSomething()'));
    });

    test('Parse function call with multiple arguments', () {
      final result = parseExpression('func(\$a, \$b, "test")');
      expect(result, contains('func('));
      expect(result, contains('\$a'));
      expect(result, contains('\$b'));
      expect(result, contains('"test"'));
    });

    test('Parse power operator', () {
      final result = parseExpression('\$x ** 2');
      expect(result, contains('**'));
    });

    test('Parse modulo operator', () {
      final result = parseExpression('\$a % \$b');
      expect(result, contains('%'));
    });

    test('Parse division operator', () {
      final result = parseExpression('\$a / \$b');
      expect(result, contains('/'));
    });

    test('Parse concatenation operator', () {
      final result = parseExpression('\$firstName . \$lastName');
      expect(result, contains('.'));
    });

    test('Parse strict equality', () {
      final result = parseExpression('\$a === \$b');
      expect(result, contains('==='));
    });

    test('Parse strict inequality', () {
      final result = parseExpression('\$a !== \$b');
      expect(result, contains('!=='));
    });

    test('Parse less than or equal', () {
      final result = parseExpression('\$a <= \$b');
      expect(result, contains('<='));
    });

    test('Parse greater than or equal', () {
      final result = parseExpression('\$a >= \$b');
      expect(result, contains('>='));
    });

    test('Parse logical "and" keyword', () {
      final result = parseExpression('\$a and \$b');
      expect(result, contains('and'));
    });

    test('Parse logical "or" keyword', () {
      final result = parseExpression('\$a or \$b');
      expect(result, contains('or'));
    });

    test('Parse chained method calls', () {
      final result = parseExpression('\$user->profile()->settings()->get()');
      expect(result, contains('->profile()'));
      expect(result, contains('->settings()'));
      expect(result, contains('->get()'));
    });

    test('Parse nested array access', () {
      final result = parseExpression('\$matrix[0][1]');
      expect(result, contains('[0]'));
      expect(result, contains('[1]'));
    });

    test('Parse mixed array and method access', () {
      final result = parseExpression('\$obj->items[0]->name');
      expect(result, contains('->items'));
      expect(result, contains('[0]'));
      expect(result, contains('->name'));
    });

    test('Parse single quoted string', () {
      final result = parseExpression("'hello'");
      expect(result, contains("'hello'"));
    });

    test('Parse complex ternary with nested expressions', () {
      final result = parseExpression('\$x > 0 ? \$x * 2 : \$x / 2');
      expect(result, contains('?'));
      expect(result, contains(':'));
      expect(result, contains('*'));
      expect(result, contains('/'));
    });
  });
}
