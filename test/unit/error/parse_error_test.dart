import 'package:test/test.dart';
import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/error/parse_error.dart';
import 'package:blade_parser/src/error/parse_result.dart';
import 'package:blade_parser/src/lexer/position.dart';

void main() {
  group('ParseError Tests', () {
    test('Create error with all fields', () {
      final error = ParseError(
        message: 'Unexpected token',
        position: Position(line: 5, column: 10, offset: 100),
        severity: ErrorSeverity.error,
        hint: 'Try adding a closing tag',
        sourceContext: '<div>',
      );

      expect(error.message, 'Unexpected token');
      expect(error.position.line, 5);
      expect(error.position.column, 10);
      expect(error.severity, ErrorSeverity.error);
      expect(error.hint, 'Try adding a closing tag');
      expect(error.sourceContext, '<div>');
    });

    test('Create error with minimal fields', () {
      final error = ParseError(
        message: 'Parse error',
        position: Position(line: 1, column: 1, offset: 0),
      );

      expect(error.message, 'Parse error');
      expect(error.severity, ErrorSeverity.error); // Default
      expect(error.hint, isNull);
      expect(error.sourceContext, isNull);
    });

    test('Create warning severity error', () {
      final error = ParseError(
        message: 'Deprecated syntax',
        position: Position(line: 3, column: 5, offset: 50),
        severity: ErrorSeverity.warning,
      );

      expect(error.severity, ErrorSeverity.warning);
    });

    test('toString includes message and position', () {
      final error = ParseError(
        message: 'Missing semicolon',
        position: Position(line: 10, column: 25, offset: 200),
      );

      final str = error.toString();

      expect(str, contains('Missing semicolon'));
      expect(str, contains('line 10'));
      expect(str, contains('column 25'));
      expect(str, contains('error')); // severity
    });

    test('toString includes hint when present', () {
      final error = ParseError(
        message: 'Invalid directive',
        position: Position(line: 2, column: 3, offset: 10),
        hint: 'Did you mean @endif?',
      );

      final str = error.toString();

      expect(str, contains('Invalid directive'));
      expect(str, contains('Hint: Did you mean @endif?'));
    });

    test('toString does not include hint when null', () {
      final error = ParseError(
        message: 'Parse error',
        position: Position(line: 1, column: 1, offset: 0),
      );

      final str = error.toString();

      expect(str, isNot(contains('Hint:')));
    });

    test('Warning severity in toString', () {
      final error = ParseError(
        message: 'Deprecated feature',
        position: Position(line: 5, column: 10, offset: 75),
        severity: ErrorSeverity.warning,
      );

      final str = error.toString();

      expect(str, contains('warning'));
      expect(str, contains('Deprecated feature'));
    });

    test('Error severity in toString', () {
      final error = ParseError(
        message: 'Syntax error',
        position: Position(line: 1, column: 1, offset: 0),
        severity: ErrorSeverity.error,
      );

      final str = error.toString();

      expect(str, contains('error'));
      expect(str, contains('Syntax error'));
    });

    test('Multiple errors with different positions', () {
      final errors = [
        ParseError(
          message: 'Error 1',
          position: Position(line: 1, column: 1, offset: 0),
        ),
        ParseError(
          message: 'Error 2',
          position: Position(line: 5, column: 10, offset: 100),
        ),
        ParseError(
          message: 'Error 3',
          position: Position(line: 10, column: 1, offset: 200),
        ),
      ];

      expect(errors[0].position.line, 1);
      expect(errors[1].position.line, 5);
      expect(errors[2].position.line, 10);
    });

    test('ErrorSeverity enum values', () {
      expect(ErrorSeverity.error, isA<ErrorSeverity>());
      expect(ErrorSeverity.warning, isA<ErrorSeverity>());
      expect(ErrorSeverity.values.length, 2);
    });

    test('Parse error with long message', () {
      final longMessage = 'This is a very long error message ' * 10;
      final error = ParseError(
        message: longMessage,
        position: Position(line: 1, column: 1, offset: 0),
      );

      expect(error.message, longMessage);
      expect(error.toString(), contains(longMessage));
    });

    test('Parse error with special characters in message', () {
      final error = ParseError(
        message: 'Expected "</div>" but got "</ div>"',
        position: Position(line: 1, column: 1, offset: 0),
      );

      expect(error.message, contains('</div>'));
      expect(error.toString(), contains('</div>'));
    });

    test('Parse error with multiline hint', () {
      final error = ParseError(
        message: 'Invalid syntax',
        position: Position(line: 1, column: 1, offset: 0),
        hint: 'Try one of:\n  - @if\n  - @foreach\n  - @while',
      );

      expect(error.hint, contains('\n'));
      final str = error.toString();
      expect(str, contains('Hint:'));
    });
  });

  group('ParseResult Tests', () {
    test('ParseResult with AST and no errors is success', () {
      final result = ParseResult(
        ast: DocumentNode(
          startPosition: Position(line: 1, column: 1, offset: 0),
          endPosition: Position(line: 1, column: 10, offset: 10),
          children: [],
        ),
      );

      expect(result.isSuccess, true);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.ast, isNotNull);
    });

    test('ParseResult with errors is not success', () {
      final result = ParseResult(
        ast: null,
        errors: [
          ParseError(
            message: 'Error',
            position: Position(line: 1, column: 1, offset: 0),
          ),
        ],
      );

      expect(result.isSuccess, false);
      expect(result.errors, hasLength(1));
    });

    test('ParseResult with warnings but no errors is success', () {
      final result = ParseResult(
        ast: DocumentNode(
          startPosition: Position(line: 1, column: 1, offset: 0),
          endPosition: Position(line: 1, column: 10, offset: 10),
          children: [],
        ),
        warnings: [
          ParseError(
            message: 'Warning',
            position: Position(line: 1, column: 1, offset: 0),
            severity: ErrorSeverity.warning,
          ),
        ],
      );

      expect(result.isSuccess, true); // Warnings don't fail
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
    });

    test('ParseResult defaults to empty lists', () {
      final result = ParseResult(ast: null);

      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('ParseResult can have partial AST with errors', () {
      final result = ParseResult(
        ast: DocumentNode(
          startPosition: Position(line: 1, column: 1, offset: 0),
          endPosition: Position(line: 1, column: 10, offset: 10),
          children: [],
        ),
        errors: [
          ParseError(
            message: 'Recoverable error',
            position: Position(line: 1, column: 1, offset: 0),
          ),
        ],
      );

      expect(result.ast, isNotNull); // Partial AST available
      expect(result.isSuccess, false); // But still failed
      expect(result.errors, hasLength(1));
    });
  });
}
