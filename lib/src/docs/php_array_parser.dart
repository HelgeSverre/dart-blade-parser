/// A small recursive descent parser for PHP array literals.
///
/// Parses the expression content from `@props` directives into structured
/// entries. Handles comments, string escapes, nested arrays, and all
/// PHP literal value types.
///
/// Example input: `(['message', 'type' => 'button', 'disabled' => false])`
/// This includes the outer parentheses from the directive expression.
class PhpArrayParser {
  final String _input;
  int _pos = 0;

  PhpArrayParser(this._input);

  /// Parse the input and return array entries.
  List<PhpArrayEntry> parse() {
    _skipWhitespaceAndComments();
    // Skip outer parens if present
    if (_peek() == '(') _advance();
    _skipWhitespaceAndComments();
    if (_peek() == '[') {
      return _parseArray();
    }
    return [];
  }

  List<PhpArrayEntry> _parseArray() {
    _advance(); // [
    final entries = <PhpArrayEntry>[];

    while (!_isAtEnd()) {
      _skipWhitespaceAndComments();
      if (_isAtEnd() || _peek() == ']') {
        if (!_isAtEnd()) _advance();
        break;
      }

      final value = _parseValue();
      _skipWhitespaceAndComments();

      if (_peek() == '=' && _peekAt(1) == '>') {
        // key => value pair
        _advance(); // =
        _advance(); // >
        _skipWhitespaceAndComments();
        final key = value is PhpString ? value.value : value.toString();
        final entryValue = _parseValue();
        entries.add(PhpArrayEntry(key: key, value: entryValue));
      } else {
        // Standalone value (e.g. required prop)
        entries.add(PhpArrayEntry(value: value));
      }

      _skipWhitespaceAndComments();
      if (_peek() == ',') _advance();
    }

    return entries;
  }

  PhpValue _parseValue() {
    _skipWhitespaceAndComments();
    final ch = _peek();

    if (ch == "'" || ch == '"') return _parseString();
    if (ch == '[') return PhpArray(_parseArray());
    if (ch == '-' || _isDigit(ch)) return _parseNumber();

    // Keywords
    if (_matchWord('true')) return PhpBool(true);
    if (_matchWord('false')) return PhpBool(false);
    if (_matchWord('null')) return PhpNull();

    // Fallback: consume until delimiter
    final start = _pos;
    while (!_isAtEnd() && !',]=>'.contains(_peek())) {
      _advance();
    }
    return PhpString(_input.substring(start, _pos).trim());
  }

  PhpString _parseString() {
    final quote = _advance();
    final buffer = StringBuffer();

    while (!_isAtEnd() && _peek() != quote) {
      if (_peek() == '\\') {
        _advance(); // backslash
        if (!_isAtEnd()) {
          final escaped = _advance();
          switch (escaped) {
            case 'n':
              buffer.write('\n');
            case 't':
              buffer.write('\t');
            case 'r':
              buffer.write('\r');
            default:
              buffer.write(escaped);
          }
        }
      } else {
        buffer.write(_advance());
      }
    }
    if (!_isAtEnd()) _advance(); // closing quote
    return PhpString(buffer.toString());
  }

  PhpNumber _parseNumber() {
    final start = _pos;
    if (_peek() == '-') _advance();
    while (!_isAtEnd() && _isDigit(_peek())) {
      _advance();
    }
    if (!_isAtEnd() && _peek() == '.' && _isDigit(_peekAt(1))) {
      _advance(); // .
      while (!_isAtEnd() && _isDigit(_peek())) {
        _advance();
      }
      return PhpNumber(double.parse(_input.substring(start, _pos)));
    }
    return PhpNumber(int.parse(_input.substring(start, _pos)));
  }

  void _skipWhitespaceAndComments() {
    while (!_isAtEnd()) {
      final ch = _peek();
      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        _advance();
      } else if (ch == '/' && _peekAt(1) == '/') {
        // Line comment — skip to end of line
        while (!_isAtEnd() && _peek() != '\n') {
          _advance();
        }
      } else if (ch == '/' && _peekAt(1) == '*') {
        // Block comment — skip to */
        _advance(); // /
        _advance(); // *
        while (!_isAtEnd()) {
          if (_peek() == '*' && _peekAt(1) == '/') {
            _advance(); // *
            _advance(); // /
            break;
          }
          _advance();
        }
      } else {
        break;
      }
    }
  }

  bool _matchWord(String word) {
    if (_pos + word.length > _input.length) return false;
    if (_input.substring(_pos, _pos + word.length) != word) return false;
    // Ensure it's not a prefix of a longer identifier
    if (_pos + word.length < _input.length &&
        _isAlphaNumeric(_input[_pos + word.length])) {
      return false;
    }
    _pos += word.length;
    return true;
  }

  // --- Character helpers ---

  bool _isAtEnd() => _pos >= _input.length;

  String _peek() => _isAtEnd() ? '\x00' : _input[_pos];

  String _peekAt(int offset) {
    final i = _pos + offset;
    return i >= _input.length ? '\x00' : _input[i];
  }

  String _advance() {
    if (_isAtEnd()) return '\x00';
    return _input[_pos++];
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  bool _isAlphaNumeric(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 48 && c <= 57) || // 0-9
        (c >= 65 && c <= 90) || // A-Z
        (c >= 97 && c <= 122) || // a-z
        c == 95; // _
  }
}

/// A single entry in a PHP array literal.
class PhpArrayEntry {
  /// The key, or null for positional entries.
  final String? key;

  /// The value.
  final PhpValue value;

  PhpArrayEntry({this.key, required this.value});
}

/// Base class for PHP literal values.
sealed class PhpValue {}

/// A string literal.
class PhpString extends PhpValue {
  final String value;
  PhpString(this.value);

  @override
  String toString() => value;
}

/// A numeric literal (int or double).
class PhpNumber extends PhpValue {
  final num value;
  PhpNumber(this.value);

  @override
  String toString() => value.toString();
}

/// A boolean literal.
class PhpBool extends PhpValue {
  final bool value;
  PhpBool(this.value);

  @override
  String toString() => value.toString();
}

/// A null literal.
class PhpNull extends PhpValue {
  @override
  String toString() => 'null';
}

/// A nested array literal.
class PhpArray extends PhpValue {
  final List<PhpArrayEntry> entries;
  PhpArray(this.entries);

  @override
  String toString() => '[${entries.length} entries]';
}
