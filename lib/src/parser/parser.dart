import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/error/parse_error.dart';
import 'package:blade_parser/src/error/parse_result.dart';
import 'package:blade_parser/src/lexer/lexer.dart';
import 'package:blade_parser/src/lexer/position.dart';
import 'package:blade_parser/src/lexer/token.dart';
import 'package:blade_parser/src/lexer/token_type.dart';

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
    _tagStack.clear();

    final children = <AstNode>[];

    while (!_isAtEnd()) {
      try {
        final node = _parseNode();
        if (node != null) {
          children.add(node);
        }
      } catch (e) {
        _errors.add(
          ParseError(message: e.toString(), position: _peek().startPosition),
        );
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

    _linkParents(doc);
    return ParseResult(ast: doc, errors: List.unmodifiable(_errors));
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
          'production',
          TokenType.directiveEndproduction,
        );

      // Validation directives
      case TokenType.directiveError:
        return _parseGenericDirective('error', TokenType.directiveEnderror);

      // Section directives
      case TokenType.directiveSection:
        return _parseSectionDirective();

      // Component directives
      case TokenType.directiveComponent:
        return _parseGenericDirective(
          'component',
          TokenType.directiveEndcomponent,
        );

      // Control flow - paired directives
      case TokenType.directiveUnless:
        return _parseGenericDirective('unless', TokenType.directiveEndunless);
      case TokenType.directiveIsset:
        return _parseGenericDirective('isset', TokenType.directiveEndisset,
            supportsElse: true);
      case TokenType.directiveEmpty:
        return _parseGenericDirective('empty', TokenType.directiveEndempty,
            supportsElse: true);

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
        return _parseGenericDirective(
          'verbatim',
          TokenType.directiveEndverbatim,
        );
      case TokenType.directivePush:
        return _parseGenericDirective('push', TokenType.directiveEndpush);
      case TokenType.directivePrepend:
        return _parseGenericDirective('prepend', TokenType.directiveEndprepend);
      case TokenType.directivePushOnce:
        return _parseGenericDirective(
            'pushOnce', TokenType.directiveEndPushOnce);
      case TokenType.directivePrependOnce:
        return _parseGenericDirective(
            'prependOnce', TokenType.directiveEndPrependOnce);
      case TokenType.directivePushIf:
        return _parseGenericDirective('pushIf', TokenType.directiveEndPushOnce);
      case TokenType.directiveFragment:
        return _parseGenericDirective(
          'fragment',
          TokenType.directiveEndfragment,
        );
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
      // Note: directiveShow and directiveOverwrite are section closing tags only
      // They are handled in _parseSection() and should not be parsed as standalone
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
        _errors.add(
          ParseError(message: token.value, position: token.startPosition),
        );
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
      // Unknown/custom directives (e.g. @inertia, @inertiaHead, @datetime)
      // Lexer emits these as TokenType.identifier with '@name' value
      case TokenType.identifier:
        if (token.value.startsWith('@')) {
          final name = token.value.substring(1);
          // If not an @end* and a matching @end{name} exists ahead, parse as block
          if (!name.startsWith('end') && _hasMatchingEndAhead(name)) {
            return _parseUnknownBlockDirective(name);
          }
          return _parseInlineDirective();
        }
        _advance();
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
      TokenType.eof,
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
        TokenType.eof,
      ])) {
        final node = _parseNode();
        if (node != null) elseifChildren.add(node);
      }

      // Add elseif as a nested directive node
      children.add(
        DirectiveNode(
          startPosition: elseifToken.startPosition,
          endPosition: _previous().endPosition,
          name: 'elseif',
          expression: elseifExpression,
          children: elseifChildren,
        ),
      );
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
      children.add(
        DirectiveNode(
          startPosition: elseToken.startPosition,
          endPosition: _previous().endPosition,
          name: 'else',
          children: elseChildren,
        ),
      );
    }

    if (!_check(TokenType.directiveEndif)) {
      _errors.add(
        ParseError(
          message:
              'Unclosed @if directive starting at line ${startToken.startLine}',
          position: startToken.startPosition,
          hint: 'Add @endif to close the conditional block',
        ),
      );
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
      _errors.add(
        ParseError(
          message: 'Unclosed @foreach directive',
          position: startToken.startPosition,
          hint: 'Add @endforeach to close the loop',
        ),
      );
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
      _errors.add(
        ParseError(
          message: 'Unclosed @for directive',
          position: startToken.startPosition,
          hint: 'Add @endfor to close the loop',
        ),
      );
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
      _errors.add(
        ParseError(
          message: 'Unclosed @while directive',
          position: startToken.startPosition,
          hint: 'Add @endwhile to close the loop',
        ),
      );
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
          TokenType.eof,
        ])) {
          final node = _parseNode();
          if (node != null) caseChildren.add(node);
        }

        children.add(
          DirectiveNode(
            startPosition: caseToken.startPosition,
            endPosition: _previous().endPosition,
            name: 'case',
            expression: caseExpression,
            children: caseChildren,
          ),
        );
      } else if (_check(TokenType.directiveDefault)) {
        final defaultToken = _advance();
        final defaultChildren = <AstNode>[];

        while (!_check(TokenType.directiveEndswitch) && !_isAtEnd()) {
          final node = _parseNode();
          if (node != null) defaultChildren.add(node);
        }

        children.add(
          DirectiveNode(
            startPosition: defaultToken.startPosition,
            endPosition: _previous().endPosition,
            name: 'default',
            children: defaultChildren,
          ),
        );
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
      _errors.add(
        ParseError(
          message: 'Unclosed @switch directive',
          position: startToken.startPosition,
        ),
      );
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
    while (!_checkAny([
      TokenType.directiveEmpty,
      TokenType.directiveEndforelse,
      TokenType.eof,
    ])) {
      final node = _parseNode();
      if (node != null) loopChildren.add(node);
    }

    // Parse @empty clause if present
    Position? emptyTokenPosition;
    if (_check(TokenType.directiveEmpty)) {
      emptyTokenPosition = _peek().startPosition;
      _advance(); // consume @empty
      while (!_check(TokenType.directiveEndforelse) && !_isAtEnd()) {
        final node = _parseNode();
        if (node != null) emptyChildren.add(node);
      }
    }

    if (!_check(TokenType.directiveEndforelse)) {
      _errors.add(
        ParseError(
          message: 'Unclosed @forelse directive',
          position: startToken.startPosition,
        ),
      );
    } else {
      _advance(); // @endforelse
    }

    // Add @empty as nested directive if it exists
    if (emptyChildren.isNotEmpty) {
      loopChildren.add(
        DirectiveNode(
          startPosition: emptyTokenPosition!,
          endPosition: _previous().endPosition,
          name: 'empty',
          children: emptyChildren,
        ),
      );
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

  EchoNode _parseEcho() => _parseEchoVariant(
        closeType: TokenType.echoClose,
        label: 'echo statement',
        isRaw: false,
      );

  EchoNode _parseRawEcho() => _parseEchoVariant(
        closeType: TokenType.rawEchoClose,
        label: 'raw echo statement',
        isRaw: true,
      );

  EchoNode _parseLegacyEcho() => _parseEchoVariant(
        closeType: TokenType.legacyEchoClose,
        label: 'legacy echo statement',
        isRaw: true,
      );

  EchoNode _parseEchoVariant({
    required TokenType closeType,
    required String label,
    required bool isRaw,
  }) {
    final openToken = _advance();

    String expression = '';
    if (_check(TokenType.expression)) {
      expression = _advance().value;
    }

    if (!_check(closeType)) {
      _errors.add(
        ParseError(
          message: 'Unclosed $label',
          position: openToken.startPosition,
        ),
      );
    } else {
      _advance();
    }

    return EchoNode(
      startPosition: openToken.startPosition,
      endPosition: _previous().endPosition,
      expression: expression.trim(),
      isRaw: isRaw,
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

  /// Parse slot tag: <x-slot:name> or <x-slot name="...">
  SlotNode _parseSlot(Token startToken, String componentName) {
    String slotName = 'default';

    // Check if name is in colon syntax: "slot:header"
    final isColonSyntax = componentName.startsWith('slot:');
    if (isColonSyntax) {
      slotName = componentName.substring(5); // Remove "slot:"
    }

    // Parse attributes (handles both colon and attribute syntax)
    final attributes = _parseAttributeMap();

    // For attribute syntax: extract name from attributes
    if (!isColonSyntax) {
      final nameAttr = attributes['name'];
      if (nameAttr != null && nameAttr.value != null) {
        slotName = nameAttr.value!;
      }
    }

    // Check for self-closing (rare for slots but possible)
    bool isSelfClosing = false;
    if (_check(TokenType.componentSelfClose)) {
      _advance(); // />
      isSelfClosing = true;
    }

    // Parse slot content
    final children = <AstNode>[];

    if (!isSelfClosing) {
      // Parse until closing tag
      while (!_check(TokenType.componentTagClose) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) {
          children.add(node);
        }
      }

      // Validate closing tag
      if (!_check(TokenType.componentTagClose)) {
        _errors.add(
          ParseError(
            message:
                'Unclosed slot <x-slot${isColonSyntax ? ':$slotName' : ''}>',
            position: startToken.startPosition,
          ),
        );
      } else {
        final closingToken = _advance();
        // Closing token is like "</x-slot:header" or "</x-slot"
        // For named slots (e.g., <x-slot:title>), both </x-slot:title> and </x-slot> are valid
        final expectedClosing =
            isColonSyntax ? '</x-slot:$slotName' : '</x-slot';
        const genericClosing = '</x-slot'; // Generic closing is always valid

        // Accept either the specific closing tag or the generic </x-slot>
        if (closingToken.value != expectedClosing &&
            closingToken.value != genericClosing) {
          _errors.add(
            ParseError(
              message:
                  'Mismatched slot tags: expected $expectedClosing but got ${closingToken.value}',
              position: closingToken.startPosition,
            ),
          );
        }
      }
    }

    return SlotNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      name: slotName,
      useColonSyntax: isColonSyntax,
      attributes: attributes,
      children: children,
    );
  }

  AstNode _parseComponent() {
    final startToken = _advance(); // <x-component or <x-slot:name

    // Extract component name from token value
    // Token value is like "<x-alert" or "<x-button" or "<x-slot:header"
    final componentName = startToken.value.substring(3); // Remove "<x-"

    // Check if this is a slot tag
    if (componentName.startsWith('slot:') || componentName == 'slot') {
      return _parseSlot(startToken, componentName);
    }

    // Parse attributes - collect tokens until we hit > or />
    final attributes = _parseAttributeMap();

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
        _errors.add(
          ParseError(
            message: 'Unclosed component <x-$componentName>',
            position: startToken.startPosition,
            hint: 'Add closing tag </x-$componentName>',
          ),
        );
      } else {
        // Validate closing tag matches opening tag
        final closingToken = _advance(); // </x-component>
        // Closing token value is like "</x-alert" (no trailing >)
        final closingName = closingToken.value.substring(
          4,
        ); // Remove "</x-" prefix

        if (closingName != componentName) {
          _errors.add(
            ParseError(
              message:
                  'Mismatched component tags: expected </x-$componentName>, found </x-$closingName>',
              position: closingToken.startPosition,
              hint:
                  'Change closing tag to </x-$componentName> or fix opening tag to <x-$closingName>',
            ),
          );
        }
      }
    }

    // If children exist and no named slots, create default slot
    if (children.isNotEmpty && slots.isEmpty) {
      slots['default'] = SlotNode(
        startPosition: children.first.startPosition,
        endPosition: children.last.endPosition,
        name: 'default',
        children: List.of(children),
      );
      children.clear();
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
  DirectiveNode _parseGenericDirective(
    String name,
    TokenType closingType, {
    bool supportsElse = false,
  }) {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    while (!_check(closingType) &&
        !_check(TokenType.eof) &&
        !(supportsElse && _check(TokenType.directiveElse))) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    // Handle @else
    if (supportsElse && _check(TokenType.directiveElse)) {
      final elseToken = _advance();
      final elseChildren = <AstNode>[];

      while (!_check(closingType) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) elseChildren.add(node);
      }

      children.add(
        DirectiveNode(
          startPosition: elseToken.startPosition,
          endPosition: _previous().endPosition,
          name: 'else',
          children: elseChildren,
        ),
      );
    }

    if (!_check(closingType)) {
      _errors.add(
        ParseError(
          message: 'Unclosed @$name directive',
          position: startToken.startPosition,
          hint: 'Add @end$name to close the block',
        ),
      );
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

  /// Parse @section directive - handles both inline and block syntax.
  /// Inline: @section('title', 'value') - self-closing
  /// Block: @section('content') ... @endsection
  DirectiveNode _parseSectionDirective() {
    final startToken = _advance();
    final expression = _extractExpression();

    // Check if this is inline syntax (2 arguments with comma)
    // Inline: @section('title', 'value')
    // Block: @section('content')
    final isInline = expression != null && _hasComma(expression);

    if (isInline) {
      // Inline syntax - no closing tag needed
      return DirectiveNode(
        startPosition: startToken.startPosition,
        endPosition: _previous().endPosition,
        name: 'section',
        expression: expression,
        children: [],
      );
    } else {
      // Block syntax - requires @endsection, @show, or @overwrite (legacy)
      final children = <AstNode>[];

      while (!_checkAny([
            TokenType.directiveEndsection,
            TokenType.directiveShow,
            TokenType.directiveOverwrite, // Legacy Laravel 4.x/5.x support
          ]) &&
          !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) children.add(node);
      }

      String? closedBy;
      if (!_checkAny([
        TokenType.directiveEndsection,
        TokenType.directiveShow,
        TokenType.directiveOverwrite,
      ])) {
        _errors.add(
          ParseError(
            message: 'Unclosed @section directive',
            position: startToken.startPosition,
            hint:
                'Add @endsection, @show, or @overwrite (deprecated) to close the block',
          ),
        );
      } else {
        // Capture which closing tag was used (strip @ prefix)
        final closingToken = _peek();
        closedBy = closingToken.value.startsWith('@')
            ? closingToken.value.substring(1)
            : closingToken.value;
        _advance();
      }

      return DirectiveNode(
        startPosition: startToken.startPosition,
        endPosition: _previous().endPosition,
        name: 'section',
        expression: expression,
        children: children,
        closedBy: closedBy,
      );
    }
  }

  /// Check if an expression contains a comma (outside of quotes/brackets)
  /// to determine if it's inline syntax with 2 arguments.
  bool _hasComma(String expr) {
    int depth = 0; // Track parentheses/bracket depth
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool escaped = false;

    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      // Track quote state
      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }
      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      // Skip if inside quotes
      if (inSingleQuote || inDoubleQuote) continue;

      // Track nesting depth
      if (char == '(' || char == '[' || char == '{') {
        depth++;
      } else if (char == ')' || char == ']' || char == '}') {
        depth--;
      }

      // Found comma at top level (depth == 1 for outer parens)
      if (char == ',' && depth == 1) {
        return true;
      }
    }

    return false;
  }

  /// Check if a matching @end{name} identifier exists ahead, with nesting awareness.
  bool _hasMatchingEndAhead(String name) {
    final open = '@$name';
    final close = '@end$name';
    int depth = 0;
    for (int i = _current + 1; i < _tokens.length; i++) {
      final t = _tokens[i];
      if (t.type != TokenType.identifier) continue;
      if (t.value == open) {
        depth++;
      } else if (t.value == close) {
        if (depth == 0) return true;
        depth--;
      }
    }
    return false;
  }

  /// Check if the current token is an identifier with a specific value.
  bool _checkIdentifierValue(String value) {
    if (_isAtEnd()) return false;
    final t = _peek();
    return t.type == TokenType.identifier && t.value == value;
  }

  /// Parse an unknown/custom block directive (@foo...@endfoo).
  DirectiveNode _parseUnknownBlockDirective(String name) {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];
    final closingValue = '@end$name';

    while (!_checkIdentifierValue(closingValue) && !_check(TokenType.eof)) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    if (_checkIdentifierValue(closingValue)) {
      _advance(); // consume @end{name}
    } else {
      _errors.add(
        ParseError(
          message: 'Unclosed @$name directive',
          position: startToken.startPosition,
          hint: 'Add @end$name to close the block',
        ),
      );
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
          _check(TokenType.directiveFor) ||
          _check(TokenType.directiveWhile) ||
          _check(TokenType.directiveSection) ||
          _check(TokenType.directiveSwitch) ||
          _check(TokenType.directiveComponent) ||
          _check(TokenType.directiveAuth) ||
          _check(TokenType.directiveGuest) ||
          _check(TokenType.directiveEnv) ||
          _check(TokenType.directiveUnless) ||
          _check(TokenType.directiveCan) ||
          _check(TokenType.directiveCannot) ||
          _check(TokenType.directiveCanany) ||
          _check(TokenType.directiveOnce) ||
          _check(TokenType.directivePhp) ||
          _check(TokenType.directivePush) ||
          _check(TokenType.directivePrepend) ||
          _check(TokenType.htmlTagOpen) ||
          _check(TokenType.componentTagOpen) ||
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

  /// Check if token type is a Livewire attribute token.
  bool _isLivewireAttributeToken(TokenType type) {
    return type == TokenType.livewireClick ||
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
        type == TokenType.livewireStream;
  }

  /// Check if token type represents an attribute (standard, Alpine, or Livewire)
  bool _isAttributeToken(TokenType type) {
    // Standard attributes
    if (type == TokenType.identifier) return true;

    // Alpine.js shorthand
    if (type == TokenType.alpineShorthandBind ||
        type == TokenType.alpineShorthandOn) {
      return true;
    }

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
        type == TokenType.alpineTeleport) {
      return true;
    }

    // Livewire attributes
    if (_isLivewireAttributeToken(type)) return true;

    // Blade attribute directives (@class, @style, @checked, etc.)
    if (_isBladeAttributeDirective(type)) return true;

    return false;
  }

  /// Check if a token type is a Blade attribute directive.
  /// These are directives designed to be used inside HTML tags.
  bool _isBladeAttributeDirective(TokenType type) {
    return type == TokenType.directiveClass ||
        type == TokenType.directiveStyle ||
        type == TokenType.directiveChecked ||
        type == TokenType.directiveSelected ||
        type == TokenType.directiveDisabled ||
        type == TokenType.directiveReadonly ||
        type == TokenType.directiveRequired;
  }

  /// Parse attributes from current token position into a map.
  /// Handles Alpine.js, Livewire, and standard HTML attributes.
  Map<String, AttributeNode> _parseAttributeMap() {
    final attributes = <String, AttributeNode>{};
    while (_isAttributeToken(_peek().type)) {
      final attrToken = _advance();
      final attrName = attrToken.value;
      final attrStartPos = attrToken.startPosition;
      Position attrEndPos = attrToken.endPosition;

      String? attrValue;

      // Blade attribute directives use expression tokens, not attributeValue
      if (_isBladeAttributeDirective(attrToken.type)) {
        if (_check(TokenType.expression)) {
          final exprToken = _advance();
          attrValue = exprToken.value;
          attrEndPos = exprToken.endPosition;
        }
      } else if (_check(TokenType.attributeValue)) {
        final valueToken = _advance();
        attrValue = valueToken.value;
        attrEndPos = valueToken.endPosition;
      }

      attributes[attrName] = _classifyAttribute(
        attrToken,
        attrName,
        attrValue,
        attrStartPos,
        attrEndPos,
      );
    }
    return attributes;
  }

  /// Classify an attribute token into the appropriate AttributeNode subclass.
  AttributeNode _classifyAttribute(
    Token attrToken,
    String attrName,
    String? attrValue,
    Position startPos,
    Position endPos,
  ) {
    // Check Blade attribute directives first (before Alpine, since @class starts with @)
    if (_isBladeAttributeDirective(attrToken.type)) {
      return StandardAttribute(
        name: attrName,
        value: attrValue,
        startPosition: startPos,
        endPosition: endPos,
      );
    }

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

    final isLivewireToken = _isLivewireAttributeToken(attrToken.type);

    if (isAlpineToken ||
        attrName.startsWith('x-') ||
        attrName.startsWith('@') ||
        attrName.startsWith(':')) {
      final directive = attrName.startsWith('@')
          ? 'on:${attrName.substring(1)}'
          : attrName.startsWith(':')
              ? 'bind:${attrName.substring(1)}'
              : attrName.startsWith('x-')
                  ? attrName.substring(2)
                  : attrName;

      return AlpineAttribute(
        name: attrName,
        directive: directive,
        value: attrValue,
        startPosition: startPos,
        endPosition: endPos,
      );
    } else if (isLivewireToken || attrName.startsWith('wire:')) {
      final parts = attrName.split('.');
      final action =
          parts[0].startsWith('wire:') ? parts[0].substring(5) : parts[0];
      final modifiers = parts.length > 1 ? parts.sublist(1) : <String>[];

      return LivewireAttribute(
        name: attrName,
        action: action,
        modifiers: modifiers,
        value: attrValue,
        startPosition: startPos,
        endPosition: endPos,
      );
    } else {
      return StandardAttribute(
        name: attrName,
        value: attrValue,
        startPosition: startPos,
        endPosition: endPos,
      );
    }
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
    final attributes = _parseAttributeMap();

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
      openingTagPos,
    );
    _tagStack.removeLast(); // Pop from stack

    // Return partial AST (T037)
    return HtmlElementNode(
      tagName: tagName,
      attributes: attributes,
      startPosition: openingTagPos,
      endPosition: endPosition,
      children: children,
    );
  }

  /// Recursively set parent references on all nodes.
  void _linkParents(AstNode node) {
    for (final child in node.children) {
      child.parent = node;
      _linkParents(child);
    }
    if (node is ComponentNode) {
      for (final slot in node.slots.values) {
        slot.parent = node;
        _linkParents(slot);
      }
    }
  }

  /// Report an error (T036)
  void _error(String message, Position position) {
    _errors.add(ParseError(message: message, position: position));
  }
}

/// Tag stack entry for tracking open tags (T032)
class _TagStackEntry {
  final String tagName;
  final Position startPosition;

  _TagStackEntry(this.tagName, this.startPosition);
}
