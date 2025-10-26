import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/error/parse_error.dart';

/// Result of a Blade template parsing operation.
///
/// Contains the parsed AST (if any), along with any errors and warnings
/// encountered during parsing. Even if errors are present, a partial AST
/// may be available for analysis.
class ParseResult {
  /// The parsed abstract syntax tree, or null if parsing failed completely.
  final DocumentNode? ast;

  /// List of errors encountered during parsing.
  final List<ParseError> errors;

  /// List of warnings encountered during parsing.
  final List<ParseError> warnings;

  /// Creates a new parse result.
  ///
  /// [ast] is the parsed document node, if parsing was successful.
  /// [errors] is the list of errors, defaults to empty list.
  /// [warnings] is the list of warnings, defaults to empty list.
  ParseResult({this.ast, List<ParseError>? errors, List<ParseError>? warnings})
      : errors = errors ?? [],
        warnings = warnings ?? [];

  /// Whether parsing was successful (no errors).
  ///
  /// Returns true if [errors] is empty, regardless of warnings.
  bool get isSuccess => errors.isEmpty;
}
