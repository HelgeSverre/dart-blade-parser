import '../lexer/token.dart';
import '../lexer/token_type.dart';

/// Pratt parser for PHP expressions within Blade templates.
///
/// Implements operator precedence parsing using the Pratt parsing algorithm.
/// This handles binary operators, unary operators, ternary operators, and
/// function calls with correct precedence.
class ExpressionParser {
  final List<Token> _tokens;
  int _current = 0;

  ExpressionParser(this._tokens);

  /// Parse an expression from tokens.
  String parse() {
    return _parseExpression(0);
  }

  /// Parse expression with minimum binding power.
  String _parseExpression(int minBindingPower) {
    String left = _parsePrimary();

    while (!_isAtEnd() && _getBindingPower(_peek()) > minBindingPower) {
      final operator = _advance();

      if (operator.type == TokenType.identifier && operator.value == '?') {
        // Ternary operator
        final trueExpr = _parseExpression(0);
        _consume(TokenType.identifier, ':'); // Expect ':'
        final falseExpr = _parseExpression(0);
        left = '$left ? $trueExpr : $falseExpr';
      } else {
        // Binary operator
        final right = _parseExpression(_getBindingPower(operator));
        left = '$left ${operator.value} $right';
      }
    }

    return left;
  }

  /// Parse primary expressions (literals, variables, function calls, parentheses).
  String _parsePrimary() {
    final token = _peek();

    // Handle unary operators
    if (token.value == '!' ||
        token.value == '-' ||
        token.value == '+' ||
        token.value == '~') {
      final op = _advance();
      final expr = _parsePrimary();
      return '${op.value}$expr';
    }

    // Variable
    if (token.value.startsWith('\$')) {
      return _parseVariable();
    }

    // String literal
    if (token.type == TokenType.stringLiteral ||
        token.value.startsWith("'") ||
        token.value.startsWith('"')) {
      return _advance().value;
    }

    // Number literal
    if (token.type == TokenType.numberLiteral ||
        RegExp(r'^\d').hasMatch(token.value)) {
      return _advance().value;
    }

    // Function call or identifier
    if (token.type == TokenType.identifier && !_isOperator(token.value)) {
      final name = _advance().value;

      if (!_isAtEnd() && _peek().value == '(') {
        return _parseFunctionCall(name);
      }

      return name;
    }

    // Parenthesized expression
    if (token.value == '(') {
      _advance(); // consume '('
      final expr = _parseExpression(0);
      _consume(TokenType.identifier, ')');
      return '($expr)';
    }

    // Array literal
    if (token.value == '[') {
      return _parseArray();
    }

    // Boolean literals
    if (token.value == 'true' || token.value == 'false') {
      return _advance().value;
    }

    // Null literal
    if (token.value == 'null') {
      return _advance().value;
    }

    // If nothing matches, consume the token and return it
    return _advance().value;
  }

  /// Parse variable with property/method access.
  String _parseVariable() {
    String result = _advance().value; // $variable

    while (!_isAtEnd()) {
      final next = _peek();

      if (next.value == '->') {
        _advance(); // consume '->'
        final property = _advance().value;

        // Check for method call
        if (!_isAtEnd() && _peek().value == '(') {
          final call = _parseFunctionCall(property);
          result = '$result->$call';
        } else {
          result = '$result->$property';
        }
      } else if (next.value == '[') {
        // Array access
        _advance(); // consume '['
        final index = _parseExpression(0);
        _consume(TokenType.identifier, ']');
        result = '$result[$index]';
      } else {
        break;
      }
    }

    return result;
  }

  /// Parse function call.
  String _parseFunctionCall(String name) {
    _advance(); // consume '('

    final args = <String>[];
    while (!_isAtEnd() && _peek().value != ')') {
      args.add(_parseExpression(0));

      if (!_isAtEnd() && _peek().value == ',') {
        _advance(); // consume ','
      }
    }

    _consume(TokenType.identifier, ')');
    return '$name(${args.join(', ')})';
  }

  /// Parse array literal.
  String _parseArray() {
    _advance(); // consume '['

    final elements = <String>[];
    while (!_isAtEnd() && _peek().value != ']') {
      elements.add(_parseExpression(0));

      if (!_isAtEnd() && _peek().value == ',') {
        _advance(); // consume ','
      }
    }

    _consume(TokenType.identifier, ']');
    return '[${elements.join(', ')}]';
  }

  /// Get binding power for operator (precedence).
  int _getBindingPower(Token token) {
    final op = token.value;

    // Precedence levels (higher = tighter binding)
    switch (op) {
      case '||':
      case 'or':
        return 10;
      case '&&':
      case 'and':
        return 20;
      case '|':
        return 30;
      case '^':
        return 40;
      case '&':
        return 50;
      case '==':
      case '!=':
      case '===':
      case '!==':
        return 60;
      case '<':
      case '<=':
      case '>':
      case '>=':
      case '<=>':
        return 70;
      case '<<':
      case '>>':
        return 80;
      case '+':
      case '-':
      case '.':
        return 90;
      case '*':
      case '/':
      case '%':
        return 100;
      case '**':
        return 110;
      case '?':
        return 5; // Ternary has low precedence
      default:
        return 0;
    }
  }

  /// Check if value is an operator.
  bool _isOperator(String value) {
    return [
      '+',
      '-',
      '*',
      '/',
      '%',
      '**',
      '==',
      '!=',
      '===',
      '!==',
      '<',
      '<=',
      '>',
      '>=',
      '<=>',
      '&&',
      '||',
      'and',
      'or',
      '!',
      '&',
      '|',
      '^',
      '~',
      '<<',
      '>>',
      '.',
      '?',
      ':'
    ].contains(value);
  }

  /// Consume expected token, throwing if not found.
  void _consume(TokenType type, String value) {
    if (_isAtEnd()) {
      throw FormatException('Expected "$value" but reached end of expression');
    }
    if (_peek().value != value) {
      throw FormatException('Expected "$value" but got "${_peek().value}"');
    }
    _advance();
  }

  /// Check if at end of tokens.
  bool _isAtEnd() => _current >= _tokens.length;

  /// Peek at current token.
  Token _peek() {
    if (_isAtEnd()) {
      return Token(
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

  /// Advance to next token.
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _tokens[_current - 1];
  }
}
