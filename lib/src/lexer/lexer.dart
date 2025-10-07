import 'token.dart';
import 'token_type.dart';

/// State enum for iterative lexing (no recursion)
enum _LexerState {
  text,
  directiveOrComment,
  bladeComment,
  echo,
  rawEcho,
  legacyEcho,
  verbatim,
  componentTag,
  htmlTag,
  done,
}

/// Lexer for Blade templates using iterative state machine.
/// Converts from recursive Rob Pike pattern to iterative loop to prevent stack overflow.
class BladeLexer {
  final String input;
  int _position = 0;
  int _start = 0;
  int _line = 1;
  int _column = 1;
  int _startLine = 1;
  int _startColumn = 1;
  final List<Token> _tokens = [];

  // Verbatim mode tracking
  bool _inVerbatim = false;

  BladeLexer(this.input);

  /// Tokenize the input string into a list of tokens.
  List<Token> tokenize() {
    _tokens.clear();
    _position = 0;
    _start = 0;
    _line = 1;
    _column = 1;
    _inVerbatim = false;

    // Iterative state machine - prevents stack overflow
    var state = _LexerState.text;
    while (state != _LexerState.done) {
      switch (state) {
        case _LexerState.text:
          state = _lexText();
          break;
        case _LexerState.directiveOrComment:
          state = _lexDirectiveOrComment();
          break;
        case _LexerState.bladeComment:
          state = _lexBladeComment();
          break;
        case _LexerState.echo:
          state = _lexEcho();
          break;
        case _LexerState.rawEcho:
          state = _lexRawEcho();
          break;
        case _LexerState.legacyEcho:
          state = _lexLegacyEcho();
          break;
        case _LexerState.verbatim:
          state = _lexVerbatim();
          break;
        case _LexerState.componentTag:
          state = _lexComponentTag();
          break;
        case _LexerState.htmlTag:
          state = _lexHtmlTag();
          break;
        case _LexerState.done:
          break;
      }
    }

    return List.unmodifiable(_tokens);
  }

  /// Main text lexing state
  _LexerState _lexText() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    while (!_isAtEnd()) {
      final ch = _peek();

      // In verbatim mode, only look for @endverbatim
      if (_inVerbatim) {
        if (ch == '@') {
          // Check if next chars are "endverbatim"
          final remainingLength = input.length - _position - 1;
          if (remainingLength >= 11 &&
              input.substring(_position + 1, _position + 12) == 'endverbatim') {
            // Emit accumulated text before @endverbatim
            if (_position > _start) {
              _emitToken(TokenType.text, input.substring(_start, _position));
            }
            // Reset _start for the directive itself
            _start = _position;
            _startLine = _line;
            _startColumn = _column;
            return _LexerState.directiveOrComment;
          }
        }
        _advance();
        continue;
      }

      // Check for @ directive
      if (ch == '@') {
        // Check for @{{ (escaped echo - treat as literal text)
        if (_peekNext() == '{' && _peekAhead(2) == '{') {
          // This is an escaped echo, skip @ and continue as text
          _advance();
          continue;
        }

        // Disambiguate: directive vs email vs Alpine.js @event
        if (_isDirectiveContext()) {
          if (_position > _start) {
            _emitToken(TokenType.text, input.substring(_start, _position));
          }
          return _LexerState.directiveOrComment;
        }
      }

      // Check for {{-- Blade comment
      if (ch == '{' &&
          _peekNext() == '{' &&
          _peekAhead(2) == '-' &&
          _peekAhead(3) == '-') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.bladeComment;
      }

