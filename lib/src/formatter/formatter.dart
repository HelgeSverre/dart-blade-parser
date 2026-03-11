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
  /// Best-effort formatting is used when the parser can still produce an AST.
  /// Throws [FormatterException] only when parsing fails so badly that no AST
  /// is available for formatting.
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
    final parsed = _parseForFormatting(source);
    return _formatAst(parsed.ast, source);
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
    final result = formatWithResult(source);
    return result.wasChanged || result.hasErrors;
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
    final parsed = _parseForFormatting(source);
    final ast = parsed.ast;
    final formatted = _formatAst(ast, source);

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
          final newOffset = (pos + relativeOffset).clamp(0, formatted.length);
          return FormatResult(
            formatted: formatted,
            wasChanged: source != formatted,
            hasErrors: parsed.errors.isNotEmpty,
            errors: parsed.errors,
            cursorOffset: newOffset,
          );
        }
      }
    }

    // Default: clamp to formatted length
    return FormatResult(
      formatted: formatted,
      wasChanged: source != formatted,
      hasErrors: parsed.errors.isNotEmpty,
      errors: parsed.errors,
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
  /// Uses best-effort formatting when the parser can still produce an AST.
  FormatResult formatRange(String source, int rangeStart, int rangeEnd) {
    final parsed = _parseForFormatting(source);
    final ast = parsed.ast;
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
        hasErrors: parsed.errors.isNotEmpty,
        errors: parsed.errors,
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

    final formattedSlice = _formatAst(syntheticDoc, source);

    // Splice back into original source
    final formatted = source.substring(0, snappedStart) +
        formattedSlice +
        source.substring(snappedEnd);

    return FormatResult(
      formatted: formatted,
      wasChanged: source != formatted,
      hasErrors: parsed.errors.isNotEmpty,
      errors: parsed.errors,
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
      final parsed = _parseForFormatting(source);
      final formatted = _formatAst(parsed.ast, source);
      final wasChanged = source != formatted;

      return FormatResult(
        formatted: formatted,
        wasChanged: wasChanged,
        hasErrors: parsed.errors.isNotEmpty,
        errors: parsed.errors,
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

  _ParsedFormattingInput _parseForFormatting(String source) {
    final parser = BladeParser();
    final result = parser.parse(source);

    if (result.ast == null) {
      throw FormatterException(
        'Cannot format source because parsing did not produce an AST',
        result.errors,
      );
    }

    return _ParsedFormattingInput(result.ast!, result.errors);
  }

  String _formatAst(DocumentNode ast, String source) {
    final visitor = FormatterVisitor(config, source: source);
    return visitor.format(ast);
  }
}

class _ParsedFormattingInput {
  final DocumentNode ast;
  final List<ParseError> errors;

  const _ParsedFormattingInput(this.ast, this.errors);
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
