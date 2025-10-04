import '../ast/node.dart';
import '../error/parse_error.dart';
import '../error/parse_result.dart';
import '../lexer/lexer.dart';
import '../lexer/position.dart';
import '../lexer/token.dart';
import '../lexer/token_type.dart';

/// Parser for Blade templates using recursive descent.
class BladeParser {
  List<Token> _tokens = [];
  int _current = 0;
  final List<ParseError> _errors = [];

  /// Parse a Blade template string.
  ParseResult parse(String source) {
    final lexer = BladeLexer(source);
    _tokens = lexer.tokenize();
    _current = 0;
    _errors.clear();

    final children = <AstNode>[];

    while (!_isAtEnd()) {
      try {
        final node = _parseNode();
        if (node != null) {
          children.add(node);
        }
      } catch (e) {
        _errors.add(ParseError(
          message: e.toString(),
          position: _peek().startPosition,
        ));
        _synchronize();
      }
    }

    final doc = DocumentNode(
      startPosition: Position(line: 1, column: 1, offset: 0),
      endPosition: _tokens.isEmpty
          ? Position(line: 1, column: 1, offset: 0)
          : _previous().endPosition,
      children: children,
    );

    return ParseResult(
      ast: doc,
      errors: List.unmodifiable(_errors),
    );
  }

  /// Parse a stream (stub for now).
  Stream<AstNode> parseStreaming(Stream<String> chunks) async* {
    // Stub implementation
    final buffer = StringBuffer();
    await for (final chunk in chunks) {
      buffer.write(chunk);
    }

    final result = parse(buffer.toString());
    if (result.ast != null) {
      for (final child in result.ast!.children) {
        yield child;
      }
    }
  }

  AstNode? _parseNode() {
    final token = _peek();

    switch (token.type) {
      // Control flow directives
      case TokenType.directiveIf:
        return _parseIfDirective();
      case TokenType.directiveForeach:
        return _parseForeachDirective();
      case TokenType.directiveFor:
        return _parseForDirective();
      case TokenType.directiveWhile:
        return _parseWhileDirective();

      // Echo statements
      case TokenType.echoOpen:
        return _parseEcho();
      case TokenType.rawEchoOpen:
        return _parseRawEcho();

      // Text and comments
      case TokenType.text:
        return _parseText();
      case TokenType.bladeComment:
        _advance(); // Skip comments
        return null;
      case TokenType.eof:
        _advance(); // Advance past EOF to terminate loop
        return null;
      default:
        _advance();
        return null;
    }
  }

  DirectiveNode _parseIfDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_checkAny([TokenType.directiveEndif, TokenType.directiveElse, TokenType.directiveElseif, TokenType.eof])) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    // Handle @else or @elseif
    if (_check(TokenType.directiveElse) || _check(TokenType.directiveElseif)) {
      _advance();
      while (!_check(TokenType.directiveEndif) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) children.add(node);
      }
    }

    if (!_check(TokenType.directiveEndif)) {
      _errors.add(ParseError(
        message: 'Unclosed @if directive starting at line ${startToken.startLine}',
        position: startToken.startPosition,
        hint: 'Add @endif to close the conditional block',
      ));
    } else {
      _advance();
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'if',
      expression: expression,
      children: children,
    );
  }

  DirectiveNode _parseForeachDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(TokenType.directiveEndforeach) && !_check(TokenType.eof)) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    if (!_check(TokenType.directiveEndforeach)) {
      _errors.add(ParseError(
        message: 'Unclosed @foreach directive',
        position: startToken.startPosition,
        hint: 'Add @endforeach to close the loop',
      ));
    } else {
      _advance();
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'foreach',
      expression: expression,
      children: children,
    );
  }

  DirectiveNode _parseForDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(TokenType.directiveEndfor) && !_check(TokenType.eof)) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    if (!_check(TokenType.directiveEndfor)) {
      _errors.add(ParseError(
        message: 'Unclosed @for directive',
        position: startToken.startPosition,
        hint: 'Add @endfor to close the loop',
      ));
    } else {
      _advance();
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'for',
      expression: expression,
      children: children,
    );
  }

  DirectiveNode _parseWhileDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(TokenType.directiveEndwhile) && !_check(TokenType.eof)) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    if (!_check(TokenType.directiveEndwhile)) {
      _errors.add(ParseError(
        message: 'Unclosed @while directive',
        position: startToken.startPosition,
        hint: 'Add @endwhile to close the loop',
      ));
    } else {
      _advance();
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'while',
      expression: expression,
      children: children,
    );
  }

  String? _extractExpression() {
    if (_check(TokenType.expression)) {
      return _advance().value.trim();
    }
    return null;
  }


  EchoNode _parseEcho() {
    final openToken = _advance(); // {{

    String expression = '';
    if (_check(TokenType.expression)) {
      expression = _advance().value;
    }

    if (!_check(TokenType.echoClose)) {
      _errors.add(ParseError(
        message: 'Unclosed echo statement',
        position: openToken.startPosition,
      ));
    } else {
      _advance(); // }}
    }

    return EchoNode(
      startPosition: openToken.startPosition,
      endPosition: _previous().endPosition,
      expression: expression.trim(),
      isRaw: false,
    );
  }

  EchoNode _parseRawEcho() {
    final openToken = _advance(); // {!!

    String expression = '';
    if (_check(TokenType.expression)) {
      expression = _advance().value;
    }

    if (!_check(TokenType.rawEchoClose)) {
      _errors.add(ParseError(
        message: 'Unclosed raw echo statement',
        position: openToken.startPosition,
      ));
    } else {
      _advance(); // !!}
    }

    return EchoNode(
      startPosition: openToken.startPosition,
      endPosition: _previous().endPosition,
      expression: expression.trim(),
      isRaw: true,
    );
  }

  TextNode _parseText() {
    final token = _advance();
    return TextNode(
      startPosition: token.startPosition,
      endPosition: token.endPosition,
      content: token.value,
    );
  }

  void _synchronize() {
    while (!_isAtEnd()) {
      if (_check(TokenType.directiveIf) ||
          _check(TokenType.directiveForeach) ||
          _check(TokenType.eof)) {
        return;
      }
      _advance();
    }
  }

  // Token navigation helpers

  bool _isAtEnd() => _current >= _tokens.length;

  Token _peek() {
    if (_isAtEnd()) {
      return _tokens.isNotEmpty ? _tokens.last : Token(
        type: TokenType.eof,
        value: '',
        startLine: 1,
        startColumn: 1,
        endLine: 1,
        endColumn: 1,
        startOffset: 0,
        endOffset: 0,
      );
    }
    return _tokens[_current];
  }

  Token _previous() => _tokens[_current - 1];

  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  bool _check(TokenType type) => !_isAtEnd() && _peek().type == type;

  bool _checkAny(List<TokenType> types) => types.any(_check);
}