      // Check for {{ echo
      // Check for {{{ legacy echo (must check before {{ regular echo)
      if (ch == '{' && _peekNext() == '{' && _peekAhead(2) == '{') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.legacyEcho;
      }

      if (ch == '{' && _peekNext() == '{') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.echo;
      }

      // Check for {!! raw echo
      if (ch == '{' && _peekNext() == '!' && _peekAhead(2) == '!') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.rawEcho;
      }

      // Check for </x- component closing tag
      if (ch == '<' &&
          _peekNext() == '/' &&
          _peekAhead(2) == 'x' &&
          _peekAhead(3) == '-') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        // Scan closing tag
        _advance(); // <
        _advance(); // /
        _advance(); // x
        _advance(); // -

        final nameStart = _position;
        while (_isAlphaNumeric(_peek()) || _peek() == '-' || _peek() == '.') {
          _advance();
        }

        final componentName = input.substring(nameStart, _position);
        _emitToken(TokenType.componentTagClose, '</x-$componentName');

        // Skip to >
        while (!_isAtEnd() && _peek() != '>') {
          _advance();
        }
        if (_peek() == '>') {
          _advance();
          // Don't emit the > as text - it's part of the component tag structure
        }

        _start = _position;
        continue;
      }

      // Check for <x- component tag
      if (ch == '<' && _peekNext() == 'x' && _peekAhead(2) == '-') {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.componentTag;
      }

      // Check for HTML closing tags </ (before opening tags)
      if (ch == '<' && _peekNext() == '/' && _isAlpha(_peekAhead(2))) {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.htmlTag;
      }

      // Check for invalid tag names (e.g., <123>)
      if (ch == '<' && _isDigit(_peekNext())) {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        // Emit error and skip past the invalid tag
        _start = _position;
        _startLine = _line;
        _startColumn = _column;
        _advance(); // <
        while (!_isAtEnd() && _peek() != '>') {
          _advance();
        }
        if (_peek() == '>') {
          _advance();
        }
        _emitToken(TokenType.error, 'Invalid tag name');
        _start = _position;
        continue;
      }

      // Check for regular HTML tags (to parse attributes with Alpine.js/Livewire)
      if (ch == '<' && _isAlpha(_peekNext())) {
        if (_position > _start) {
          _emitToken(TokenType.text, input.substring(_start, _position));
        }
        return _LexerState.htmlTag;
      }

      _advance();
    }

    // Emit remaining text
    if (_position > _start) {
      _emitToken(TokenType.text, input.substring(_start, _position));
    }

    // Emit EOF
    _emitToken(TokenType.eof, '');
    return _LexerState.done;
  }

  /// Check if @ is in directive context (vs email or Alpine.js @event)
  bool _isDirectiveContext() {
    // @ at start of input -> likely directive
    if (_position == 0) return true;

    final prev = _position > 0 ? input[_position - 1] : '\x00';

    // @ preceded by alphanumeric or dot = likely email address or domain
    if (_isAlphaNumeric(prev) || prev == '.') {
      return false; // Email address like user@example.com
    }

    // @ at start of line or after whitespace -> likely directive
    if (prev == '\n' || prev == '\r' || prev == ' ' || prev == '\t') {
      return true;
    }

    // Inside HTML attribute -> likely Alpine.js @event
    // Simplified: check if we're between < and >
    int tagStart = _position - 1;
    while (tagStart >= 0 && input[tagStart] != '<' && input[tagStart] != '>') {
      tagStart--;
    }
    if (tagStart >= 0 && input[tagStart] == '<') {
      // Inside tag, likely Alpine.js
      return false;
    }

    // Otherwise treat as directive
    return true;
  }

  /// Lex Blade directive or @ symbol
  _LexerState _lexDirectiveOrComment() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // consume '@'

    // Collect directive name
    final nameStart = _position;
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    if (_position == nameStart) {
      // No directive name, treat @ as text
      _emitToken(TokenType.text, '@');
      return _LexerState.text;
    }

    final name = input.substring(nameStart, _position);

    // Handle @verbatim specially
    if (name == 'verbatim') {
      _emitToken(TokenType.directiveVerbatim, '@$name');
      _inVerbatim = true;
      return _LexerState.text;
    }

    if (name == 'endverbatim') {
      _emitToken(TokenType.directiveEndverbatim, '@$name');
      _inVerbatim = false;
      return _LexerState.text;
    }

    // Emit directive token
    final tokenType = _directiveNameToType(name);
    _emitToken(tokenType, '@$name');

    // Check for expression after directive and emit as separate token
    if (_peek() == '(') {
      final exprStart = _position;
      _advance(); // (
      int parenCount = 1;

      while (!_isAtEnd() && parenCount > 0) {
        if (_peek() == '(') parenCount++;
        if (_peek() == ')') parenCount--;
        _advance();
      }

      final expression = input.substring(exprStart, _position);
      _emitToken(TokenType.expression, expression);
    }

    return _LexerState.text;
  }

  /// Lex Blade comment {{-- --}}
  _LexerState _lexBladeComment() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // {
    _advance(); // {
    _advance(); // -
    _advance(); // -

    final contentStart = _position;

    while (!_isAtEnd()) {
      if (_peek() == '-' &&
          _peekNext() == '-' &&
          _peekAhead(2) == '}' &&
          _peekAhead(3) == '}') {
        final content = input.substring(contentStart, _position);
        _advance(); // -
        _advance(); // -
        _advance(); // }
        _advance(); // }
        _emitToken(TokenType.bladeComment, '{{-- $content --}}');
        return _LexerState.text;
      }
      _advance();
    }

    // Unclosed comment
    _emitToken(TokenType.error, 'Unclosed Blade comment');
    _emitToken(TokenType.eof, '');
    return _LexerState.done;
  }

  /// Lex echo statement {{ }}
  _LexerState _lexEcho() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // {
    _advance(); // {

    _emitToken(TokenType.echoOpen, '{{');

    // Scan expression
    final exprStart = _position;
    int braceCount = 0;

    while (!_isAtEnd()) {
      final ch = _peek();

      if (ch == '{') {
        braceCount++;
      } else if (ch == '}' && _peekNext() == '}') {
        if (braceCount > 0) {
          braceCount--;
        } else {
          // End of echo
          if (_position > exprStart) {
            _emitToken(
                TokenType.expression, input.substring(exprStart, _position));
          }
          _advance(); // }
          _advance(); // }
          _emitToken(TokenType.echoClose, '}}');
          return _LexerState.text;
        }
      }

      _advance();
    }

    // Unclosed echo
    _emitToken(TokenType.error, 'Unclosed echo statement');
    _emitToken(TokenType.eof, '');
    return _LexerState.done;
  }

  /// Lex raw echo {!! !!}
  _LexerState _lexRawEcho() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // {
    _advance(); // !
    _advance(); // !

    _emitToken(TokenType.rawEchoOpen, '{!!');

    // Scan expression
    final exprStart = _position;

    while (!_isAtEnd()) {
      if (_peek() == '!' && _peekNext() == '!' && _peekAhead(2) == '}') {
        if (_position > exprStart) {
          _emitToken(
              TokenType.expression, input.substring(exprStart, _position));
        }
        _advance(); // !
        _advance(); // !
        _advance(); // }
        _emitToken(TokenType.rawEchoClose, '!!}');
        return _LexerState.text;
      }
      _advance();
    }

    // Unclosed raw echo
    _emitToken(TokenType.error, 'Unclosed raw echo');
    _emitToken(TokenType.eof, '');
    return _LexerState.done;
  }

  /// Lex legacy echo {{{ }}}
  _LexerState _lexLegacyEcho() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // {
    _advance(); // {
    _advance(); // {

    _emitToken(TokenType.legacyEchoOpen, '{{{');

    // Scan expression
    final exprStart = _position;

    while (!_isAtEnd()) {
      if (_peek() == '}' && _peekNext() == '}' && _peekAhead(2) == '}') {
        if (_position > exprStart) {
          _emitToken(
              TokenType.expression, input.substring(exprStart, _position));
        }
        _advance(); // }
        _advance(); // }
        _advance(); // }
        _emitToken(TokenType.legacyEchoClose, '}}}');
        return _LexerState.text;
      }
      _advance();
    }

    // Unclosed legacy echo
    _emitToken(TokenType.error, 'Unclosed legacy echo');
    _emitToken(TokenType.eof, '');
    return _LexerState.done;
  }

  /// Lex @verbatim content (already handled in _lexText when _inVerbatim is true)
  _LexerState _lexVerbatim() {
    // This state is not used in current implementation
    // Verbatim handling is done in _lexText
    return _LexerState.text;
  }

  /// Lex component tag <x-component>
  _LexerState _lexComponentTag() {
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    _advance(); // <
    _advance(); // x
    _advance(); // -

    // Scan component name
    final nameStart = _position;
    while (_isAlphaNumeric(_peek()) || _peek() == '-' || _peek() == '.') {
      _advance();
    }

    final componentName = input.substring(nameStart, _position);
    _emitToken(TokenType.componentTagOpen, '<x-$componentName');

    // Skip whitespace
    while (_peek() == ' ' ||
        _peek() == '\t' ||
        _peek() == '\n' ||
        _peek() == '\r') {
      _advance();
    }

    // Parse attributes
    while (!_isAtEnd() && _peek() != '>' && _peek() != '/') {
      _lexAttribute();

      // Skip whitespace
      while (_peek() == ' ' ||
          _peek() == '\t' ||
          _peek() == '\n' ||
          _peek() == '\r') {
        _advance();
      }
    }

    // Check for self-closing />
    if (_peek() == '/' && _peekNext() == '>') {
      _advance(); // /
      _advance(); // >
      _emitToken(TokenType.componentSelfClose, '/>');
      return _LexerState.text;
    }

    // Regular closing >
    if (_peek() == '>') {
      _advance();
      // Don't emit the > as text - it's part of the component tag structure
      return _LexerState.text;
    }

    return _LexerState.text;
  }

  /// Lex HTML tag <tag>
  _LexerState _lexHtmlTag() {
    // T028-T030: Full HTML tag lexing implementation
    final tagStartPos = _position;
    _advance(); // consume '<'

    // Check for closing tag: </
    final isClosingTag = _peek() == '/';
    if (isClosingTag) {
      _emitToken(TokenType.htmlClosingTagStart, '</');
      _advance(); // consume '/'
    } else {
      _emitToken(TokenType.htmlTagOpen, '<');
    }

    // Lex tag name
    _start = _position;
    _startLine = _line;
    _startColumn = _column;

    if (!_isAlpha(_peek())) {
      // Invalid tag name (e.g., <123>)
      // Emit error token and return to text
      _emitToken(TokenType.error, 'Invalid tag name');
      return _LexerState.text;
    }

    // Scan tag name: letters, digits, hyphens
    while (_isAlphaNumeric(_peek()) || _peek() == '-') {
      _advance();
    }

    final tagName = input.substring(_start, _position);
    _emitToken(TokenType.htmlTagName, tagName);

    // Skip whitespace before attributes or tag close
    while (_peek() == ' ' ||
        _peek() == '\t' ||
        _peek() == '\n' ||
        _peek() == '\r') {
      _advance();
    }

    // Lex attributes (reuse existing _lexAttribute)
    while (!_isAtEnd() && _peek() != '>' && _peek() != '/') {
      _lexAttribute();

      // Skip whitespace after attribute
      while (_peek() == ' ' ||
          _peek() == '\t' ||
          _peek() == '\n' ||
          _peek() == '\r') {
        _advance();
      }
    }

    // Check for self-closing: />
    if (_peek() == '/' && _peekNext() == '>') {
      _advance(); // consume '/'
      _advance(); // consume '>'
      _emitToken(TokenType.htmlSelfClose, '/>');
      _start = _position;
      return _LexerState.text;
    }

    // Regular close: >
    if (_peek() == '>') {
      _advance(); // consume '>'
      if (isClosingTag) {
        _emitToken(TokenType.htmlClosingTagEnd, '>');
      } else {
        _emitToken(TokenType.htmlTagClose, '>');
      }
      _start = _position;
      return _LexerState.text;
    }

    // If we reach here, something went wrong
    _emitToken(TokenType.error, 'Unexpected character in HTML tag');
    return _LexerState.text;
  }

  /// Lex attribute (Standard, Alpine.js, or Livewire)
  void _lexAttribute() {
    final attrStart = _position;

    // Skip any unexpected characters (like dots in wire:loading.delay)
    if (!_isAlphaNumeric(_peek()) &&
        _peek() != '@' &&
        _peek() != ':' &&
        _peek() != '_') {
      _advance(); // Skip the unexpected character
      return;
    }

    // Check for Alpine.js shorthand
    if (_peek() == '@') {
      _advance();
      // Alpine.js @event shorthand
      final eventStart = _position;
      while (_isAlphaNumeric(_peek()) || _peek() == '-' || _peek() == '.') {
        _advance();
      }
      final event = input.substring(eventStart, _position);
      _emitToken(TokenType.alpineShorthandOn, '@$event');

      // Lex attribute value
      _lexAttributeValue();
      return;
    }

    if (_peek() == ':') {
      _advance();
      // Alpine.js :bind shorthand
      final bindStart = _position;
      while (_isAlphaNumeric(_peek()) || _peek() == '-') {
        _advance();
      }
      final attr = input.substring(bindStart, _position);
      _emitToken(TokenType.alpineShorthandBind, ':$attr');

      // Lex attribute value
      _lexAttributeValue();
      return;
    }

    // Scan attribute name
    final nameStart = _position;
    while (_isAlphaNumeric(_peek()) ||
        _peek() == '-' ||
        _peek() == ':' ||
        _peek() == '.') {
      _advance();
    }

    final attrName = input.substring(nameStart, _position);

    // Detect attribute type
    if (attrName.startsWith('x-')) {
      // Alpine.js attribute
      final directive = attrName.substring(2);
      _emitToken(_alpineDirectiveToTokenType(directive), attrName);
    } else if (attrName.startsWith('wire:')) {
      // Livewire attribute
      final action = attrName.substring(5);
      _emitToken(_livewireActionToTokenType(action), attrName);
    } else {
      // Standard attribute
      _emitToken(TokenType.identifier, attrName);
    }

    // Lex attribute value
    _lexAttributeValue();
  }

  /// Lex attribute value and emit token
  void _lexAttributeValue() {
    // Skip whitespace
    while (_peek() == ' ' || _peek() == '\t') {
      _advance();
    }

    // Check for =
    if (_peek() != '=') return; // Boolean attribute, no value
    _advance();

    // Skip whitespace
    while (_peek() == ' ' || _peek() == '\t') {
      _advance();
    }

    // Capture quoted value
    final quote = _peek();
    if (quote == '"' || quote == "'") {
      _advance(); // Skip opening quote
      final valueStart = _position;

      // Handle escaped quotes within the string
      while (!_isAtEnd() && _peek() != quote) {
        if (_peek() == '\\' && _peekNext() == quote) {
          _advance(); // Skip backslash
          _advance(); // Skip escaped quote
        } else {
          _advance();
        }
      }

      final value = input.substring(valueStart, _position);

      if (_peek() == quote) {
        _advance(); // Skip closing quote
      }

      // Emit the value without quotes (but includes backslashes for escaped quotes)
      _emitToken(TokenType.attributeValue, value);
    }
  }

  /// Peek word starting at current position
  String _peekWord() {
    int end = _position;
    while (end < input.length && _isAlphaAt(end)) {
      end++;
    }
    return input.substring(_position, end);
  }

  bool _isAlphaAt(int index) {
    if (index >= input.length) return false;
    final code = input.codeUnitAt(index);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  // Helper methods

  bool _isAtEnd() => _position >= input.length;

  String _peek() => _isAtEnd() ? '\x00' : input[_position];

  String _peekNext() =>
      _position + 1 >= input.length ? '\x00' : input[_position + 1];

  String _peekAhead(int n) =>
      _position + n >= input.length ? '\x00' : input[_position + n];

  void _advance() {
    if (_isAtEnd()) return;

    final ch = input[_position];
    _position++;

    if (ch == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
  }

  bool _isAlpha(String ch) {
    if (ch.isEmpty || ch == '\x00') return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isDigit(String ch) {
    if (ch.isEmpty || ch == '\x00') return false;
    final code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isAlphaNumeric(String ch) => _isAlpha(ch) || _isDigit(ch);

  void _emitToken(TokenType type, String value) {
    _tokens.add(Token(
      type: type,
      value: value,
      startLine: _startLine,
      startColumn: _startColumn,
      endLine: _line,
      endColumn: _column,
      startOffset: _start,
      endOffset: _position,
    ));
  }

  /// Map directive name to token type - ALL 75+ DIRECTIVES
  TokenType _directiveNameToType(String name) {
    switch (name) {
      // Control Flow
      case 'if':
        return TokenType.directiveIf;
      case 'elseif':
        return TokenType.directiveElseif;
      case 'else':
        return TokenType.directiveElse;
      case 'endif':
        return TokenType.directiveEndif;
      case 'unless':
        return TokenType.directiveUnless;
      case 'endunless':
        return TokenType.directiveEndunless;
      case 'isset':
        return TokenType.directiveIsset;
      case 'empty':
        return TokenType.directiveEmpty;
      case 'switch':
        return TokenType.directiveSwitch;
      case 'case':
        return TokenType.directiveCase;
      case 'default':
        return TokenType.directiveDefault;
      case 'endswitch':
        return TokenType.directiveEndswitch;

      // Loops
      case 'for':
        return TokenType.directiveFor;
      case 'endfor':
        return TokenType.directiveEndfor;
      case 'foreach':
        return TokenType.directiveForeach;
      case 'endforeach':
        return TokenType.directiveEndforeach;
      case 'forelse':
        return TokenType.directiveForelse;
      case 'endforelse':
        return TokenType.directiveEndforelse;
      case 'while':
        return TokenType.directiveWhile;
      case 'endwhile':
        return TokenType.directiveEndwhile;
      case 'continue':
        return TokenType.directiveContinue;
      case 'break':
        return TokenType.directiveBreak;

      // Template Inheritance
      case 'extends':
        return TokenType.directiveExtends;
      case 'section':
        return TokenType.directiveSection;
      case 'endsection':
        return TokenType.directiveEndsection;
      case 'yield':
        return TokenType.directiveYield;
      case 'parent':
        return TokenType.directiveParent;
      case 'show':
        return TokenType.directiveShow;
      case 'overwrite':
        return TokenType.directiveOverwrite;

      // Stacks
      case 'push':
        return TokenType.directivePush;
      case 'endpush':
        return TokenType.directiveEndpush;
      case 'prepend':
        return TokenType.directivePrepend;
      case 'endprepend':
        return TokenType.directiveEndprepend;
      case 'stack':
        return TokenType.directiveStack;
      case 'pushOnce':
        return TokenType.directivePushOnce;
      case 'endPushOnce':
        return TokenType.directiveEndPushOnce;
      case 'pushIf':
        return TokenType.directivePushIf;
      case 'prependOnce':
        return TokenType.directivePrependOnce;
      case 'endPrependOnce':
        return TokenType.directiveEndPrependOnce;

      // Components
      case 'component':
        return TokenType.directiveComponent;
      case 'endcomponent':
        return TokenType.directiveEndcomponent;
      case 'slot':
        return TokenType.directiveSlot;
      case 'endslot':
        return TokenType.directiveEndslot;
      case 'props':
        return TokenType.directiveProps;
      case 'aware':
        return TokenType.directiveAware;

      // Includes
      case 'include':
        return TokenType.directiveInclude;
      case 'includeIf':
        return TokenType.directiveIncludeIf;
      case 'includeWhen':
        return TokenType.directiveIncludeWhen;
      case 'includeUnless':
        return TokenType.directiveIncludeUnless;
      case 'includeFirst':
        return TokenType.directiveIncludeFirst;
      case 'each':
        return TokenType.directiveEach;

      // Special
      case 'once':
        return TokenType.directiveOnce;
      case 'endonce':
        return TokenType.directiveEndonce;
      case 'php':
        return TokenType.directivePhp;
      case 'endphp':
        return TokenType.directiveEndphp;
      case 'verbatim':
        return TokenType.directiveVerbatim;
      case 'endverbatim':
        return TokenType.directiveEndverbatim;

      // Authentication & Authorization
      case 'auth':
        return TokenType.directiveAuth;
      case 'endauth':
        return TokenType.directiveEndauth;
      case 'guest':
        return TokenType.directiveGuest;
      case 'endguest':
        return TokenType.directiveEndguest;
      case 'can':
        return TokenType.directiveCan;
      case 'endcan':
        return TokenType.directiveEndcan;
      case 'cannot':
        return TokenType.directiveCannot;
      case 'endcannot':
        return TokenType.directiveEndcannot;
      case 'canany':
        return TokenType.directiveCanany;
      case 'endcanany':
        return TokenType.directiveEndcanany;

      // Environment
      case 'env':
        return TokenType.directiveEnv;
      case 'endenv':
        return TokenType.directiveEndenv;
      case 'production':
        return TokenType.directiveProduction;
      case 'endproduction':
        return TokenType.directiveEndproduction;
      case 'session':
        return TokenType.directiveSession;
      case 'endsession':
        return TokenType.directiveEndsession;

      // Debugging
      case 'dd':
        return TokenType.directiveDd;
      case 'dump':
        return TokenType.directiveDump;

      // Validation
      case 'error':
        return TokenType.directiveError;
      case 'enderror':
        return TokenType.directiveEnderror;

      // Section Conditionals
      case 'hasSection':
        return TokenType.directiveHasSection;
      case 'sectionMissing':
        return TokenType.directiveSectionMissing;

      // HTML Attributes
      case 'class':
        return TokenType.directiveClass;
      case 'style':
        return TokenType.directiveStyle;
      case 'checked':
        return TokenType.directiveChecked;
      case 'selected':
        return TokenType.directiveSelected;
      case 'disabled':
        return TokenType.directiveDisabled;
      case 'readonly':
        return TokenType.directiveReadonly;
      case 'required':
        return TokenType.directiveRequired;

      // Assets & Data
      case 'json':
        return TokenType.directiveJson;
      case 'method':
        return TokenType.directiveMethod;
      case 'csrf':
        return TokenType.directiveCsrf;
      case 'vite':
        return TokenType.directiveVite;

      // Service Injection
      case 'inject':
        return TokenType.directiveInject;

      // Modern Features
      case 'fragment':
        return TokenType.directiveFragment;
      case 'endfragment':
        return TokenType.directiveEndfragment;
      case 'use':
        return TokenType.directiveUse;

      // Livewire Directives
      case 'entangle':
        return TokenType.directiveEntangle;
      case 'this':
        return TokenType.directiveThis;
      case 'js':
        return TokenType.directiveJs;

      default:
        return TokenType.identifier;
    }
  }

  /// Map Alpine.js directive to token type
  TokenType _alpineDirectiveToTokenType(String directive) {
    switch (directive) {
      case 'data':
        return TokenType.alpineData;
      case 'init':
        return TokenType.alpineInit;
      case 'show':
        return TokenType.alpineShow;
      case 'if':
        return TokenType.alpineIf;
      case 'for':
        return TokenType.alpineFor;
      case 'model':
        return TokenType.alpineModel;
      case 'text':
        return TokenType.alpineText;
      case 'html':
        return TokenType.alpineHtml;
      case 'bind':
        return TokenType.alpineBind;
      case 'on':
        return TokenType.alpineOn;
      case 'transition':
        return TokenType.alpineTransition;
      case 'cloak':
        return TokenType.alpineCloak;
      case 'ignore':
        return TokenType.alpineIgnore;
      case 'ref':
        return TokenType.alpineRef;
      case 'teleport':
        return TokenType.alpineTeleport;
      default:
        return TokenType.identifier;
    }
  }

  /// Map Livewire action to token type
  TokenType _livewireActionToTokenType(String action) {
    // Parse action with modifiers (e.g., "click.prevent" -> "click")
    final baseName = action.split('.').first;

    switch (baseName) {
      case 'click':
        return TokenType.livewireClick;
      case 'submit':
        return TokenType.livewireSubmit;
      case 'keydown':
        return TokenType.livewireKeydown;
      case 'keyup':
        return TokenType.livewireKeyup;
      case 'mouseenter':
        return TokenType.livewireMouseenter;
      case 'mouseleave':
        return TokenType.livewireMouseleave;
      case 'model':
        return TokenType.livewireModel;
      case 'loading':
        return TokenType.livewireLoading;
      case 'target':
        return TokenType.livewireTarget;
      case 'poll':
        return TokenType.livewirePoll;
      case 'ignore':
        return TokenType.livewireIgnore;
      case 'key':
        return TokenType.livewireKey;
      case 'id':
        return TokenType.livewireId;
      case 'init':
        return TokenType.livewireInit;
      case 'dirty':
        return TokenType.livewireDirty;
      case 'offline':
        return TokenType.livewireOffline;
      case 'navigate':
        return TokenType.livewireNavigate;
      case 'transition':
        return TokenType.livewireTransition;
      case 'stream':
        return TokenType.livewireStream;
      default:
        return TokenType.identifier;
    }
  }
}
