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
    // Pass the original source for ignore comment support
    final visitor = FormatterVisitor(config, source: source);
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

  /// Unique marker used for cursor tracking.
  ///
  /// This marker is inserted at the cursor position before parsing,
  /// survives formatting as part of text content, and is then removed
  /// to determine the new cursor position.
  static const _cursorMarker = '\u200B\u200B\u200B';

  /// Formats a Blade template and tracks the cursor position.
  ///
  /// Inserts a marker at [cursorOffset], formats the source, then locates
  /// the marker in the output to determine the new cursor position.
  ///
  /// If the marker interferes with parsing, falls back to an AST-based
  /// approach that maps the cursor to the nearest node boundary.
  ///
  /// Returns a [FormatResult] with the new [FormatResult.cursorOffset].
  FormatResult formatWithCursor(String source, int cursorOffset) {
    final clampedOffset = cursorOffset.clamp(0, source.length);

    // Try marker-based approach first
    final markedSource = source.substring(0, clampedOffset) +
        _cursorMarker +
        source.substring(clampedOffset);

    final parser = BladeParser();
    final parseResult = parser.parse(markedSource);

    if (parseResult.isSuccess) {
      final visitor = FormatterVisitor(config, source: markedSource);
      final formatted = visitor.format(parseResult.ast!);
      final markerPos = formatted.indexOf(_cursorMarker);

      if (markerPos >= 0) {
        final cleanFormatted = formatted.replaceFirst(_cursorMarker, '');

        // Verify the marker didn't corrupt formatting by comparing
        // with a clean format (no marker). If they differ, the marker
        // affected parsing/formatting — fall back to AST approach.
        final cleanFormat = format(source);
        if (cleanFormatted == cleanFormat) {
          return FormatResult(
            formatted: cleanFormatted,
            wasChanged: source != cleanFormatted,
            hasErrors: false,
            errors: const [],
            cursorOffset: markerPos,
          );
        }
      }
    }

    // Fallback: AST-based approach
    return _formatWithCursorFallback(source, clampedOffset);
  }

  /// AST-based cursor tracking fallback.
  ///
  /// Parses without a marker, formats, then maps the cursor offset to the
  /// nearest node boundary in the formatted output.
  FormatResult _formatWithCursorFallback(String source, int cursorOffset) {
    final parser = BladeParser();
    final parseResult = parser.parse(source);

    if (!parseResult.isSuccess) {
      throw FormatterException(
        'Cannot format source with parse errors',
        parseResult.errors,
      );
    }

    final ast = parseResult.ast!;
    final visitor = FormatterVisitor(config, source: source);
    final formatted = visitor.format(ast);

    // Find the node containing the cursor
    final node = _findNodeAtOffset(ast.children, cursorOffset);

    if (node != null && node is TextNode) {
      // Compute relative position within the text node
      final relativeOffset = cursorOffset - node.startPosition.offset;
      // Find this text node's content in the formatted output
      final formattedContent = node.content.trim();
      if (formattedContent.isNotEmpty) {
        final pos = formatted.indexOf(formattedContent);
        if (pos >= 0) {
          final newOffset =
              (pos + relativeOffset).clamp(0, formatted.length);
          return FormatResult(
            formatted: formatted,
            wasChanged: source != formatted,
            hasErrors: false,
            errors: const [],
            cursorOffset: newOffset,
          );
        }
      }
    }

    // Default: clamp to formatted length
    return FormatResult(
      formatted: formatted,
      wasChanged: source != formatted,
      hasErrors: false,
      errors: const [],
      cursorOffset: cursorOffset.clamp(0, formatted.length),
    );
  }

  /// Finds the deepest AST node containing [offset].
  AstNode? _findNodeAtOffset(List<AstNode> nodes, int offset) {
    for (final node in nodes) {
      final start = node.startPosition.offset;
      final end = node.endPosition.offset;

      if (offset >= start && offset <= end) {
        // Try to find a deeper child
        final child = _findNodeAtOffset(node.children, offset);
        return child ?? node;
      }
    }
    return null;
  }

  /// Formats only the nodes overlapping with the given range.
  ///
  /// Parses the full document, finds top-level nodes that overlap with
  /// [rangeStart]..[rangeEnd], snaps the range to node boundaries, formats
  /// those nodes, and splices the result back into the original source.
  ///
  /// Throws [FormatterException] if the source contains parse errors.
  FormatResult formatRange(String source, int rangeStart, int rangeEnd) {
    final parser = BladeParser();
    final result = parser.parse(source);

    if (!result.isSuccess) {
      throw FormatterException(
        'Cannot format source with parse errors',
        result.errors,
      );
    }

    final ast = result.ast!;
    final children = ast.children;

    // Find top-level children overlapping [rangeStart, rangeEnd]
    final overlapping = <AstNode>[];
    for (final child in children) {
      final nodeStart = child.startPosition.offset;
      final nodeEnd = child.endPosition.offset;

      // Node overlaps range if: nodeStart < rangeEnd && nodeEnd > rangeStart
      if (nodeStart < rangeEnd && nodeEnd > rangeStart) {
        overlapping.add(child);
      }
    }

    if (overlapping.isEmpty) {
      // No nodes overlap; return source unchanged
      return FormatResult(
        formatted: source,
        wasChanged: false,
        hasErrors: false,
        errors: const [],
      );
    }

    // Snap range to node boundaries
    final snappedStart = overlapping.first.startPosition.offset;
    final snappedEnd = overlapping.last.endPosition.offset;

    // Build a synthetic document containing only the overlapping nodes
    final syntheticDoc = DocumentNode(
      startPosition: overlapping.first.startPosition,
      endPosition: overlapping.last.endPosition,
      children: overlapping,
    );

    final visitor = FormatterVisitor(config, source: source);
    final formattedSlice = visitor.format(syntheticDoc);

    // Splice back into original source
    final formatted = source.substring(0, snappedStart) +
        formattedSlice +
        source.substring(snappedEnd);

    return FormatResult(
      formatted: formatted,
      wasChanged: source != formatted,
      hasErrors: false,
      errors: const [],
    );
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

  /// The cursor offset in the formatted output, or -1 if not tracked.
  final int cursorOffset;

  const FormatResult({
    required this.formatted,
    required this.wasChanged,
    required this.hasErrors,
    required this.errors,
    this.cursorOffset = -1,
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
