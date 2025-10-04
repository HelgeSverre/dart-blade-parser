import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Token Contract Tests', () {
    test('Token has all required fields', () {
      final token = Token(
        type: TokenType.text,
        value: 'hello',
        startLine: 1,
        startColumn: 1,
        endLine: 1,
        endColumn: 6,
        startOffset: 0,
        endOffset: 5,
      );

      expect(token.type, equals(TokenType.text));
      expect(token.value, equals('hello'));
      expect(token.startLine, equals(1));
      expect(token.startColumn, equals(1));
      expect(token.endLine, equals(1));
      expect(token.endColumn, equals(6));
      expect(token.startOffset, equals(0));
      expect(token.endOffset, equals(5));
    });

    test('Position validation: line >= 1', () {
      expect(
        () => Position(line: 0, column: 1, offset: 0),
        throwsArgumentError,
      );
      expect(
        () => Position(line: 1, column: 1, offset: 0),
        returnsNormally,
      );
    });

    test('Position validation: column >= 1', () {
      expect(
        () => Position(line: 1, column: 0, offset: 0),
        throwsArgumentError,
      );
      expect(
        () => Position(line: 1, column: 1, offset: 0),
        returnsNormally,
      );
    });

    test('Position validation: offset >= 0', () {
      expect(
        () => Position(line: 1, column: 1, offset: -1),
        throwsArgumentError,
      );
      expect(
        () => Position(line: 1, column: 1, offset: 0),
        returnsNormally,
      );
    });

    test('Token provides startPosition and endPosition', () {
      final token = Token(
        type: TokenType.text,
        value: 'test',
        startLine: 2,
        startColumn: 5,
        endLine: 2,
        endColumn: 9,
        startOffset: 10,
        endOffset: 14,
      );

      expect(token.startPosition.line, equals(2));
      expect(token.startPosition.column, equals(5));
      expect(token.startPosition.offset, equals(10));

      expect(token.endPosition.line, equals(2));
      expect(token.endPosition.column, equals(9));
      expect(token.endPosition.offset, equals(14));
    });

    test('TokenType enum includes essential types', () {
      // Verify key token types exist
      expect(TokenType.directiveIf, isNotNull);
      expect(TokenType.directiveForeach, isNotNull);
      expect(TokenType.echoOpen, isNotNull);
      expect(TokenType.echoClose, isNotNull);
      expect(TokenType.text, isNotNull);
      expect(TokenType.eof, isNotNull);
    });
  });
}
