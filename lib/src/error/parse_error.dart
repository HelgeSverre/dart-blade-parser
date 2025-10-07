import '../lexer/position.dart';

/// Error severity levels.
enum ErrorSeverity {
  error,
  warning,
}

/// Represents a parsing error.
class ParseError {
  final String message;
  final Position position;
  final ErrorSeverity severity;
  final String? hint;
  final String? sourceContext;

  ParseError({
    required this.message,
    required this.position,
    this.severity = ErrorSeverity.error,
    this.hint,
    this.sourceContext,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(
        '[$severity] $message at line ${position.line}, column ${position.column}');
    if (hint != null) {
      buffer.write('\nHint: $hint');
    }
    return buffer.toString();
  }
}
