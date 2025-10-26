import 'package:blade_parser/src/lexer/position.dart';

/// Error severity levels for parse errors.
enum ErrorSeverity {
  /// Critical error that prevents successful parsing.
  error,

  /// Warning that doesn't prevent parsing but indicates potential issues.
  warning,
}

/// Represents a parsing error encountered during Blade template processing.
///
/// Contains information about the error message, position in the source,
/// severity level, and optional hint for fixing the issue.
class ParseError {
  /// The error message describing what went wrong.
  final String message;

  /// The position in the source where the error occurred.
  final Position position;

  /// The severity level of the error (error or warning).
  final ErrorSeverity severity;

  /// Optional hint suggesting how to fix the error.
  final String? hint;

  /// Optional source code context around the error location.
  final String? sourceContext;

  /// Creates a new parse error.
  ///
  /// [message] describes what went wrong.
  /// [position] indicates where in the source the error occurred.
  /// [severity] defaults to [ErrorSeverity.error].
  /// [hint] optionally provides a suggestion for fixing the error.
  /// [sourceContext] optionally includes surrounding source code.
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
      '[$severity] $message at line ${position.line}, column ${position.column}',
    );
    if (hint != null) {
      buffer.write('\nHint: $hint');
    }
    return buffer.toString();
  }
}
