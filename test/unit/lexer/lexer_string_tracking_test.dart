import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Lexer string literal tracking', () {
    test('directive expression handles ) inside single-quoted string', () {
      final lexer =
          BladeLexer("@if(strpos(\$str, ')') !== false) hello @endif");
      final tokens = lexer.tokenize();

      final exprToken =
          tokens.firstWhere((t) => t.type == TokenType.expression);
      expect(exprToken.value, contains('strpos'));
      expect(exprToken.value, contains('!== false'));
    });

    test('directive expression handles ) inside double-quoted string', () {
      final lexer =
          BladeLexer('@if(strpos(\$str, ")") !== false) hello @endif');
      final tokens = lexer.tokenize();

      final exprToken =
          tokens.firstWhere((t) => t.type == TokenType.expression);
      expect(exprToken.value, contains('!== false'));
    });

    test('echo expression handles }} inside double-quoted string', () {
      final lexer = BladeLexer('{{ "hello}}" }}');
      final tokens = lexer.tokenize();

      final exprToken =
          tokens.firstWhere((t) => t.type == TokenType.expression);
      expect(exprToken.value, contains('hello}}'));
    });

    test('echo expression handles }} inside single-quoted string', () {
      final lexer = BladeLexer("{{ 'hello}}' }}");
      final tokens = lexer.tokenize();

      final exprToken =
          tokens.firstWhere((t) => t.type == TokenType.expression);
      expect(exprToken.value, contains("hello}}"));
    });

    test('directive expression handles nested parens in string', () {
      final lexer = BladeLexer(
          "@if(preg_match('/\\(test\\)/', \$str)) hello @endif");
      final tokens = lexer.tokenize();

      final exprToken =
          tokens.firstWhere((t) => t.type == TokenType.expression);
      expect(exprToken.value, contains('preg_match'));
    });
  });

  group('Expression token positions', () {
    test('expression token in echo has correct start position', () {
      final lexer = BladeLexer('{{ \$var }}');
      final tokens = lexer.tokenize();

      final echoOpen =
          tokens.firstWhere((t) => t.type == TokenType.echoOpen);
      final expr =
          tokens.firstWhere((t) => t.type == TokenType.expression);

      expect(expr.startPosition.offset,
          greaterThan(echoOpen.startPosition.offset));
      expect(expr.startPosition.column,
          greaterThan(echoOpen.startPosition.column));
    });

    test('expression token in directive has correct start position', () {
      final lexer = BladeLexer('@if(\$cond)');
      final tokens = lexer.tokenize();

      final directive =
          tokens.firstWhere((t) => t.type == TokenType.directiveIf);
      final expr =
          tokens.firstWhere((t) => t.type == TokenType.expression);

      expect(expr.startPosition.offset,
          greaterThan(directive.startPosition.offset));
    });
  });

  group('Raw text double-backslash escape handling', () {
    test('raw text handles escaped backslash before quote', () {
      final lexer = BladeLexer("<script>var x = 'test\\\\';</script>");
      final tokens = lexer.tokenize();

      final hasClosingTag = tokens.any((t) =>
          t.value.contains('</script>') ||
          t.type == TokenType.htmlClosingTagStart);
      expect(hasClosingTag, isTrue,
          reason: 'Should handle escaped backslash before quote');
    });
  });
}
