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

  /// HTML5 void elements that cannot have children.
  static const Set<String> _voidElements = {
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  /// Tag stack for tracking open HTML elements (T032)
  final List<_TagStackEntry> _tagStack = [];

  /// Check if a tag name is a void element.
  bool _isVoidElement(String tagName) =>
      _voidElements.contains(tagName.toLowerCase());

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
      case TokenType.directiveSwitch:
        return _parseSwitchDirective();
      case TokenType.directiveForelse:
        return _parseForelseDirective();

      // Authentication directives
      case TokenType.directiveAuth:
        return _parseGenericDirective('auth', TokenType.directiveEndauth);
      case TokenType.directiveGuest:
        return _parseGenericDirective('guest', TokenType.directiveEndguest);

      // Environment directives
      case TokenType.directiveEnv:
        return _parseGenericDirective('env', TokenType.directiveEndenv);
      case TokenType.directiveProduction:
        return _parseGenericDirective(
            'production', TokenType.directiveEndproduction);

      // Validation directives
      case TokenType.directiveError:
        return _parseGenericDirective('error', TokenType.directiveEnderror);

      // Section directives
      case TokenType.directiveSection:
        return _parseGenericDirective('section', TokenType.directiveEndsection);

      // Component directives
      case TokenType.directiveComponent:
        return _parseGenericDirective(
            'component', TokenType.directiveEndcomponent);

      // Control flow - paired directives
      case TokenType.directiveUnless:
        return _parseGenericDirective('unless', TokenType.directiveEndunless);
      case TokenType.directiveIsset:
        return _parseGenericDirective('isset', TokenType.directiveEndisset);
      case TokenType.directiveEmpty:
        return _parseGenericDirective('empty', TokenType.directiveEndempty);

      // Authorization - paired directives
      case TokenType.directiveCan:
        return _parseGenericDirective('can', TokenType.directiveEndcan);
      case TokenType.directiveCannot:
        return _parseGenericDirective('cannot', TokenType.directiveEndcannot);
      case TokenType.directiveCanany:
        return _parseGenericDirective('canany', TokenType.directiveEndcanany);

      // Template features - paired directives
      case TokenType.directiveOnce:
        return _parseGenericDirective('once', TokenType.directiveEndonce);
      case TokenType.directivePhp:
        return _parseGenericDirective('php', TokenType.directiveEndphp);
      case TokenType.directiveVerbatim:
        return _parseGenericDirective('verbatim', TokenType.directiveEndverbatim);
      case TokenType.directivePush:
        return _parseGenericDirective('push', TokenType.directiveEndpush);
      case TokenType.directivePrepend:
        return _parseGenericDirective('prepend', TokenType.directiveEndprepend);
      case TokenType.directiveFragment:
        return _parseGenericDirective('fragment', TokenType.directiveEndfragment);
      case TokenType.directiveSession:
        return _parseGenericDirective('session', TokenType.directiveEndsession);

      // Livewire - paired directives
      case TokenType.directiveScript:
        return _parseGenericDirective('script', TokenType.directiveEndscript);
      case TokenType.directiveAssets:
        return _parseGenericDirective('assets', TokenType.directiveEndassets);

      // Other directives (inline, no closing tag)
      case TokenType.directiveExtends:
      case TokenType.directiveYield:
      case TokenType.directiveInclude:
      case TokenType.directiveIncludeIf:
      case TokenType.directiveIncludeWhen:
      case TokenType.directiveIncludeUnless:
      case TokenType.directiveIncludeFirst:
      case TokenType.directiveEach:
      case TokenType.directiveContinue:
      case TokenType.directiveBreak:
      case TokenType.directiveCsrf:
      case TokenType.directiveMethod:
      case TokenType.directiveVite:
      case TokenType.directiveJson:
      case TokenType.directiveDd:
      case TokenType.directiveDump:
      case TokenType.directiveParent:
      case TokenType.directiveShow:
      case TokenType.directiveOverwrite:
      case TokenType.directiveStack:
      case TokenType.directiveHasSection:
      case TokenType.directiveSectionMissing:
      case TokenType.directiveClass:
      case TokenType.directiveStyle:
      case TokenType.directiveChecked:
      case TokenType.directiveSelected:
      case TokenType.directiveDisabled:
      case TokenType.directiveReadonly:
      case TokenType.directiveRequired:
      case TokenType.directiveInject:
      case TokenType.directiveUse:
      case TokenType.directiveEntangle:
      case TokenType.directiveThis:
      case TokenType.directiveJs:
      case TokenType.directiveProps:
      case TokenType.directiveAware:
      case TokenType.directiveLivewireStyles:
      case TokenType.directiveLivewireScripts:
      case TokenType.directiveLivewireScriptConfig:
      case TokenType.directiveFilamentStyles:
      case TokenType.directiveFilamentScripts:
        return _parseInlineDirective();

      // Echo statements
      case TokenType.echoOpen:
        return _parseEcho();
      case TokenType.rawEchoOpen:
        return _parseRawEcho();
      case TokenType.legacyEchoOpen:
        return _parseLegacyEcho();

      // Components
      case TokenType.componentTagOpen:
        return _parseComponent();

      // HTML Elements
      case TokenType.htmlTagOpen:
      case TokenType.htmlClosingTagStart:
        return _parseHtmlElement();

      // Error tokens
      case TokenType.error:
        final token = _advance();
        _errors.add(ParseError(
          message: token.value,
          position: token.startPosition,
        ));
        return null;

      // Text and comments
      case TokenType.text:
        return _parseText();
      case TokenType.bladeComment:
        final token = _advance();
        return CommentNode(
          startPosition: token.startPosition,
          endPosition: token.endPosition,
          content: token.value,
          isBladeComment: true,
        );
      case TokenType.htmlComment:
        final token = _advance();
        return CommentNode(
          startPosition: token.startPosition,
          endPosition: token.endPosition,
          content: token.value,
          isBladeComment: false,
        );
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

    // Parse the 'then' branch
    while (!_checkAny([
      TokenType.directiveEndif,
      TokenType.directiveElse,
      TokenType.directiveElseif,
      TokenType.eof
    ])) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    // Handle @elseif chain
    while (_check(TokenType.directiveElseif)) {
      final elseifToken = _advance();
      final elseifExpression = _extractExpression();
      final elseifChildren = <AstNode>[];

      while (!_checkAny([
        TokenType.directiveEndif,
        TokenType.directiveElse,
        TokenType.directiveElseif,
        TokenType.eof
      ])) {
        final node = _parseNode();
        if (node != null) elseifChildren.add(node);
      }

      // Add elseif as a nested directive node
      children.add(DirectiveNode(
        startPosition: elseifToken.startPosition,
        endPosition: _previous().endPosition,
        name: 'elseif',
        expression: elseifExpression,
        children: elseifChildren,
      ));
    }

    // Handle @else
    if (_check(TokenType.directiveElse)) {
      final elseToken = _advance();
      final elseChildren = <AstNode>[];

      while (!_check(TokenType.directiveEndif) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) elseChildren.add(node);
      }

      // Add else as a nested directive node
      children.add(DirectiveNode(
        startPosition: elseToken.startPosition,
        endPosition: _previous().endPosition,
        name: 'else',
        expression: null,
        children: elseChildren,
      ));
    }

    if (!_check(TokenType.directiveEndif)) {
      _errors.add(ParseError(
        message:
            'Unclosed @if directive starting at line ${startToken.startLine}',
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

  /// Parse @switch/@case/@default/@endswitch directive
  DirectiveNode _parseSwitchDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(TokenType.directiveEndswitch) && !_isAtEnd()) {
      if (_check(TokenType.directiveCase)) {
        final caseToken = _advance();
        final caseExpression = _extractExpression();
        final caseChildren = <AstNode>[];

        while (!_checkAny([
          TokenType.directiveCase,
          TokenType.directiveDefault,
          TokenType.directiveEndswitch,
          TokenType.eof
        ])) {
          final node = _parseNode();
          if (node != null) caseChildren.add(node);
        }

        children.add(DirectiveNode(
          startPosition: caseToken.startPosition,
          endPosition: _previous().endPosition,
          name: 'case',
          expression: caseExpression,
          children: caseChildren,
        ));
      } else if (_check(TokenType.directiveDefault)) {
        final defaultToken = _advance();
        final defaultChildren = <AstNode>[];

        while (!_check(TokenType.directiveEndswitch) && !_isAtEnd()) {
          final node = _parseNode();
          if (node != null) defaultChildren.add(node);
        }

        children.add(DirectiveNode(
          startPosition: defaultToken.startPosition,
          endPosition: _previous().endPosition,
          name: 'default',
          expression: null,
          children: defaultChildren,
        ));
      } else {
        // Skip non-case/default content (whitespace, etc.) and continue looking
        final node = _parseNode();
        if (node != null) {
          // Content outside case/default - add to switch children
          children.add(node);
        }
      }
    }

    if (!_check(TokenType.directiveEndswitch)) {
      _errors.add(ParseError(
        message: 'Unclosed @switch directive',
        position: startToken.startPosition,
      ));
    } else {
      _advance(); // @endswitch
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'switch',
      expression: expression,
      children: children,
    );
  }

  /// Parse @forelse/@empty/@endforelse directive
  DirectiveNode _parseForelseDirective() {
    final startToken = _advance();
    final expression = _extractExpression();
    final loopChildren = <AstNode>[];
    final emptyChildren = <AstNode>[];

    // Parse loop body
    while (!_checkAny([TokenType.directiveEmpty, TokenType.directiveEndforelse, TokenType.eof])) {
      final node = _parseNode();
      if (node != null) loopChildren.add(node);
    }

    // Parse @empty clause if present
    if (_check(TokenType.directiveEmpty)) {
      _advance(); // consume @empty
      while (!_check(TokenType.directiveEndforelse) && !_isAtEnd()) {
        final node = _parseNode();
        if (node != null) emptyChildren.add(node);
      }
    }

    if (!_check(TokenType.directiveEndforelse)) {
      _errors.add(ParseError(
        message: 'Unclosed @forelse directive',
        position: startToken.startPosition,
      ));
    } else {
      _advance(); // @endforelse
    }

    // Add @empty as nested directive if it exists
    if (emptyChildren.isNotEmpty) {
      loopChildren.add(DirectiveNode(
        startPosition: startToken.startPosition,
        endPosition: _previous().endPosition,
        name: 'empty',
        expression: null,
        children: emptyChildren,
      ));
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: 'forelse',
      expression: expression,
      children: loopChildren,
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

  EchoNode _parseLegacyEcho() {
    final openToken = _advance(); // {{{

    String expression = '';
    if (_check(TokenType.expression)) {
      expression = _advance().value;
    }

    if (!_check(TokenType.legacyEchoClose)) {
      _errors.add(ParseError(
        message: 'Unclosed legacy echo statement',
        position: openToken.startPosition,
      ));
    } else {
      _advance(); // }}}
    }

    return EchoNode(
      startPosition: openToken.startPosition,
      endPosition: _previous().endPosition,
      expression: expression.trim(),
      isRaw: true, // Legacy echo is raw (not escaped)
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

  ComponentNode _parseComponent() {
    final startToken = _advance(); // <x-component

    // Extract component name from token value
    // Token value is like "<x-alert" or "<x-button"
    final componentName = startToken.value.substring(3); // Remove "<x-"

    // Parse attributes - collect tokens until we hit > or />
    final attributes = <String, AttributeNode>{};
    while (_isAttributeToken(_peek().type)) {
      final attrToken = _advance();
      final attrName = attrToken.value;

      // Check for attribute value in next token
      String? attrValue;
      if (_check(TokenType.attributeValue)) {
        attrValue = _advance().value;
      }

      // Create appropriate attribute node based on token type
      AttributeNode attrNode;

      // Check token type first for proper classification
      final isAlpineToken = attrToken.type == TokenType.alpineShorthandOn ||
          attrToken.type == TokenType.alpineShorthandBind ||
          attrToken.type == TokenType.alpineData ||
          attrToken.type == TokenType.alpineInit ||
          attrToken.type == TokenType.alpineShow ||
          attrToken.type == TokenType.alpineIf ||
          attrToken.type == TokenType.alpineFor ||
          attrToken.type == TokenType.alpineModel ||
          attrToken.type == TokenType.alpineText ||
          attrToken.type == TokenType.alpineHtml ||
          attrToken.type == TokenType.alpineBind ||
          attrToken.type == TokenType.alpineOn ||
          attrToken.type == TokenType.alpineTransition ||
          attrToken.type == TokenType.alpineCloak ||
          attrToken.type == TokenType.alpineIgnore ||
          attrToken.type == TokenType.alpineRef ||
          attrToken.type == TokenType.alpineTeleport;

      final isLivewireToken = attrToken.type.toString().contains('livewire');

      if (isAlpineToken ||
          attrName.startsWith('x-') ||
          attrName.startsWith('@') ||
          attrName.startsWith(':')) {
        // Extract directive from attribute name
        final directive = attrName.startsWith('x-')
            ? attrName.substring(2)
            : attrName.startsWith('@')
                ? attrName.substring(1)
                : attrName.startsWith(':')
                    ? attrName.substring(1)
                    : attrName;

        attrNode = AlpineAttribute(
          name: attrName,
          directive: directive,
          value: attrValue,
        );
      } else if (isLivewireToken || attrName.startsWith('wire:')) {
        // Extract action and modifiers from wire:action.modifier1.modifier2
        final parts = attrName.substring(5).split('.');
        final action = parts.first;
        final modifiers = parts.length > 1 ? parts.sublist(1) : <String>[];

        attrNode = LivewireAttribute(
          name: attrName,
          action: action,
          modifiers: modifiers,
          value: attrValue,
        );
      } else {
        attrNode = StandardAttribute(
          name: attrName,
          value: attrValue,
        );
      }

      attributes[attrName] = attrNode;
    }

    // Check for self-closing
    bool isSelfClosing = false;
    if (_check(TokenType.componentSelfClose)) {
      _advance(); // />
      isSelfClosing = true;
    }

    // Parse children if not self-closing
    final children = <AstNode>[];
    final slots = <String, SlotNode>{};

    if (!isSelfClosing) {
      // Parse until closing tag
      while (!_check(TokenType.componentTagClose) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) {
          if (node is SlotNode) {
            slots[node.name] = node;
          } else {
            children.add(node);
          }
        }
      }

      if (!_check(TokenType.componentTagClose)) {
        _errors.add(ParseError(
          message: 'Unclosed component <x-$componentName>',
          position: startToken.startPosition,
          hint: 'Add closing tag </x-$componentName>',
        ));
      } else {
        // Validate closing tag matches opening tag
        final closingToken = _advance(); // </x-component>
        // Closing token value is like "</x-alert" (no trailing >)
        final closingName = closingToken.value.substring(4); // Remove "</x-" prefix

        if (closingName != componentName) {
          _errors.add(ParseError(
            message: 'Mismatched component tags: expected </x-$componentName>, found </x-$closingName>',
            position: closingToken.startPosition,
            hint: 'Change closing tag to </x-$componentName> or fix opening tag to <x-$closingName>',
          ));
        }
      }
    }

    // If children exist and no named slots, create default slot
    if (children.isNotEmpty && slots.isEmpty) {
      slots['default'] = SlotNode(
        startPosition: children.first.startPosition,
        endPosition: children.last.endPosition,
        name: 'default',
        children: children,
      );
    }

    return ComponentNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: componentName,
      attributes: attributes,
      slots: slots,
      isSelfClosing: isSelfClosing,
      children: children,
    );
  }

  /// Parse generic directive with opening/closing tags.
  DirectiveNode _parseGenericDirective(String name, TokenType closingType) {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(closingType) && !_check(TokenType.eof)) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    if (!_check(closingType)) {
      _errors.add(ParseError(
        message: 'Unclosed @$name directive',
        position: startToken.startPosition,
        hint: 'Add @end$name to close the block',
      ));
    } else {
      _advance();
    }

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: name,
      expression: expression,
      children: children,
    );
  }

  /// Parse inline directive (no closing tag).
  DirectiveNode _parseInlineDirective() {
    final startToken = _advance();
    final expression = _extractExpression();

    // Get directive name from token type
    final name = startToken.value.substring(1); // Remove '@'

    return DirectiveNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: name,
      expression: expression,
      children: [],
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
      return _tokens.isNotEmpty
          ? _tokens.last
          : Token(
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

  /// Check if token type represents an attribute (standard, Alpine, or Livewire)
  bool _isAttributeToken(TokenType type) {
    // Standard attributes
    if (type == TokenType.identifier) return true;

    // Alpine.js shorthand
    if (type == TokenType.alpineShorthandBind ||
        type == TokenType.alpineShorthandOn) return true;

    // Alpine.js directives
    if (type == TokenType.alpineData ||
        type == TokenType.alpineInit ||
        type == TokenType.alpineShow ||
        type == TokenType.alpineIf ||
        type == TokenType.alpineFor ||
        type == TokenType.alpineModel ||
        type == TokenType.alpineText ||
        type == TokenType.alpineHtml ||
        type == TokenType.alpineBind ||
        type == TokenType.alpineOn ||
        type == TokenType.alpineTransition ||
        type == TokenType.alpineCloak ||
        type == TokenType.alpineIgnore ||
        type == TokenType.alpineRef ||
        type == TokenType.alpineTeleport) return true;

    // Livewire attributes
    if (type == TokenType.livewireClick ||
        type == TokenType.livewireSubmit ||
        type == TokenType.livewireKeydown ||
        type == TokenType.livewireKeyup ||
        type == TokenType.livewireMouseenter ||
        type == TokenType.livewireMouseleave ||
        type == TokenType.livewireModel ||
        type == TokenType.livewireModelLive ||
        type == TokenType.livewireModelBlur ||
        type == TokenType.livewireModelDebounce ||
        type == TokenType.livewireModelLazy ||
        type == TokenType.livewireModelDefer ||
        type == TokenType.livewireLoading ||
        type == TokenType.livewireTarget ||
        type == TokenType.livewireLoadingClass ||
        type == TokenType.livewireLoadingRemove ||
        type == TokenType.livewireLoadingAttr ||
        type == TokenType.livewirePoll ||
        type == TokenType.livewirePollKeepAlive ||
        type == TokenType.livewirePollVisible ||
        type == TokenType.livewireIgnore ||
        type == TokenType.livewireKey ||
        type == TokenType.livewireId ||
        type == TokenType.livewireInit ||
        type == TokenType.livewireDirty ||
        type == TokenType.livewireOffline ||
        type == TokenType.livewireNavigate ||
        type == TokenType.livewireTransition ||
        type == TokenType.livewireStream) return true;

    return false;
  }

  /// Parse HTML element into HtmlElementNode (T031-T037)
  ///
  /// Handles:
  /// - Opening tags: <div>, <p>, etc.
  /// - Attributes: class, id, data-*, etc.
  /// - Children: nested elements, text, directives
  /// - Closing tags: </div>, </p>
  /// - Self-closing: <br/>, <img/>
  /// - Void elements: <br>, <img>, <meta>, <input>, <hr>, <link>
  HtmlElementNode? _parseHtmlElement() {
    final startToken = _peek();

    // Handle closing tag (shouldn't be called directly, but handle gracefully)
    if (_check(TokenType.htmlClosingTagStart)) {
      final closingStartPos = _advance().startPosition; // consume '</

      if (_check(TokenType.htmlTagName)) {
        final tagNameToken = _advance(); // consume tag name
        final tagName = tagNameToken.value.toLowerCase();

        // Check if this is a void element closing tag (T035 - error case)
        if (_isVoidElement(tagName)) {
          _error(
            'Void element <$tagName> cannot have closing tag',
            closingStartPos,
          );
        }

        if (_check(TokenType.htmlClosingTagEnd)) {
          _advance(); // consume '>'
        }
      }

      return null; // Closing tags handled by parent
    }

    // Parse opening tag
    if (!_check(TokenType.htmlTagOpen)) {
      return null;
    }

    final openingTagPos = _advance().startPosition; // consume '<'

    // Get tag name
    if (!_check(TokenType.htmlTagName)) {
      _error('Expected tag name after <', _peek().startPosition);
      return null;
    }

    final tagNameToken = _advance();
    final tagName = tagNameToken.value.toLowerCase(); // Normalize to lowercase

    // Validate tag name (T036 - invalid tag name)
    // HTML tag names must start with a letter
    if (tagName.isEmpty || !RegExp(r'^[a-z]').hasMatch(tagName)) {
      _error('Invalid tag name: <$tagName>', tagNameToken.startPosition);
      return null;
    }

    final isVoid = _isVoidElement(tagName);

    // Parse attributes (T034)
    final attributes = <String, AttributeNode>{};
    while (_isAttributeToken(_peek().type)) {
      final attrToken = _advance();
      final attrName = attrToken.value;

      // Check for attribute value in next token
      String? attrValue;
      if (_check(TokenType.attributeValue)) {
        attrValue = _advance().value;
      }

      // Create appropriate attribute node based on token type
      AttributeNode attrNode;

      // Check token type first for proper classification
      final isAlpineToken = attrToken.type == TokenType.alpineShorthandOn ||
          attrToken.type == TokenType.alpineShorthandBind ||
          attrToken.type == TokenType.alpineData ||
          attrToken.type == TokenType.alpineInit ||
          attrToken.type == TokenType.alpineShow ||
          attrToken.type == TokenType.alpineIf ||
          attrToken.type == TokenType.alpineFor ||
          attrToken.type == TokenType.alpineModel ||
          attrToken.type == TokenType.alpineText ||
          attrToken.type == TokenType.alpineHtml ||
          attrToken.type == TokenType.alpineBind ||
          attrToken.type == TokenType.alpineOn ||
          attrToken.type == TokenType.alpineTransition ||
          attrToken.type == TokenType.alpineCloak ||
          attrToken.type == TokenType.alpineIgnore ||
          attrToken.type == TokenType.alpineRef ||
          attrToken.type == TokenType.alpineTeleport;

      final isLivewireToken =
          attrToken.type.toString().startsWith('TokenType.livewire');

      if (isAlpineToken) {
        // Alpine.js attribute
        final directive = attrName.startsWith('@')
            ? 'on:${attrName.substring(1)}'
            : attrName.startsWith(':')
                ? 'bind:${attrName.substring(1)}'
                : attrName.startsWith('x-')
                    ? attrName.substring(2)
                    : attrName;

        attrNode = AlpineAttribute(
          name: attrName,
          directive: directive,
          value: attrValue,
        );
      } else if (isLivewireToken) {
        // Livewire attribute - parse action and modifiers
        final parts = attrName.split('.');
        final action =
            parts[0].startsWith('wire:') ? parts[0].substring(5) : parts[0];
        final modifiers = parts.length > 1 ? parts.sublist(1) : <String>[];

        attrNode = LivewireAttribute(
          name: attrName,
          action: action,
          modifiers: modifiers,
          value: attrValue,
        );
      } else {
        // Standard attribute
        attrNode = StandardAttribute(
          name: attrName,
          value: attrValue,
        );
      }

      attributes[attrName] = attrNode;
    }

    // Check for self-closing or regular close
    bool isSelfClosing = false;
    Position? endPosition;

    if (_check(TokenType.htmlSelfClose)) {
      isSelfClosing = true;
      endPosition = _advance().endPosition; // consume '/>'

      return HtmlElementNode(
        tagName: tagName,
        attributes: attributes,
        isSelfClosing: isSelfClosing,
        isVoid: isVoid,
        startPosition: openingTagPos,
        endPosition: endPosition,
        children: [],
      );
    }

    if (_check(TokenType.htmlTagClose)) {
      endPosition = _advance().endPosition; // consume '>'
    } else {
      _error('Expected > or /> to close tag', _peek().startPosition);
      return null;
    }

    // If void element, no children expected (T035)
    if (isVoid) {
      return HtmlElementNode(
        tagName: tagName,
        attributes: attributes,
        isSelfClosing: false,
        isVoid: true,
        startPosition: openingTagPos,
        endPosition: endPosition,
        children: [],
      );
    }

    // Parse children (T031)
    _tagStack.add(_TagStackEntry(tagName, openingTagPos)); // T032
    final children = <AstNode>[];

    while (!_isAtEnd()) {
      // Check for closing tag
      if (_check(TokenType.htmlClosingTagStart)) {
        _advance(); // consume '</

        if (!_check(TokenType.htmlTagName)) {
          _error('Expected tag name after </', _peek().startPosition);
          break;
        }

        final closingTagName = _advance().value.toLowerCase();
        final closingEndPos = _peek().endPosition;

        // Tag matching validation (T033)
        if (closingTagName != tagName) {
          _error(
            'Expected </$tagName>, found </$closingTagName>',
            _peek().startPosition,
          );
          // Continue parsing for error recovery
        }

        // Consume '>'
        if (_check(TokenType.htmlClosingTagEnd)) {
          _advance();
        }

        _tagStack.removeLast(); // Pop from stack (T032)

        return HtmlElementNode(
          tagName: tagName,
          attributes: attributes,
          isSelfClosing: false,
          isVoid: false,
          startPosition: openingTagPos,
          endPosition: closingEndPos,
          children: children,
        );
      }

      // Parse child node
      final child = _parseNode();
      if (child != null) {
        children.add(child);
      }

      // Safety: break if we're stuck
      if (_current >= _tokens.length - 1) {
        break;
      }
    }

    // Unclosed tag error (T036)
    _error(
        'Unclosed <$tagName> at ${openingTagPos.line}:${openingTagPos.column}',
        openingTagPos);
    _tagStack.removeLast(); // Pop from stack

    // Return partial AST (T037)
    return HtmlElementNode(
      tagName: tagName,
      attributes: attributes,
      isSelfClosing: false,
      isVoid: false,
      startPosition: openingTagPos,
      endPosition: endPosition,
      children: children,
    );
  }

  /// Report an error (T036)
  void _error(String message, Position position) {
    _errors.add(ParseError(
      message: message,
      position: position,
    ));
  }
}

/// Tag stack entry for tracking open tags (T032)
class _TagStackEntry {
  final String tagName;
  final Position startPosition;

  _TagStackEntry(this.tagName, this.startPosition);
}
