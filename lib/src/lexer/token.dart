import 'package:blade_parser/src/lexer/position.dart';
import 'package:blade_parser/src/lexer/token_type.dart';

/// Represents a lexical token in a Blade template.
class Token {
  final TokenType type;
  final String value;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final int startOffset;
  final int endOffset;

  Token({
    required this.type,
    required this.value,
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
    required this.startOffset,
    required this.endOffset,
  });

  Position get startPosition =>
      Position(line: startLine, column: startColumn, offset: startOffset);

  Position get endPosition =>
      Position(line: endLine, column: endColumn, offset: endOffset);

  @override
  String toString() =>
      'Token($type, "$value", line $startLine:$startColumn-$endLine:$endColumn)';
}
