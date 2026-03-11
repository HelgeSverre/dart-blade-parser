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
  String _source = '';

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

  String _closingDirectiveName(String name) {
    return TokenType.closingDirectiveName(name);
  }

  /// Check if a tag name is a void element.
  bool _isVoidElement(String tagName) =>
      _voidElements.contains(tagName.toLowerCase());

  /// Parse a Blade template string.
  /// Recovers the quote character used for an attribute value token.
  String? _inferQuoteChar(Token valueToken) {
    final i = valueToken.startOffset - 1;
    if (i < 0 || i >= _source.length) return null;
    final ch = _source[i];
    return (ch == '"' || ch == "'") ? ch : null;
  }

  ParseResult parse(String source) {
    _source = source;
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
        return _parseGenericDirective('auth', TokenType.directiveEndauth,
            supportsElse: true);
      case TokenType.directiveGuest:
        return _parseGenericDirective('guest', TokenType.directiveEndguest,
            supportsElse: true);

      // Environment directives
      case TokenType.directiveEnv:
        return _parseGenericDirective('env', TokenType.directiveEndenv,
            supportsElse: true);
      case TokenType.directiveProduction:
        return _parseGenericDirective(
          'production',
          TokenType.directiveEndproduction,
          supportsElse: true,
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
      case TokenType.directiveSlot:
        return _parseGenericDirective('slot', TokenType.directiveEndslot);

      // Control flow - paired directives
      case TokenType.directiveUnless:
        return _parseGenericDirective('unless', TokenType.directiveEndunless,
            supportsElse: true,
            alternateClosingTypes: [TokenType.directiveEndif]);
      case TokenType.directiveIsset:
        return _parseGenericDirective('isset', TokenType.directiveEndisset,
            supportsElse: true,
            alternateClosingTypes: [TokenType.directiveEndif]);
      case TokenType.directiveEmpty:
        return _parseGenericDirective('empty', TokenType.directiveEndempty,
            supportsElse: true,
            alternateClosingTypes: [TokenType.directiveEndif]);

      // Authorization - paired directives
      case TokenType.directiveCan:
        return _parseGenericDirective('can', TokenType.directiveEndcan,
            supportsElse: true);
      case TokenType.directiveCannot:
        return _parseGenericDirective('cannot', TokenType.directiveEndcannot,
            supportsElse: true);
      case TokenType.directiveCanany:
        return _parseGenericDirective('canany', TokenType.directiveEndcanany,
            supportsElse: true);

      // Template features - paired directives
      case TokenType.directiveOnce:
        return _parseGenericDirective('once', TokenType.directiveEndonce);
      case TokenType.directivePhp:
        // Inline @php($expr) has an expression token following;
        // block @php has raw text content until @endphp
        if (_current < _tokens.length - 1 &&
            _tokens[_current + 1].type == TokenType.expression) {
          return _parseInlineDirective();
        }
        return _parsePhpDirectiveBlock();
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
        return _parseGenericDirective('pushIf', TokenType.directiveEndPushIf);
      case TokenType.directiveFragment:
        return _parseGenericDirective(
          'fragment',
          TokenType.directiveEndfragment,
        );
      case TokenType.directiveSession:
        return _parseGenericDirective('session', TokenType.directiveEndsession);
      case TokenType.directiveContext:
        return _parseGenericDirective('context', TokenType.directiveEndcontext);

      // Stacks - conditional
      case TokenType.directiveHasStack:
        return _parseGenericDirective('hasStack', TokenType.directiveEndif);

      // Livewire - paired directives
      case TokenType.directiveScript:
        return _parseGenericDirective('script', TokenType.directiveEndscript);
      case TokenType.directiveAssets:
        return _parseGenericDirective('assets', TokenType.directiveEndassets);
      case TokenType.directiveTeleport:
        return _parseGenericDirective(
            'teleport', TokenType.directiveEndTeleport);
      case TokenType.directivePersist:
        return _parseGenericDirective('persist', TokenType.directiveEndPersist);

      // Volt - paired directive
      case TokenType.directiveVolt:
        return _parseGenericDirective('volt', TokenType.directiveEndvolt);

      // Blaze - inline (no closing tag)
      case TokenType.directiveBlaze:
        return _parseInlineDirective();
      // Blaze - paired block directive
      case TokenType.directiveUnblaze:
        return _parseGenericDirective('unblaze', TokenType.directiveEndunblaze);

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
      case TokenType.directiveLivewire:
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
        return _parseHtmlElement();
      case TokenType.htmlClosingTagStart:
        return _parseStrayClosingTag();

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
      case TokenType.phpBlock:
        return _parsePhpTagBlock();
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
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endif',
        startPosition: pos,
        endPosition: pos,
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
      _errors.add(
        ParseError(
          message: 'Unclosed @foreach directive',
          position: startToken.startPosition,
          hint: 'Add @endforeach to close the loop',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endforeach',
        startPosition: pos,
        endPosition: pos,
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
      _errors.add(
        ParseError(
          message: 'Unclosed @for directive',
          position: startToken.startPosition,
          hint: 'Add @endfor to close the loop',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endfor',
        startPosition: pos,
        endPosition: pos,
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
      _errors.add(
        ParseError(
          message: 'Unclosed @while directive',
          position: startToken.startPosition,
          hint: 'Add @endwhile to close the loop',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endwhile',
        startPosition: pos,
        endPosition: pos,
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
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @endswitch',
        startPosition: pos,
        endPosition: pos,
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
      final pos = _previous().endPosition;
      loopChildren.add(RecoveryNode(
        content: '',
        reason: 'missing @endforelse',
        startPosition: pos,
        endPosition: pos,
      ));
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

  /// Parse a `<?php ... ?>`, `<?= ... ?>`, or `<? ... ?>` block.
  PhpBlockNode _parsePhpTagBlock() {
    final token = _advance();
    final value = token.value;

    PhpBlockSyntax syntax;
    String code;

    if (value.startsWith('<?=')) {
      syntax = PhpBlockSyntax.shortEcho;
      code = _extractPhpCode(value, 3);
    } else if (value.startsWith('<?php')) {
      syntax = PhpBlockSyntax.phpTag;
      code = _extractPhpCode(value, 5);
    } else {
      syntax = PhpBlockSyntax.shortTag;
      code = _extractPhpCode(value, 2);
    }

    return PhpBlockNode(
      startPosition: token.startPosition,
      endPosition: token.endPosition,
      code: code,
      syntax: syntax,
    );
  }

  /// Extract PHP code from a token value, stripping opening tag prefix
  /// and optional closing `?>`.
  String _extractPhpCode(String value, int prefixLength) {
    var code = value.substring(prefixLength);
    if (code.endsWith('?>')) {
      code = code.substring(0, code.length - 2);
    }
    return code;
  }

  /// Parse `@php ... @endphp` as a [PhpBlockNode].
  PhpBlockNode _parsePhpDirectiveBlock() {
    final startToken = _advance();

    // Collect raw text content until @endphp
    final codeBuffer = StringBuffer();
    while (!_check(TokenType.directiveEndphp) && !_check(TokenType.eof)) {
      final token = _advance();
      codeBuffer.write(token.value);
    }

    if (_check(TokenType.directiveEndphp)) {
      _advance();
    } else {
      _errors.add(
        ParseError(
          message: 'Unclosed @php directive',
          position: startToken.startPosition,
          hint: 'Add @endphp to close the block',
        ),
      );
    }

    return PhpBlockNode(
      startPosition: startToken.startPosition,
      endPosition: _previous().endPosition,
      code: codeBuffer.toString(),
      syntax: PhpBlockSyntax.bladeDirective,
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
      rawExpression: expression,
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
    final tagHeadResult = _parseTagHead();
    final attributes = tagHeadResult.attributes;

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
    } else if (_check(TokenType.htmlTagClose)) {
      _advance(); // >
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

    // Parse tag head: attributes and structural directives
    final tagHeadResult = _parseTagHead();
    final attributes = tagHeadResult.attributes;
    final tagHead = tagHeadResult.tagHead;

    // Check for self-closing
    bool isSelfClosing = false;
    if (_check(TokenType.componentSelfClose)) {
      _advance(); // />
      isSelfClosing = true;
    } else if (_check(TokenType.htmlTagClose)) {
      _advance(); // >
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
      tagHead: tagHead,
      slots: slots,
      isSelfClosing: isSelfClosing,
      children: children,
    );
  }

  /// Parse generic directive with opening/closing tags.
  ///
  /// [alternateClosingTypes] allows additional token types to close the
  /// directive (e.g., @endif can close @unless in real-world Blade).
  DirectiveNode _parseGenericDirective(
    String name,
    TokenType closingType, {
    bool supportsElse = false,
    List<TokenType> alternateClosingTypes = const [],
  }) {
    final startToken = _advance();
    final expression = _extractExpression();
    final children = <AstNode>[];

    bool _isCloser() =>
        _check(closingType) || alternateClosingTypes.any(_check);

    while (!_isCloser() &&
        !_check(TokenType.eof) &&
        !(supportsElse && _check(TokenType.directiveElse))) {
      final node = _parseNode();
      if (node != null) children.add(node);
    }

    // Handle @else
    if (supportsElse && _check(TokenType.directiveElse)) {
      final elseToken = _advance();
      final elseChildren = <AstNode>[];

      while (!_isCloser() && !_check(TokenType.eof)) {
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

    if (!_isCloser()) {
      _errors.add(
        ParseError(
          message: 'Unclosed @$name directive',
          position: startToken.startPosition,
          hint: 'Add @${_closingDirectiveName(name)} to close the block',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @${_closingDirectiveName(name)}',
        startPosition: pos,
        endPosition: pos,
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
      // Block syntax - requires @endsection, @show, @stop, @append, or @overwrite (legacy)
      final children = <AstNode>[];

      final sectionClosers = [
        TokenType.directiveEndsection,
        TokenType.directiveShow,
        TokenType.directiveStop,
        TokenType.directiveAppend,
        TokenType.directiveOverwrite, // Legacy Laravel 4.x/5.x support
      ];

      while (!_checkAny(sectionClosers) && !_check(TokenType.eof)) {
        final node = _parseNode();
        if (node != null) children.add(node);
      }

      String? closedBy;
      if (!_checkAny(sectionClosers)) {
        _errors.add(
          ParseError(
            message: 'Unclosed @section directive',
            position: startToken.startPosition,
            hint:
                'Add @endsection, @show, @stop, or @append to close the block',
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
          hint: 'Add @${_closingDirectiveName(name)} to close the block',
        ),
      );
      final pos = _previous().endPosition;
      children.add(RecoveryNode(
        content: '',
        reason: 'missing @${_closingDirectiveName(name)}',
        startPosition: pos,
        endPosition: pos,
      ));
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
    return TokenType.attributeDirectives.contains(type);
  }

  /// Check if a token type is a Blade structural directive that can appear in tag heads.
  bool _isStructuralDirectiveToken(TokenType type) {
    // This covers @if, @elseif, @else, @endif, @foreach, @endforeach,
    // @unless, @endunless, @isset, @endisset, @empty, @endempty, etc.
    // We match any directive that is NOT an attribute directive and NOT an identifier.
    final name = type.name;
    return name.startsWith('directive') && !_isBladeAttributeDirective(type);
  }

  /// Parse the tag head, handling both attributes and structural directives.
  /// Returns attributes map (for backward compat) and ordered tag head items.
  ({Map<String, AttributeNode> attributes, List<TagHeadItem> tagHead})
      _parseTagHead() {
    final attributes = <String, AttributeNode>{};
    final tagHead = <TagHeadItem>[];
    var preserveTagHead = false;

    while (!_checkAny([
      TokenType.htmlTagClose,
      TokenType.htmlSelfClose,
      TokenType.componentSelfClose,
      TokenType.eof,
    ])) {
      final type = _peek().type;

      if (_isAttributeToken(type)) {
        // Parse attribute (same logic as _parseAttributeMap)
        final attrToken = _advance();
        final attrName = attrToken.value;
        final attrStartPos = attrToken.startPosition;
        Position attrEndPos = attrToken.endPosition;

        String? attrValue;
        String? quoteChar;

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
          quoteChar = _inferQuoteChar(valueToken);
        }

        final attrNode = _classifyAttribute(
            attrToken, attrName, attrValue, attrStartPos, attrEndPos,
            quoteChar: quoteChar);
        attributes[attrName] = attrNode;
        tagHead.add(TagHeadAttribute(attrName, attrNode));
      } else if (_isStructuralDirectiveToken(type)) {
        preserveTagHead = true;
        final token = _advance();
        // Extract directive name from token value (e.g., "@if" → "if")
        final directiveName = token.value.startsWith('@')
            ? token.value.substring(1)
            : token.value;
        String? expression;
        if (_check(TokenType.expression)) {
          expression = _advance().value.trim();
        }
        tagHead.add(TagHeadDirective(directiveName, expression: expression));
      } else if (type == TokenType.echoOpen ||
          type == TokenType.rawEchoOpen ||
          type == TokenType.bladeComment) {
        // Blade echo/raw-echo/comment inside tag attributes (e.g., {{ $attributes->class([...]) }})
        // Consume the echo tokens without creating an attribute node
        if (type == TokenType.echoOpen) {
          preserveTagHead = true;
          _advance(); // echoOpen
          String expr = '';
          if (_check(TokenType.expression)) {
            expr = _advance().value;
          }
          if (_check(TokenType.echoClose)) {
            _advance(); // echoClose
          }
          // Store as a special attribute with the expression as name
          final attrName = '{{ ${expr.trim()} }}';
          final attrNode = StandardAttribute(
            name: attrName,
            value: null,
            startPosition: _previous().startPosition,
            endPosition: _previous().endPosition,
          );
          attributes[attrName] = attrNode;
          tagHead.add(TagHeadAttribute(attrName, attrNode));
        } else if (type == TokenType.rawEchoOpen) {
          preserveTagHead = true;
          _advance(); // rawEchoOpen
          String expr = '';
          if (_check(TokenType.expression)) {
            expr = _advance().value;
          }
          if (_check(TokenType.rawEchoClose)) {
            _advance(); // rawEchoClose
          }
          final attrName = '{!! ${expr.trim()} !!}';
          final attrNode = StandardAttribute(
            name: attrName,
            value: null,
            startPosition: _previous().startPosition,
            endPosition: _previous().endPosition,
          );
          attributes[attrName] = attrNode;
          tagHead.add(TagHeadAttribute(attrName, attrNode));
        } else {
          // Blade comment - preserve in tag head
          preserveTagHead = true;
          final commentToken = _advance();
          tagHead.add(TagHeadComment(commentToken.value));
        }
      } else if (type == TokenType.phpBlock) {
        preserveTagHead = true;
        final phpToken = _advance();
        tagHead.add(TagHeadPhpBlock(phpToken.value));
      } else if (type == TokenType.tagHeadRaw) {
        preserveTagHead = true;
        final rawToken = _advance();
        tagHead.add(TagHeadRaw(rawToken.value));
      } else {
        // Skip unexpected tokens (whitespace, text between directives)
        _advance();
      }
    }

    // Preserve tagHead only when order/recovery details matter.
    return (
      attributes: attributes,
      tagHead: preserveTagHead ? tagHead : const [],
    );
  }

  /// Classify an attribute token into the appropriate AttributeNode subclass.
  AttributeNode _classifyAttribute(
    Token attrToken,
    String attrName,
    String? attrValue,
    Position startPos,
    Position endPos, {
    String? quoteChar,
  }) {
    // Check Blade attribute directives first (before Alpine, since @class starts with @)
    if (_isBladeAttributeDirective(attrToken.type)) {
      return StandardAttribute(
        name: attrName,
        value: attrValue,
        quoteChar: quoteChar,
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
        quoteChar: quoteChar,
        startPosition: startPos,
        endPosition: endPos,
      );
    } else if (isLivewireToken || attrName.startsWith('wire:')) {
      final parts = attrName.split('.');
      final head =
          parts[0].startsWith('wire:') ? parts[0].substring(5) : parts[0];
      final modifiers = parts.length > 1 ? parts.sublist(1) : <String>[];

      // Split head by ':' to extract sub-action (e.g., "sort:item" → "sort", "item")
      final colonIndex = head.indexOf(':');
      final String action;
      final String? subAction;
      if (colonIndex != -1) {
        action = head.substring(0, colonIndex);
        subAction = head.substring(colonIndex + 1);
      } else {
        action = head;
        subAction = null;
      }

      return LivewireAttribute(
        name: attrName,
        action: action,
        subAction: subAction,
        modifiers: modifiers,
        value: attrValue,
        quoteChar: quoteChar,
        startPosition: startPos,
        endPosition: endPos,
      );
    } else {
      return StandardAttribute(
        name: attrName,
        value: attrValue,
        quoteChar: quoteChar,
        startPosition: startPos,
        endPosition: endPos,
      );
    }
  }

  /// Handles a stray closing tag encountered at the top level or by
  /// [_parseNode]. Returns a [RecoveryNode] when the tag name is valid.
  AstNode? _parseStrayClosingTag() {
    final closingStartPos = _peek().startPosition;
    final closingTagName = _peekClosingTagName();
    final consumed = _consumeClosingTag();

    if (closingTagName != null) {
      if (_isVoidElement(closingTagName)) {
        _error(
          'Void element <$closingTagName> cannot have closing tag',
          closingStartPos,
        );
      } else {
        _error(
          'Unexpected closing tag </$closingTagName>',
          closingStartPos,
        );
      }
      return RecoveryNode(
        content: '</$closingTagName>',
        reason: 'stray closing tag </$closingTagName>',
        startPosition: closingStartPos,
        endPosition: consumed?.endPosition ?? _previous().endPosition,
      );
    }

    if (consumed == null) {
      _error('Expected tag name after </', closingStartPos);
    }

    return null;
  }

  /// Parse HTML element into HtmlElementNode (T031-T037).
  ///
  /// Handles opening tags, attributes, children, closing tags,
  /// self-closing syntax, and void elements.
  HtmlElementNode? _parseHtmlElement() {
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

    // Parse tag head: attributes and structural directives (T034)
    final tagHeadResult = _parseTagHead();
    final attributes = tagHeadResult.attributes;
    final tagHead = tagHeadResult.tagHead;

    // Check for self-closing or regular close
    bool isSelfClosing = false;
    Position? endPosition;

    if (_check(TokenType.htmlSelfClose)) {
      isSelfClosing = true;
      endPosition = _advance().endPosition; // consume '/>'

      return HtmlElementNode(
        tagName: tagName,
        attributes: attributes,
        tagHead: tagHead,
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
        tagHead: tagHead,
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
        final closingStartPos = _peek().startPosition;
        final closingTagName = _peekClosingTagName();

        if (closingTagName == null) {
          _advance(); // consume '</
          _error('Expected tag name after </', _peek().startPosition);
          break;
        }

        if (closingTagName == tagName) {
          final consumedClosingTag = _consumeClosingTag();
          final closingEndPos =
              consumedClosingTag?.endPosition ?? _previous().endPosition;

          _tagStack.removeLast(); // Pop from stack (T032)

          return HtmlElementNode(
            tagName: tagName,
            attributes: attributes,
            tagHead: tagHead,
            startPosition: openingTagPos,
            endPosition: closingEndPos,
            children: children,
          );
        }

        if (_hasAncestorTagOnStack(closingTagName)) {
          _error(
            'Expected </$tagName>, found </$closingTagName>; auto-closing <$tagName> for recovery',
            closingStartPos,
          );
          _tagStack.removeLast();

          final recoveredEndPos =
              children.isNotEmpty ? children.last.endPosition : endPosition!;

          return HtmlElementNode(
            tagName: tagName,
            attributes: attributes,
            tagHead: tagHead,
            startPosition: openingTagPos,
            endPosition: recoveredEndPos,
            children: children,
          );
        }

        _error(
          'Unexpected closing tag </$closingTagName> inside <$tagName>',
          closingStartPos,
        );
        final consumed = _consumeClosingTag();
        if (consumed != null) {
          children.add(RecoveryNode(
            content: '</${consumed.name}>',
            reason: 'stray closing tag </${consumed.name}>',
            startPosition: closingStartPos,
            endPosition: consumed.endPosition,
          ));
        }
        continue;
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
      tagHead: tagHead,
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

  String? _peekClosingTagName() {
    if (!_check(TokenType.htmlClosingTagStart)) return null;
    if (_current + 1 >= _tokens.length) return null;

    final nameToken = _tokens[_current + 1];
    if (nameToken.type != TokenType.htmlTagName) return null;

    return nameToken.value.toLowerCase();
  }

  bool _hasAncestorTagOnStack(String tagName) {
    if (_tagStack.length < 2) return false;

    for (var i = _tagStack.length - 2; i >= 0; i--) {
      if (_tagStack[i].tagName == tagName) {
        return true;
      }
    }

    return false;
  }

  ({String name, Position startPosition, Position endPosition})?
      _consumeClosingTag() {
    if (!_check(TokenType.htmlClosingTagStart)) return null;

    final startPosition = _advance().startPosition; // consume '</

    if (!_check(TokenType.htmlTagName)) {
      return null;
    }

    final tagNameToken = _advance();
    var endPosition = tagNameToken.endPosition;

    if (_check(TokenType.htmlClosingTagEnd)) {
      endPosition = _advance().endPosition;
    }

    return (
      name: tagNameToken.value.toLowerCase(),
      startPosition: startPosition,
      endPosition: endPosition,
    );
  }
}

/// Tag stack entry for tracking open tags (T032)
class _TagStackEntry {
  final String tagName;
  final Position startPosition;

  _TagStackEntry(this.tagName, this.startPosition);
}
