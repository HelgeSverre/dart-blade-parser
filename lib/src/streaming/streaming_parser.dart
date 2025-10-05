import 'dart:async';
import '../ast/node.dart';
import '../parser/parser.dart';

/// Streaming parser for incremental parsing of large Blade templates.
///
/// This parser processes template chunks incrementally and emits complete AST
/// nodes as soon as they can be parsed, without waiting for the entire file.
///
/// Memory usage is O(buffered incomplete nodes) rather than O(file size).
class StreamingParser {
  final BladeParser _parser = BladeParser();
  final StringBuffer _buffer = StringBuffer();
  final List<AstNode> _incompleteNodes = [];

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
    await for (final chunk in chunks) {
      _buffer.write(chunk);

      // Try to parse buffered content
      final content = _buffer.toString();
      final result = _parser.parse(content);

      if (result.isSuccess && result.ast != null) {
        // Emit all complete nodes
        for (final child in result.ast!.children) {
          if (_isCompleteNode(child)) {
            yield child;
          } else {
            // Buffer incomplete nodes for next iteration
            _incompleteNodes.add(child);
          }
        }

        // Clear buffer after successful parse
        _buffer.clear();
      }
    }

    // Flush remaining buffered content
    if (_buffer.isNotEmpty) {
      final result = _parser.parse(_buffer.toString());
      if (result.ast != null) {
        for (final child in result.ast!.children) {
          yield child;
        }
      }
    }

    // Emit any incomplete nodes that couldn't be completed
    for (final node in _incompleteNodes) {
      yield node;
    }
  }

  /// Check if a node is complete (has no unclosed directives/components).
  bool _isCompleteNode(AstNode node) {
    if (node is DirectiveNode) {
      // Directives with children need closing tags (if, foreach, while, etc.)
      // Directives without children are complete (csrf, json, etc.)
      final needsClosing = _directiveNeedsClosing(node.name);
      if (needsClosing) {
        // Check if all children are complete
        return node.children.every(_isCompleteNode);
      }
      return true;
    }

    if (node is ComponentNode) {
      // Self-closing components are always complete
      // Regular components need all children to be complete
      return node.isSelfClosing || node.children.every(_isCompleteNode);
    }

    // Text and echo nodes are always complete
    return true;
  }

  /// Check if a directive requires a closing tag.
  bool _directiveNeedsClosing(String name) {
    const closingDirectives = {
      'if', 'foreach', 'for', 'while', 'switch', 'unless',
      'section', 'component', 'slot', 'push', 'prepend',
      'once', 'auth', 'guest', 'env', 'production', 'error',
      'can', 'cannot', 'canany', 'php', 'verbatim'
    };
    return closingDirectives.contains(name);
  }
}
