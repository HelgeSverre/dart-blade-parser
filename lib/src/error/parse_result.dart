import '../ast/node.dart';
import 'parse_error.dart';

/// Result of parsing operation.
class ParseResult {
  final DocumentNode? ast;
  final List<ParseError> errors;
  final List<ParseError> warnings;

  ParseResult({
    this.ast,
    List<ParseError>? errors,
    List<ParseError>? warnings,
  })  : errors = errors ?? [],
        warnings = warnings ?? [];

  bool get isSuccess => errors.isEmpty;
}
