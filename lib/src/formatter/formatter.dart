import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/formatter/formatter_visitor.dart';

/// Main formatter class for Blade templates.
///
/// Takes Blade template source code, parses it into an AST, and generates
/// formatted output according to the configured formatting rules.
///
/// Example:
/// ```dart
/// final formatter = BladeFormatter();
/// final formatted = formatter.format('<div>{{ $user->name }}</div>');
/// print(formatted);
/// ```
class BladeFormatter {
  /// The formatting configuration to use.
  final FormatterConfig config;

  /// Creates a new Blade formatter with the given configuration.
  ///
  /// If no configuration is provided, uses [FormatterConfig.defaults].
  BladeFormatter({FormatterConfig? config})
      : config = config ?? FormatterConfig.defaults();

  /// Formats a Blade template source string.
  ///
  /// Returns the formatted source code as a string.
  ///
  /// Throws [FormatterException] if the source contains parse errors.
  ///
  /// Example:
  /// ```dart
  /// final formatter = BladeFormatter();
  /// final formatted = formatter.format('''
  ///   <div>
  ///   @if(\$user)
  ///   <p>{{ \$user->name }}</p>
  ///   @endif
  ///   </div>
  /// ''');
  /// ```
  String format(String source) {
    final parser = BladeParser();
    final result = parser.parse(source);

    // If there are parse errors, we cannot format
    if (!result.isSuccess) {
      throw FormatterException(
        'Cannot format source with parse errors',
        result.errors,
      );
    }

    // Use the visitor to format the AST
    final visitor = FormatterVisitor(config);
    return visitor.format(result.ast!);
  }

  /// Checks if a source string needs formatting.
  ///
  /// Returns `true` if formatting the source would produce different output.
  /// Returns `false` if the source is already formatted correctly.
  ///
  /// This is useful for "check" mode in CLI tools where you want to verify
  /// if files are formatted without modifying them.
  ///
  /// Example:
  /// ```dart
  /// final formatter = BladeFormatter();
  /// if (formatter.needsFormatting(source)) {
  ///   print('File needs formatting');
  /// }
  /// ```
  bool needsFormatting(String source) {
    try {
      final formatted = format(source);
      return source != formatted;
    } on FormatterException {
      // If source has parse errors, consider it as needing formatting
      // (user should fix the errors)
      return true;
    }
  }

  /// Formats source code and returns a [FormatResult].
  ///
  /// This provides more detailed information than [format], including
  /// whether any changes were made and any errors encountered.
  ///
  /// Example:
  /// ```dart
  /// final formatter = BladeFormatter();
  /// final result = formatter.formatWithResult(source);
  ///
  /// if (result.hasErrors) {
  ///   print('Errors: ${result.errors}');
  /// } else if (result.wasChanged) {
  ///   print('Formatted successfully');
  /// } else {
  ///   print('No changes needed');
  /// }
  /// ```
  FormatResult formatWithResult(String source) {
    try {
      final formatted = format(source);
      final wasChanged = source != formatted;

      return FormatResult(
        formatted: formatted,
        wasChanged: wasChanged,
        hasErrors: false,
        errors: const [],
      );
    } on FormatterException catch (e) {
      return FormatResult(
        formatted: source,
        wasChanged: false,
        hasErrors: true,
        errors: e.parseErrors,
      );
    }
  }
}

/// Result of a formatting operation.
///
/// Contains the formatted output and metadata about the formatting process.
class FormatResult {
  /// The formatted source code.
  final String formatted;

  /// Whether the source was changed by formatting.
  final bool wasChanged;

  /// Whether any errors were encountered during formatting.
  final bool hasErrors;

  /// List of parse errors, if any.
  final List<ParseError> errors;

  const FormatResult({
    required this.formatted,
    required this.wasChanged,
    required this.hasErrors,
    required this.errors,
  });

  /// Whether formatting was successful (no errors).
  bool get isSuccess => !hasErrors;
}

/// Exception thrown when formatting fails.
class FormatterException implements Exception {
  /// A description of the formatting error.
  final String message;

  /// Parse errors that caused the formatting to fail.
  final List<ParseError> parseErrors;

  const FormatterException(this.message, this.parseErrors);

  @override
  String toString() {
    final buffer = StringBuffer('FormatterException: $message\n');

    if (parseErrors.isNotEmpty) {
      buffer.writeln('Parse errors:');
      for (final error in parseErrors) {
        buffer.writeln('  - ${error.message} at ${error.position}');
      }
    }

    return buffer.toString();
  }
}
