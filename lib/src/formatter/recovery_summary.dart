import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/lexer/position.dart';

/// Summary metadata for a recovery span emitted during formatting.
///
/// Includes the verbatim content (if any), the parser-provided reason,
/// confidence level, and the original source positions so tooling can
/// highlight recovered regions without re-traversing the AST.
final class RecoverySummary {
  final String content;
  final String reason;
  final RecoveryConfidence confidence;
  final Position startPosition;
  final Position endPosition;

  const RecoverySummary({
    required this.content,
    required this.reason,
    required this.confidence,
    required this.startPosition,
    required this.endPosition,
  });
}
