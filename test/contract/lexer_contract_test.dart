import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Lexer Contract Tests', () {
    test('tokenize returns List<Token>', () {
      final lexer = BladeLexer('{{ \$test }}');
      final tokens = lexer.tokenize();

      expect(tokens, isA<List<Token>>());
    });

    test('tokenize always includes EOF token as last', () {
      final lexer = BladeLexer('hello');
      final tokens = lexer.tokenize();

      expect(tokens.isNotEmpty, isTrue);
      expect(tokens.last.type, equals(TokenType.eof));
    });

    test('all tokens have position information', () {
      final lexer = BladeLexer('test');
      final tokens = lexer.tokenize();

      for (final token in tokens) {
        expect(token.startLine, greaterThanOrEqualTo(1));
        expect(token.startColumn, greaterThanOrEqualTo(1));
        expect(token.startOffset, greaterThanOrEqualTo(0));
      }
    });

    test('handles UTF-8 correctly', () {
      final lexer = BladeLexer('{{ "你好 Héllo" }}');
      final tokens = lexer.tokenize();

      // Should not throw and should produce tokens
      expect(tokens, isNotEmpty);
      expect(tokens.last.type, equals(TokenType.eof));
    });

    test('handles LF line endings', () {
      final lexer = BladeLexer('line1\nline2');
      final tokens = lexer.tokenize();

      expect(tokens, isNotEmpty);
      expect(tokens.last.type, equals(TokenType.eof));
    });

    test('handles CRLF line endings', () {
      final lexer = BladeLexer('line1\r\nline2');
      final tokens = lexer.tokenize();

      expect(tokens, isNotEmpty);
      expect(tokens.last.type, equals(TokenType.eof));
    });
  });
}
