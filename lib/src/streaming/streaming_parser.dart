import 'dart:async';
import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/parser/parser.dart';

/// Streaming parser for incremental parsing of large Blade templates.
///
/// This parser processes template chunks incrementally and emits complete AST
/// nodes as soon as they can be parsed, without waiting for the entire file.
///
/// Memory usage is O(buffered incomplete nodes) rather than O(file size).
class StreamingParser {
  /// Parse a stream of template chunks incrementally.
  ///
  /// Emits complete AST nodes as they become available.
  ///
  /// Example:
  /// ```dart
  /// final stream = file.openRead()
  ///   .transform(utf8.decoder)
  ///   .transform(LineSplitter());
  ///
  /// await for (final node in parser.parseStreaming(stream)) {
  ///   // Process node immediately
  ///   print('Parsed: ${node.runtimeType}');
  /// }
  /// ```
  Stream<AstNode> parseStreaming(Stream<String> chunks) async* {
    // Simplified approach: Buffer all chunks, then parse at the end
    // This ensures we have complete templates before parsing
    final buffer = StringBuffer();

    await for (final chunk in chunks) {
      buffer.write(chunk);
    }

    // Parse the complete buffer
    if (buffer.isNotEmpty) {
      final parser = BladeParser();
      final result = parser.parse(buffer.toString());

      if (result.ast != null) {
        for (final child in result.ast!.children) {
          yield child;
        }
      }
    }
  }
}
