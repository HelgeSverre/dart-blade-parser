import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/indent_tracker.dart';
import 'package:blade_parser/src/lexer/token_type.dart';

/// A StringBuffer wrapper that tracks the last two characters written,
/// avoiding O(n) toString() calls for endsWith checks.
class _TrackedBuffer {
  final StringBuffer _buffer = StringBuffer();
  String _lastTwo = '';

  bool get isEmpty => _buffer.isEmpty;

  void write(Object? obj) {
    final s = obj.toString();
    _buffer.write(s);
    _updateTrailing(s);
  }

  void writeln([Object? obj = '']) {
    final s = obj.toString();
    _buffer.write(s);
    _buffer.write('\n');
    _updateTrailing('$s\n');
  }

  void _updateTrailing(String s) {
    if (s.isEmpty) return;
    if (s.length >= 2) {
      _lastTwo = s.substring(s.length - 2);
    } else {
      _lastTwo = (_lastTwo.isNotEmpty ? _lastTwo[_lastTwo.length - 1] : '') + s;
    }
  }

  bool endsWithNewline() => _lastTwo.endsWith('\n');
  bool endsWithDoubleNewline() => _lastTwo == '\n\n';

  void clear() {
    _buffer.clear();
    _lastTwo = '';
  }

  @override
  String toString() => _buffer.toString();
}

/// Visitor that traverses an AST and generates formatted Blade template output.
///
/// This visitor implements the formatting logic for all AST node types,
/// handling indentation, spacing, and line breaks according to the
/// formatter configuration.
class FormatterVisitor implements AstVisitor<String> {
  final FormatterConfig config;
  final IndentTracker _indent;
  final _TrackedBuffer _output = _TrackedBuffer();

  /// Original source for raw output in ignored sections.
  final String? _source;

  /// Whether formatting is currently enabled.
  ///
  /// Set to `false` when encountering a `blade-formatter:off` comment,
  /// and back to `true` when encountering `blade-formatter:on`.
  bool _formattingEnabled = true;

  /// Block-level HTML elements that should get blank line spacing between siblings.
  static const Set<String> _blockElements = {
    'div',
    'p',
    'section',
    'article',
    'aside',
    'header',
    'footer',
    'nav',
    'main',
    'figure',
    'figcaption',
    'details',
    'summary',
    'form',
    'fieldset',
    'table',
    'blockquote',
    'pre',
    'address',
    'dl',
    'ol',
    'ul',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'hgroup',
    'dialog',
    'search',
  };

  /// Raw text elements whose content indentation should be preserved.
  static const Set<String> _rawTextElements = {
    'script',
    'style',
    'textarea',
    'pre',
  };

  /// Inline (phrasing) HTML elements that may stay on the same line as
  /// surrounding text. Used by the inline-content path to avoid breaking
  /// prose apart with newlines.
  static const Set<String> _inlineElements = {
    'a',
    'abbr',
    'b',
    'bdi',
    'bdo',
    'br',
    'cite',
    'code',
    'data',
    'dfn',
    'em',
    'i',
    'kbd',
    'mark',
    'q',
    'rp',
    'rt',
    'ruby',
    's',
    'samp',
    'small',
    'span',
    'strong',
    'sub',
    'sup',
    'time',
    'u',
    'var',
    'wbr',
  };

  /// HTML void elements that should not have closing tags.
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

  /// Block-level directives that are intermediate (no @end tag of their own).
  /// These appear inside other block directives (e.g., @elseif inside @if/@endif).
  /// Note: @empty is context-dependent — intermediate inside @forelse (no expression),
  /// but standalone as @empty($var)...@endempty (has expression).
  static const Set<String> _intermediateDirectives = {
    'elseif',
    'else',
    'case',
    'default',
  };

  /// Blade directives that are block-level (require children).
  static const Set<String> _blockDirectives = {
    'if',
    'elseif',
    'else',
    'unless',
    'foreach',
    'forelse',
    'for',
    'while',
    'switch',
    'case',
    'default',
    'auth',
    'guest',
    'can',
    'cannot',
    'canany',
    'env',
    'production',
    'section',
    'push',
    'prepend',
    'once',
    'verbatim',
    'error',
    'component',
    'fragment',
    'session',
    'pushOnce',
    'prependOnce',
    'pushIf',
    'script',
    'assets',
    'isset',
    'empty',
    'slot',
    'context',
    'hasStack',
    'teleport',
    'persist',
  };

  /// Blade directives that are inline (no children, single line).
  static const Set<String> _inlineDirectives = {
    'yield',
    'show',
    'stop',
    'append',
    'endsection',
    'extends',
    'include',
    'includeIf',
    'includeWhen',
    'includeUnless',
    'includeFirst',
    'each',
    'csrf',
    'method',
    'vite',
    'json',
    'inject',
    'use',
    'dd',
    'dump',
    'props',
    'aware',
    'stack',
    'hasSection',
    'sectionMissing',
    'break',
    'continue',
    'empty', // Can be both, but often inline in context
    'entangle',
    'this',
    'js',
    'livewireStyles',
    'livewireScripts',
    'livewireScriptConfig',
    'filamentStyles',
    'filamentScripts',
  };

  /// Standard HTML attributes that should appear first when sorting by type.
  static const Set<String> _standardHtmlAttributes = {
    'id',
    'class',
    'style',
    'type',
    'name',
    'value',
    'href',
    'src',
    'alt',
    'title',
    'width',
    'height',
    'disabled',
    'readonly',
    'required',
    'checked',
    'selected',
    'placeholder',
    'action',
    'method',
    'target',
    'rel',
    'for',
    'role',
    'tabindex',
    'aria-label',
    'aria-hidden',
    'aria-describedby',
  };

  FormatterVisitor(this.config, {String? source})
      : _source = source,
        _indent = IndentTracker(config);

  /// Ensures the output is at the start of a new line, then writes indentation.
  ///
  /// This prevents mid-line indentation injection which causes idempotency
  /// failures: if a text node doesn't write a trailing newline, the next
  /// block-level node must not append indentation on the same line.
  void _beginLine() {
    if (!_output.endsWithNewline() && !_output.isEmpty) {
      _output.writeln();
    }
    _output.write(_indent.current);
  }

  /// Formats the AST and returns the formatted string.
  String format(AstNode node) {
    _output.clear();
    _indent.reset();
    _formattingEnabled = true;
    node.accept(this);
    return _output.toString();
  }

  /// Checks if a comment is a formatter control comment.
  ///
  /// Returns 'off' if it disables formatting, 'on' if it enables formatting,
  /// or null if it's not a control comment.
  ///
  /// Supports the following patterns (case-insensitive):
  /// - `blade-formatter:off` / `blade-formatter:on`
  /// - `blade-formatter-disable` / `blade-formatter-enable`
  /// - `format:off` / `format:on`
  String? _getFormatterControl(String content) {
    // Normalize the content by stripping comment delimiters and trimming
    var text = content;

    // Strip Blade comment delimiters
    if (text.startsWith('{{--')) {
      text = text.substring(4);
    }
    if (text.endsWith('--}}')) {
      text = text.substring(0, text.length - 4);
    }

    // Strip HTML comment delimiters
    if (text.startsWith('<!--')) {
      text = text.substring(4);
    }
    if (text.endsWith('-->')) {
      text = text.substring(0, text.length - 3);
    }

    text = text.trim().toLowerCase();

    // Check for off commands
    if (text == 'blade-formatter:off' ||
        text == 'blade-formatter-disable' ||
        text == 'format:off') {
      return 'off';
    }

    // Check for on commands
    if (text == 'blade-formatter:on' ||
        text == 'blade-formatter-enable' ||
        text == 'format:on') {
      return 'on';
    }

    return null;
  }

  /// Outputs the raw source text for a node.
  ///
  /// Used when formatting is disabled to preserve the original text.
  void _outputRaw(AstNode node) {
    if (_source == null) return;

    final start = node.startPosition.offset;
    final end = node.endPosition.offset;

    if (start >= 0 && end <= _source!.length && start < end) {
      _output.write(_source!.substring(start, end));
    }
  }

  /// Renders an echo node's delimiters and expression according to echoSpacing config.
  String _renderEchoString(EchoNode node) {
    final String inner;
    switch (config.echoSpacing) {
      case EchoSpacing.spaced:
        inner = ' ${node.expression} ';
      case EchoSpacing.compact:
        inner = node.expression;
      case EchoSpacing.preserve:
        inner = node.rawExpression;
    }
    return node.isRaw ? '{!!$inner!!}' : '{{$inner}}';
  }

  /// Checks if the original source has a blank line between two nodes.
  ///
  /// Used by preserve-style spacing configs to detect whether the author
  /// intended a visual break between elements.
  bool _sourceHasBlankLineBetween(AstNode a, AstNode b) {
    final source = _source;
    if (source == null) return false;
    final start = a.endPosition.offset;
    final end = b.startPosition.offset;
    if (start < 0 || end > source.length || start >= end) return false;
    final gap = source.substring(start, end);
    return RegExp(r'\n[ \t]*\n').hasMatch(gap);
  }

  /// Returns the category priority for an attribute (for byType sorting).
  /// Lower numbers come first.
  int _getAttributeCategory(String name) {
    // 1. Standard HTML attributes
    if (_standardHtmlAttributes.contains(name.toLowerCase())) {
      return 1;
    }
    // 2. Data attributes
    if (name.startsWith('data-')) {
      return 2;
    }
    // 3. Alpine.js attributes (x-*, @*, :*)
    if (name.startsWith('x-') || name.startsWith('@') || name.startsWith(':')) {
      return 3;
    }
    // 4. Livewire attributes (wire:*)
    if (name.startsWith('wire:')) {
      return 4;
    }
    // 5. Other attributes
    return 5;
  }

  /// Sorts attributes according to the configured sort order.
  List<AttributeNode> _sortAttributes(Iterable<AttributeNode> attributes) {
    final list = attributes.toList();

    switch (config.attributeSort) {
      case AttributeSort.none:
        return list;

      case AttributeSort.alphabetical:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;

      case AttributeSort.byType:
        list.sort((a, b) {
          final catA = _getAttributeCategory(a.name);
          final catB = _getAttributeCategory(b.name);
          if (catA != catB) {
            return catA.compareTo(catB);
          }
          // Within same category, sort alphabetically
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return list;
    }
  }

  /// Formats a single attribute and returns its string representation.
  String _formatAttribute(AttributeNode attr) {
    if (attr.value == null) {
      return attr.name;
    }
    // Blade attribute directives use expression syntax: @class(['dark' => true])
    // No = sign or quotes needed, just append the expression directly
    if (attr.name.startsWith('@') &&
        _isBladeAttributeDirectiveName(attr.name)) {
      return '${attr.name}${attr.value}';
    }
    return '${attr.name}=${_formatAttributeValue(attr.value!, sourceQuoteChar: attr.quoteChar)}';
  }

  /// Check if an attribute name is a Blade attribute directive.
  bool _isBladeAttributeDirectiveName(String name) {
    // Strip @ prefix and look up in the shared source of truth
    if (!name.startsWith('@')) return false;
    return TokenType.attributeDirectivesByName.containsKey(name.substring(1));
  }

  /// Calculates the length of the opening tag if all attributes were on one line.
  int _calculateSingleLineTagLength(
      String tagName, List<AttributeNode> attributes,
      {bool isComponent = false, bool isSelfClosing = false}) {
    final prefix = isComponent ? '<x-$tagName' : '<$tagName';
    var length = _indent.current.length + prefix.length;

    for (final attr in attributes) {
      length += 1 + _formatAttribute(attr).length; // +1 for space
    }

    length += isSelfClosing ? 3 : 1; // ' />' or '>'
    return length;
  }

  /// Determines if attributes should be wrapped to multiple lines.
  bool _shouldWrapAttributes(String tagName, List<AttributeNode> attributes,
      {bool isComponent = false, bool isSelfClosing = false}) {
    if (attributes.isEmpty) return false;

    switch (config.wrapAttributes) {
      case WrapAttributes.always:
        return attributes.length > 1;

      case WrapAttributes.never:
        return false;

      case WrapAttributes.auto:
        final lineLength = _calculateSingleLineTagLength(
          tagName,
          attributes,
          isComponent: isComponent,
          isSelfClosing: isSelfClosing,
        );
        return lineLength > config.maxLineLength;
    }
  }

  /// Writes tag head items (attributes + structural directives), always wrapped.
  /// Used when the tag head contains structural directives like @if/@endif.
  void _writeTagHead(List<TagHeadItem> items,
      {required String closingBracket}) {
    if (items.isEmpty) {
      _output.write(closingBracket);
      return;
    }

    // Tag heads with directives always wrap to multiple lines
    _output.writeln();
    _indent.increase();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      _output.write(_indent.current);

      if (item is TagHeadAttribute) {
        _output.write(_formatAttribute(item.attribute));
      } else if (item is TagHeadDirective) {
        _output.write('@${item.name}');
        if (item.expression != null) {
          // Expression already includes parentheses from the lexer
          _output.write(item.expression!);
        }
      } else if (item is TagHeadComment) {
        _output.write(item.content);
      } else if (item is TagHeadPhpBlock) {
        _output.write(item.content);
      }

      final isLast = i == items.length - 1;
      if (isLast) {
        if (config.closingBracketStyle == ClosingBracketStyle.newLine) {
          _output.writeln();
          _indent.decrease();
          _output.write(_indent.current);
          _output.write(closingBracket.trim());
        } else {
          _output.write(closingBracket);
          _indent.decrease();
        }
      } else {
        _output.writeln();
      }
    }
  }

  /// Writes attributes, either inline or wrapped to multiple lines.
  void _writeAttributes(List<AttributeNode> attributes,
      {required bool wrap, required String closingBracket}) {
    if (attributes.isEmpty) {
      _output.write(closingBracket);
      return;
    }

    final sortedAttrs = _sortAttributes(attributes);

    if (wrap) {
      // Multi-line formatting: one attribute per line
      _output.writeln();
      _indent.increase();

      for (var i = 0; i < sortedAttrs.length; i++) {
        _output.write(_indent.current);
        _output.write(_formatAttribute(sortedAttrs[i]));

        final isLastAttr = i == sortedAttrs.length - 1;

        if (isLastAttr) {
          // Last attribute - closing bracket placement depends on style
          if (config.closingBracketStyle == ClosingBracketStyle.newLine) {
            // Bracket on its own line
            _output.writeln();
            _indent.decrease();
            _output.write(_indent.current);
            _output.write(closingBracket.trim());
          } else {
            // Bracket on same line as last attribute (default)
            _output.write(closingBracket);
            _indent.decrease();
          }
        } else {
          _output.writeln();
        }
      }
    } else {
      // Single-line formatting: all attributes on same line
      for (final attr in sortedAttrs) {
        _output.write(' ');
        _output.write(_formatAttribute(attr));
      }
      _output.write(closingBracket);
    }
  }

  /// Formats an attribute value with the appropriate quote style.
  ///
  /// Handles escaping and quote style conversion based on config.quoteStyle.
  String _formatAttributeValue(String value, {String? sourceQuoteChar}) {
    String quote;
    if (config.quoteStyle == QuoteStyle.preserve) {
      quote = sourceQuoteChar ?? '"';
    } else {
      quote = config.quoteStyle.quoteChar;
    }

    // If the value contains Blade echo expressions ({{ }}, {!! !!}), the echo
    // content may contain quotes that must not be escaped (HTML doesn't support
    // backslash escaping). Choose the quote style that avoids conflicts, or
    // output the value as-is if it contains both.
    if (value.contains('{{') || value.contains('{!!')) {
      if (quote == '"' && value.contains('"')) {
        // Try switching to single quotes if the value doesn't also contain them
        if (!value.contains("'")) {
          quote = "'";
        }
        // Otherwise keep double quotes — the value will be output as-is since
        // the quotes are inside Blade expressions which are opaque to HTML.
        return '$quote$value$quote';
      }
      if (quote == "'" && value.contains("'")) {
        if (!value.contains('"')) {
          quote = '"';
        }
        return '$quote$value$quote';
      }
      return '$quote$value$quote';
    }

    // Plain HTML attribute values: escape quotes normally
    String escaped = value;
    if (quote == "'") {
      escaped = value.replaceAll(r"\'", "'").replaceAll("'", r"\'");
    } else {
      escaped = value.replaceAll(r'\"', '"').replaceAll('"', r'\"');
    }

    return '$quote$escaped$quote';
  }

  @override
  String visitDocument(DocumentNode node) {
    for (var i = 0; i < node.children.length; i++) {
      final child = node.children[i];

      // Handle whitespace-only text nodes that represent blank lines
      // Only apply this logic when formatting is enabled
      if (_formattingEnabled &&
          child is TextNode &&
          child.content.trim().isEmpty) {
        // Count the number of newlines in this text node
        final newlineCount = '\n'.allMatches(child.content).length;

        // If there are 2+ newlines, it represents intentional blank line(s)
        // Preserve one blank line (we already have one from previous element's writeln)
        if (newlineCount >= 2 && !_output.endsWithDoubleNewline()) {
          _output.writeln();
        }
        continue;
      }

      child.accept(this);

      // Add spacing between top-level elements (only when formatting is enabled)
      if (_formattingEnabled && i < node.children.length - 1) {
        // Find the next meaningful (non-whitespace) node
        AstNode? nextMeaningful;
        for (var j = i + 1; j < node.children.length; j++) {
          final candidate = node.children[j];
          if (candidate is! TextNode || candidate.content.trim().isNotEmpty) {
            nextMeaningful = candidate;
            break;
          }
        }

        if (nextMeaningful != null &&
            _needsSpacingBetween(child, nextMeaningful)) {
          _output.writeln();
        }
      }
    }

    if (config.trailingNewline) {
      // Ensure file ends with newline
      final isEmpty = _output.toString().isEmpty;
      if (isEmpty) {
        if (node.children.isNotEmpty) {
          _output.writeln();
        }
      } else if (!_output.endsWithNewline()) {
        _output.writeln();
      }
    } else {
      // Strip trailing newline if present
      final str = _output.toString();
      if (str.endsWith('\n')) {
        _output.clear();
        _output.write(str.substring(0, str.length - 1));
      }
    }

    return _output.toString();
  }

  @override
  String visitDirective(DirectiveNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Known block directives, or unknown directives that were parsed with children
    final isBlock =
        _blockDirectives.contains(node.name) || node.children.isNotEmpty;

    // Write the directive opening
    _beginLine();
    _output.write('@${node.name}');

    // Add expression if present (already includes parentheses from parser)
    if (node.expression != null && node.expression!.isNotEmpty) {
      _output.write(node.expression);
    }

    _output.writeln();

    // Format children with increased indentation
    if (node.children.isNotEmpty) {
      _indent.increase();

      for (var i = 0; i < node.children.length; i++) {
        final child = node.children[i];

        // Skip whitespace-only text nodes to maintain idempotency
        if (child is TextNode && child.content.trim().isEmpty) {
          continue;
        }

        // Intermediate directives (@else, @elseif, @case, @default, @empty inside @forelse)
        // should align with the parent directive, not be indented inside it.
        if (child is DirectiveNode && _isIntermediateDirective(child)) {
          _indent.decrease();
          child.accept(this);
          _indent.increase();
        } else {
          child.accept(this);
        }

        // Add spacing between children if needed
        if (i < node.children.length - 1) {
          AstNode? nextMeaningful;
          for (var j = i + 1; j < node.children.length; j++) {
            final candidate = node.children[j];
            if (candidate is! TextNode || candidate.content.trim().isNotEmpty) {
              nextMeaningful = candidate;
              break;
            }
          }

          if (nextMeaningful != null &&
              _needsSpacingBetween(child, nextMeaningful)) {
            _output.writeln();
          }
        }
      }

      _indent.decrease();
    }

    // Write closing directive if this is a block directive with children
    // Inline directives (like @section('title', 'value')) don't get closing tags
    if (isBlock &&
        node.children.isNotEmpty &&
        _hasClosingDirective(node.name, expression: node.expression)) {
      _beginLine();
      if (node.closedBy != null) {
        _output.write('@${node.closedBy}');
      } else {
        _output.write('@${_closingDirectiveName(node.name)}');
      }
      _output.writeln();
    }

    return '';
  }

  @override
  String visitEcho(EchoNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Inside raw text elements (script/style/textarea/pre), echo expressions
    // should be output inline without indentation or trailing newline,
    // preserving the surrounding raw text context.
    final parent = node.parent;
    final inRawText = parent is HtmlElementNode &&
        _rawTextElements.contains(parent.tagName.toLowerCase());

    if (inRawText) {
      _output.write(_renderEchoString(node));
      return '';
    }

    // Only write indentation if we're at the start of a line
    // (not continuing inline after text like "Deadline: {{ $date }}")
    if (_output.endsWithNewline()) {
      _output.write(_indent.current);
    }

    _output.write(_renderEchoString(node));

    _output.writeln();
    return '';
  }

  @override
  String visitText(TextNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Handle text content carefully to preserve meaningful whitespace
    final content = node.content;

    // Skip empty text nodes
    if (content.trim().isEmpty && content.length < 2) {
      return '';
    }

    // If text contains only whitespace and newlines, preserve one newline
    if (content.trim().isEmpty) {
      if (!_output.endsWithDoubleNewline()) {
        _output.writeln();
      }
      return '';
    }

    // Check if we're inside a raw text element (script/style/textarea/pre)
    // and should preserve relative indentation of the content.
    final parent = node.parent;
    if (parent is HtmlElementNode &&
        _rawTextElements.contains(parent.tagName.toLowerCase())) {
      return _visitRawTextContent(content);
    }

    // Split text by lines to handle multi-line text
    final lines = content.split('\n');

    // On the last line, preserve trailing whitespace only if the next
    // meaningful sibling is an echo node (for inline continuation like
    // "Deadline: {{ $date }}"). For all other siblings (HTML elements,
    // directives, etc.), they start on their own line via _beginLine(),
    // so trailing space would create idempotency issues.
    final preserveTrailing = _nextMeaningSiblingIsEcho(node);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final trimmedLine =
          (isLastLine && preserveTrailing) ? line.trimLeft() : line.trim();

      if (trimmedLine.isNotEmpty) {
        // Check if this line should be indented
        // Don't indent if it's in the middle of inline content
        if (i == 0 && !_output.endsWithNewline()) {
          _output.write(line);
        } else {
          _output.write(_indent.current);
          _output.write(trimmedLine);
        }

        if (!isLastLine) {
          _output.writeln();
        }
      }
    }

    return '';
  }

  /// Handles text content inside raw text elements (script/style/textarea/pre).
  ///
  /// Preserves the relative indentation structure of the content while
  /// re-basing it to the current formatter indent level.
  String _visitRawTextContent(String content) {
    final lines = content.split('\n');

    // Find the minimum indentation of non-empty lines (excluding the first
    // line which is typically on the same line as the opening tag).
    int? minIndent;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final indent = line.length - line.trimLeft().length;
      if (minIndent == null || indent < minIndent) {
        minIndent = indent;
      }
    }
    minIndent ??= 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (i == 0) {
        // First line: typically right after <script>, may be empty or have content
        final trimmed = line.trimLeft();
        if (trimmed.isNotEmpty) {
          if (!_output.endsWithNewline()) {
            _output.write(trimmed);
          } else {
            _output.write(_indent.current);
            _output.write(trimmed);
          }
          if (i < lines.length - 1) {
            _output.writeln();
          }
        } else if (lines.length > 1) {
          // Empty first line (content starts with newline) - output the newline
          if (!_output.endsWithNewline()) {
            _output.writeln();
          }
        }
        continue;
      }

      if (line.trim().isEmpty) {
        // Preserve blank lines within the content
        if (i < lines.length - 1) {
          _output.writeln();
        }
        continue;
      }

      // Strip the base indentation and re-indent relative to current level
      final currentLineIndent = line.length - line.trimLeft().length;
      final relativeIndent = currentLineIndent - minIndent;
      final extraIndent = relativeIndent > 0 ? ' ' * relativeIndent : '';

      _output.write(_indent.current);
      _output.write(extraIndent);
      _output.write(line.trimLeft());

      if (i < lines.length - 1) {
        _output.writeln();
      }
    }

    return '';
  }

  @override
  String visitHtmlElement(HtmlElementNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    final tagName = node.tagName.toLowerCase();
    final isVoid = _voidElements.contains(tagName);
    final attributes = node.attributes.values.toList();

    // Check if element has meaningful content
    final hasContent = node.children.any(
      (child) => child is! TextNode || child.content.trim().isNotEmpty,
    );

    // Determine if we should format as self-closing
    final shouldSelfClose =
        !isVoid && !hasContent && _shouldSelfClose(node.isSelfClosing);

    // Write opening tag
    _beginLine();
    _output.write('<${node.tagName}');

    // If tag head contains structural directives, use the ordered tag head
    if (node.tagHead.isNotEmpty) {
      final closingBracket = isVoid
          ? '>'
          : shouldSelfClose
              ? ' />'
              : '>';
      _writeTagHead(node.tagHead, closingBracket: closingBracket);

      if (isVoid || shouldSelfClose) {
        _output.writeln();
        return '';
      }
    } else {
      // Normal attribute-only formatting
      final shouldWrap = _shouldWrapAttributes(
        node.tagName,
        attributes,
        isSelfClosing: isVoid || shouldSelfClose,
      );

      if (isVoid) {
        _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');
        _output.writeln();
        return '';
      }

      if (shouldSelfClose) {
        _writeAttributes(attributes, wrap: shouldWrap, closingBracket: ' />');
        _output.writeln();
        return '';
      }

      _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');
    }

    // Raw text elements (script/style/textarea/pre): reconstruct full content
    // from all children (text + echo + comment nodes) and preserve indentation.
    // Only use this path if all children are raw-text-safe (text, echo, comment).
    if (_rawTextElements.contains(tagName) && node.children.isNotEmpty) {
      final allRawTextSafe = node.children.every(
        (child) =>
            child is TextNode || child is EchoNode || child is CommentNode,
      );

      if (allRawTextSafe) {
        // Reconstruct the full raw content including Blade expressions
        final rawContent = StringBuffer();
        for (final child in node.children) {
          if (child is TextNode) {
            rawContent.write(child.content);
          } else if (child is EchoNode) {
            rawContent.write(_renderEchoString(child));
          } else if (child is CommentNode) {
            rawContent.write(child.content);
          }
        }

        // Use the same raw text content rendering as visitText
        _indent.increase();
        _visitRawTextContent(rawContent.toString());
        _indent.decrease();

        // Write closing tag
        _beginLine();
        _output.write('</${node.tagName}>');
        _output.writeln();
        return '';
      }
    }

    // Format children
    if (node.children.isNotEmpty) {
      // Filter out whitespace-only text nodes for inline check
      final meaningfulChildren = node.children
          .where((c) => c is! TextNode || c.content.trim().isNotEmpty)
          .toList();

      // Check if we can keep content inline
      // Allow inline if: all meaningful children are inline-renderable
      // (simple text, echo, or inline HTML elements with simple content)
      // BUT: if there are newlines in whitespace between meaningful children, don't inline
      // Also: if the tag head is not empty (opening tag spans multiple lines due
      // to structural directives), always use block formatting for children.
      // The totalLineLength calculation assumes a single-line opening tag and
      // would produce unstable results when attributes are wrapped.
      var canKeepInline = node.tagHead.isEmpty &&
          meaningfulChildren.isNotEmpty &&
          meaningfulChildren.every(_isInlineRenderableNode);

      // Check for newlines between meaningful children
      if (canKeepInline && meaningfulChildren.length > 1) {
        // Look for newlines in whitespace text nodes between meaningful children
        for (var i = 0; i < node.children.length - 1; i++) {
          final child = node.children[i];
          // If this is a meaningful child, check if the next nodes contain newlines
          if (meaningfulChildren.contains(child)) {
            // Check following whitespace nodes until we hit another meaningful child
            for (var j = i + 1; j < node.children.length; j++) {
              final next = node.children[j];
              if (meaningfulChildren.contains(next)) {
                break; // Found next meaningful child
              }
              // Check if this whitespace node contains a newline
              if (next is TextNode && next.content.contains('\n')) {
                canKeepInline = false;
                break;
              }
            }
            if (!canKeepInline) break;
          }
        }
      }

      if (canKeepInline) {
        // Keep simple content inline
        // Build the inline content, preserving spaces between elements.
        // Iterate all children (not just meaningful ones) to preserve
        // whitespace-only text nodes like the space in "{{ $a }} {{ $b }}".
        final firstMeaningful = meaningfulChildren.first;
        final lastMeaningful = meaningfulChildren.last;
        final inlineContent = StringBuffer();
        var seenFirstMeaningful = false;
        var pastLastMeaningful = false;
        for (final child in node.children) {
          if (child == firstMeaningful) seenFirstMeaningful = true;
          if (pastLastMeaningful) break;
          if (child is TextNode) {
            var text = child.content;
            if (child == firstMeaningful) {
              text = text.trimLeft();
            }
            if (child == lastMeaningful) {
              text = text.trimRight();
            }
            // Whitespace-only text: skip if outside meaningful range,
            // collapse to single space if between meaningful children.
            if (text.trim().isEmpty) {
              if (seenFirstMeaningful && text.isNotEmpty) {
                inlineContent.write(' ');
              }
            } else {
              inlineContent.write(text);
            }
          } else {
            inlineContent.write(_renderInlineNode(child));
          }
          if (child == lastMeaningful) pastLastMeaningful = true;
        }

        // Check if the complete line fits within maxLineLength.
        // If not, fall through to block formatting to avoid unstable
        // toggling between inline/block across formatting passes.
        final closingTag = '</${node.tagName}>';
        final totalLineLength = _indent.current.length +
            '<${node.tagName}'.length +
            attributes.fold<int>(
                0, (sum, a) => sum + 1 + _formatAttribute(a).length) +
            '>'.length +
            inlineContent.length +
            closingTag.length;

        if (totalLineLength <= config.maxLineLength) {
          _output.write(inlineContent.toString());
          _output.write(closingTag);
          _output.writeln();
          return '';
        }
        // Line too long — fall through to block formatting
      }

      // Block formatting: children on new lines with indentation
      _output.writeln();
      _indent.increase();

      for (var i = 0; i < node.children.length; i++) {
        final child = node.children[i];

        // Skip whitespace-only text nodes in block mode
        if (child is TextNode && child.content.trim().isEmpty) {
          continue;
        }

        child.accept(this);

        // Add spacing between children if needed
        if (i < node.children.length - 1) {
          // Find the next meaningful (non-whitespace) node
          AstNode? nextMeaningful;
          for (var j = i + 1; j < node.children.length; j++) {
            final candidate = node.children[j];
            if (candidate is! TextNode || candidate.content.trim().isNotEmpty) {
              nextMeaningful = candidate;
              break;
            }
          }

          if (nextMeaningful != null &&
              _needsSpacingBetween(child, nextMeaningful)) {
            _output.writeln();
          }
        }
      }

      _indent.decrease();
      _beginLine();
    }

    // Write closing tag
    _output.write('</${node.tagName}>');
    _output.writeln();

    return '';
  }

  @override
  String visitComponent(ComponentNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    final attributes = node.attributes.values.toList();

    // Check if component has content (slots or non-whitespace children)
    final hasContent = node.slots.isNotEmpty ||
        node.children.any(
          (child) => child is! TextNode || child.content.trim().isNotEmpty,
        );

    // Determine if we should format as self-closing
    final shouldSelfClose = !hasContent && _shouldSelfClose(node.isSelfClosing);

    // Write opening tag
    _beginLine();
    _output.write('<x-${node.name}');

    // If tag head contains structural directives, use ordered tag head
    if (node.tagHead.isNotEmpty) {
      final closingBracket = shouldSelfClose ? ' />' : '>';
      _writeTagHead(node.tagHead, closingBracket: closingBracket);

      if (shouldSelfClose) {
        _output.writeln();
        return '';
      }

      if (!hasContent) {
        _output.write('</x-${node.name}>');
        _output.writeln();
        return '';
      }
    } else {
      // Normal attribute-only formatting
      final shouldWrap = _shouldWrapAttributes(
        node.name,
        attributes,
        isComponent: true,
        isSelfClosing: shouldSelfClose,
      );

      // Handle self-closing components
      if (shouldSelfClose) {
        _writeAttributes(attributes, wrap: shouldWrap, closingBracket: ' />');
        _output.writeln();
        return '';
      }

      // For empty components with selfClosingStyle.never, output explicit close
      if (!hasContent) {
        _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');
        _output.write('</x-${node.name}>');
        _output.writeln();
        return '';
      }

      _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');
    }

    // Format children
    // Check if we can keep content inline
    // If there's only a default slot with simple text, render it inline without slot tags
    // Skip inline optimization when tag head has directives (unstable line length)
    final hasOnlyDefaultSlot = node.tagHead.isEmpty &&
        node.slots.length == 1 &&
        node.slots.containsKey('default') &&
        node.slots['default']!.children.length == 1 &&
        node.slots['default']!.children.first is TextNode &&
        !(node.slots['default']!.children.first as TextNode)
            .content
            .contains('\n');

    if (hasOnlyDefaultSlot) {
      // Keep simple default slot content inline (without slot tags)
      final text =
          (node.slots['default']!.children.first as TextNode).content.trim();
      _output.write(text);
      _output.write('</x-${node.name}>');
      _output.writeln();
      return '';
    }

    // Block formatting for complex content
    _output.writeln();
    _indent.increase();

    // If there's a default slot, render it instead of children
    final hasDefaultSlot = node.slots.containsKey('default');

    if (hasDefaultSlot) {
      // Render all named slots (including default)
      final slotList = node.slots.values.toList();
      for (var i = 0; i < slotList.length; i++) {
        final slot = slotList[i];
        slot.accept(this);

        // Add spacing between slots if needed
        if (i < slotList.length - 1) {
          if (_needsSpacingBetween(slot, slotList[i + 1])) {
            _output.writeln();
          }
        }
      }
    } else {
      // First, format named slots (non-default)
      final slotList = node.slots.values.toList();
      for (var i = 0; i < slotList.length; i++) {
        final slot = slotList[i];
        slot.accept(this);

        // Add spacing between slots if needed
        if (i < slotList.length - 1) {
          if (_needsSpacingBetween(slot, slotList[i + 1])) {
            _output.writeln();
          }
        }
      }

      // Find the first meaningful child for spacing between last slot and children
      final meaningfulChildren = node.children
          .where(
            (child) => child is! TextNode || child.content.trim().isNotEmpty,
          )
          .toList();

      // Add spacing between last slot and first child if needed
      if (slotList.isNotEmpty && meaningfulChildren.isNotEmpty) {
        if (_needsSpacingBetween(slotList.last, meaningfulChildren.first)) {
          _output.writeln();
        }
      }

      // Then format regular children
      for (var i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        // Skip whitespace-only text nodes
        if (child is TextNode && child.content.trim().isEmpty) {
          continue;
        }

        child.accept(this);

        // Add spacing between children if needed
        if (i < node.children.length - 1) {
          // Find next meaningful node
          AstNode? nextMeaningful;
          for (var j = i + 1; j < node.children.length; j++) {
            final candidate = node.children[j];
            if (candidate is! TextNode || candidate.content.trim().isNotEmpty) {
              nextMeaningful = candidate;
              break;
            }
          }

          if (nextMeaningful != null &&
              _needsSpacingBetween(child, nextMeaningful)) {
            _output.writeln();
          }
        }

        // Add spacing before last slot's closing bracket (child followed by nothing = end)
      }
    }

    _indent.decrease();

    // Write closing tag
    _beginLine();
    _output.write('</x-${node.name}>');
    _output.writeln();

    return '';
  }

  @override
  String visitComment(CommentNode node) {
    // Check if this is a formatter control comment
    final control = _getFormatterControl(node.content);

    if (control == 'off') {
      // Disable formatting and output the comment
      // Don't add trailing newline - the following raw text will preserve spacing
      _formattingEnabled = false;
      _beginLine();
      _formatComment(node);
      return '';
    }

    if (control == 'on') {
      // Re-enable formatting and output the comment
      _formattingEnabled = true;
      _beginLine();
      _formatComment(node);
      _output.writeln();
      return '';
    }

    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Inside raw text elements, output inline
    final parent = node.parent;
    if (parent is HtmlElementNode &&
        _rawTextElements.contains(parent.tagName.toLowerCase())) {
      _formatComment(node);
      return '';
    }

    // Normal comment formatting
    _beginLine();
    _formatComment(node);
    _output.writeln();
    return '';
  }

  /// Formats a comment node with proper delimiters.
  void _formatComment(CommentNode node) {
    var content = node.content;

    // Strip delimiters if they're already in the content (parser includes them)
    if (node.isBladeComment) {
      if (content.startsWith('{{--') && content.endsWith('--}}')) {
        content = content.substring(4, content.length - 4);
      }
      content = content.trim();
      _output.write('{{-- $content --}}');
    } else {
      if (content.startsWith('<!--') && content.endsWith('-->')) {
        content = content.substring(4, content.length - 3);
      }
      content = content.trim();
      _output.write('<!-- $content -->');
    }
  }

  @override
  String visitSlot(SlotNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    final useColon = switch (config.slotNameStyle) {
      SlotNameStyle.colon => true,
      SlotNameStyle.attribute => false,
      SlotNameStyle.preserve => node.useColonSyntax,
    };

    // Build attribute list, handling name attribute based on syntax choice
    final List<AttributeNode> attributes;
    if (useColon) {
      // Colon syntax: filter out 'name' attribute to avoid duplication
      attributes = node.attributes.entries
          .where((e) => e.key != 'name')
          .map((e) => e.value)
          .toList();
    } else {
      // Attribute syntax: ensure name attribute is present
      final hasNameAttr = node.attributes.containsKey('name');
      if (hasNameAttr) {
        attributes = node.attributes.values.toList();
      } else {
        // Source was colon syntax but we're converting to attribute syntax
        attributes = [
          StandardAttribute(
            name: 'name',
            value: node.name,
            startPosition: node.startPosition,
            endPosition: node.startPosition,
          ),
          ...node.attributes.values,
        ];
      }
    }

    // Write opening slot tag
    _beginLine();
    if (useColon) {
      _output.write('<x-slot:${node.name}');
    } else {
      _output.write('<x-slot');
    }

    // Determine if we should wrap attributes
    final shouldWrap = _shouldWrapAttributes(
      useColon ? 'slot:${node.name}' : 'slot',
      attributes,
      isComponent: true,
    );

    _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');

    // Format children
    if (node.children.isEmpty) {
      _output.write('</x-slot>');
      _output.writeln();
      return '';
    }

    // Check if we should use compact formatting
    final useCompactFormatting =
        config.slotFormatting == SlotFormatting.compact;

    if (useCompactFormatting) {
      // Filter out whitespace-only text nodes for inline check
      final meaningfulChildren = node.children
          .where((c) => c is! TextNode || c.content.trim().isNotEmpty)
          .toList();

      // Check if we can format compactly (single meaningful child without newlines)
      final canFormatCompact = meaningfulChildren.length == 1 &&
          (meaningfulChildren.first is! TextNode ||
              !(meaningfulChildren.first as TextNode).content.contains('\n'));

      if (canFormatCompact) {
        // Compact formatting: no extra newlines
        _output.writeln();
        _indent.increase();

        for (final child in node.children) {
          // Skip whitespace-only text nodes at start/end
          if (child is TextNode && child.content.trim().isEmpty) {
            continue;
          }
          child.accept(this);
        }

        _indent.decrease();
        _beginLine();
        _output.write('</x-slot>');
        _output.writeln();
        return '';
      }
    }

    // Block formatting (either SlotFormatting.block config, or complex content with compact config)
    final useBlockWithExtraNewlines =
        config.slotFormatting == SlotFormatting.block;

    _output.writeln();

    if (useBlockWithExtraNewlines) {
      // Add extra newline after opening tag (old block behavior)
      _output.writeln();
    }

    _indent.increase();

    for (var i = 0; i < node.children.length; i++) {
      final child = node.children[i];

      // Skip whitespace-only text nodes in block mode
      if (child is TextNode && child.content.trim().isEmpty) {
        continue;
      }

      child.accept(this);

      // Add spacing between children if needed
      if (i < node.children.length - 1) {
        // Find the next meaningful (non-whitespace) node
        AstNode? nextMeaningful;
        for (var j = i + 1; j < node.children.length; j++) {
          final candidate = node.children[j];
          if (candidate is! TextNode || candidate.content.trim().isNotEmpty) {
            nextMeaningful = candidate;
            break;
          }
        }

        if (nextMeaningful != null &&
            _needsSpacingBetween(child, nextMeaningful)) {
          _output.writeln();
        }
      }
    }

    _indent.decrease();

    if (useBlockWithExtraNewlines) {
      // Add extra newline before closing tag (old block behavior)
      _output.writeln();
    }

    // Write closing tag
    _beginLine();
    _output.write('</x-slot>');
    _output.writeln();

    return '';
  }

  @override
  String visitError(ErrorNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Preserve error nodes as-is (shouldn't happen in well-formed input)
    _beginLine();
    _output.write('<!-- ERROR: ${node.error} -->');
    _output.writeln();
    return '';
  }

  @override
  String visitPhpBlock(PhpBlockNode node) {
    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    _beginLine();
    switch (node.syntax) {
      case PhpBlockSyntax.phpTag:
        _output.write('<?php${node.code}?>');
      case PhpBlockSyntax.shortEcho:
        _output.write('<?=${node.code}?>');
      case PhpBlockSyntax.shortTag:
        _output.write('<?${node.code}?>');
      case PhpBlockSyntax.bladeDirective:
        _output.write('@php${node.code}@endphp');
    }
    _output.writeln();
    return '';
  }

  /// Checks if the next meaningful sibling of [node] is an echo node.
  ///
  /// Used by [visitText] to decide whether trailing whitespace on the last
  /// line should be preserved for inline continuation (e.g., "Deadline: {{ $date }}").
  bool _nextMeaningSiblingIsEcho(AstNode node) {
    final parent = node.parent;
    if (parent == null) return false;
    final siblings = parent.children;
    final idx = siblings.indexOf(node);
    if (idx < 0) return false;
    for (var i = idx + 1; i < siblings.length; i++) {
      final sibling = siblings[i];
      if (sibling is TextNode && sibling.content.trim().isEmpty) continue;
      return sibling is EchoNode;
    }
    return false;
  }

  /// Checks if a node is simple text (no newlines).
  bool _isSimpleTextNode(AstNode node) {
    return node is TextNode && !node.content.contains('\n');
  }

  /// Checks if a node is a simple echo statement.
  bool _isSimpleEchoNode(AstNode node) {
    return node is EchoNode;
  }

  /// Checks if a node can be rendered inline (on the same line as text).
  ///
  /// Includes simple text, echo nodes, and inline HTML elements whose
  /// attributes don't need wrapping and whose children are also inline.
  bool _isInlineRenderableNode(AstNode node) {
    if (_isSimpleTextNode(node) || _isSimpleEchoNode(node)) return true;
    if (node is HtmlElementNode) return _isInlineRenderableElement(node);
    return false;
  }

  /// Checks if an HTML element can be rendered inline.
  ///
  /// An element is inline-renderable when it uses a whitelisted inline tag,
  /// has no structural directives in its tag head, would not wrap its
  /// attributes, and all its children are themselves inline-renderable.
  bool _isInlineRenderableElement(HtmlElementNode node) {
    final tag = node.tagName.toLowerCase();

    // Must be a known inline element
    if (!_inlineElements.contains(tag)) return false;

    // Structural directives in the tag head force block formatting
    if (node.tagHead.isNotEmpty) return false;

    final attrs = node.attributes.values.toList();
    final isVoid = _voidElements.contains(tag);

    // If attributes would wrap, force block formatting
    if (_shouldWrapAttributes(node.tagName, attrs,
        isSelfClosing: isVoid || node.isSelfClosing)) {
      return false;
    }

    // Void elements with no children are always inline-renderable
    if (isVoid) return true;

    // All children must be inline-renderable (recursive check)
    final meaningful = node.children
        .where((c) => c is! TextNode || c.content.trim().isNotEmpty)
        .toList();
    if (meaningful.isEmpty) return true;
    if (!meaningful.every(_isInlineRenderableNode)) return false;

    // Reject if there are newlines between meaningful children.
    // Only check when there are multiple meaningful children, matching
    // the inline decision in visitHtmlElement (which also skips newline
    // checks for single meaningful children). This prevents the
    // _isInlineRenderableElement prediction from disagreeing with the
    // actual formatting, which would cause idempotency failures
    // (e.g., <td><a>...</a></td> collapsing on the second pass).
    if (meaningful.length > 1) {
      for (var i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        if (child is TextNode &&
            child.content.trim().isEmpty &&
            child.content.contains('\n') &&
            meaningful.contains(i > 0 ? node.children[i - 1] : null)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Renders a node inline (no indentation, no trailing newline).
  ///
  /// Used by the inline content builder for inline HTML elements.
  String _renderInlineNode(AstNode node) {
    if (node is TextNode) return node.content;
    if (node is EchoNode) {
      return _renderEchoString(node);
    }
    if (node is HtmlElementNode) return _renderInlineElement(node);
    return '';
  }

  /// Renders an HTML element inline (no indentation, no trailing newline).
  String _renderInlineElement(HtmlElementNode node) {
    final buf = StringBuffer();
    final tag = node.tagName;
    final isVoid = _voidElements.contains(tag.toLowerCase());
    final attrs = _sortAttributes(node.attributes.values);

    buf.write('<$tag');
    for (final attr in attrs) {
      buf.write(' ');
      buf.write(_formatAttribute(attr));
    }

    if (isVoid) {
      buf.write('>');
      return buf.toString();
    }

    if (node.children.isEmpty ||
        !node.children
            .any((c) => c is! TextNode || c.content.trim().isNotEmpty)) {
      buf.write('></$tag>');
      return buf.toString();
    }

    buf.write('>');

    // Render children inline
    final meaningful = node.children
        .where((c) => c is! TextNode || c.content.trim().isNotEmpty)
        .toList();
    final first = meaningful.first;
    final last = meaningful.last;

    var seenFirst = false;
    var pastLast = false;
    for (final child in node.children) {
      if (child == first) seenFirst = true;
      if (pastLast) break;
      if (child is TextNode) {
        var text = child.content;
        if (child == first) text = text.trimLeft();
        if (child == last) text = text.trimRight();
        if (text.trim().isEmpty) {
          if (seenFirst && text.isNotEmpty) buf.write(' ');
        } else {
          buf.write(text);
        }
      } else {
        buf.write(_renderInlineNode(child));
      }
      if (child == last) pastLast = true;
    }

    buf.write('</$tag>');
    return buf.toString();
  }

  /// Determines if spacing is needed between two nodes.
  bool _needsSpacingBetween(AstNode current, AstNode next) {
    // Skip spacing if next is whitespace-only text
    if (next is TextNode && next.content.trim().isEmpty) {
      return false;
    }

    // Add spacing between block-level HTML elements
    if (current is HtmlElementNode && next is HtmlElementNode) {
      final bothBlock =
          _blockElements.contains(current.tagName.toLowerCase()) &&
              _blockElements.contains(next.tagName.toLowerCase());
      if (!bothBlock) return false;

      switch (config.htmlBlockSpacing) {
        case HtmlBlockSpacing.betweenBlocks:
          return true;
        case HtmlBlockSpacing.none:
          return false;
        case HtmlBlockSpacing.preserve:
          return _sourceHasBlankLineBetween(current, next);
      }
    }

    // Add spacing between components
    if (current is ComponentNode && next is ComponentNode) {
      return true;
    }

    // Handle directive spacing based on configuration
    if (current is DirectiveNode && next is DirectiveNode) {
      // Never add blank lines before intermediate directives (@else, @elseif,
      // @case, @default, @empty inside @forelse) — they are branches of the same parent block.
      if (_isIntermediateDirective(next)) {
        return false;
      }

      switch (config.directiveSpacing) {
        case DirectiveSpacing.betweenBlocks:
          final isCurrentBlock = _blockDirectives.contains(current.name);
          final isNextBlock = _blockDirectives.contains(next.name) ||
              _inlineDirectives.contains(next.name);
          if (isCurrentBlock && isNextBlock) {
            return true;
          }
          return false;
        case DirectiveSpacing.none:
          return false;
        case DirectiveSpacing.preserve:
          return _sourceHasBlankLineBetween(current, next);
      }
    }

    // Add spacing between block directives and non-directives
    if (current is DirectiveNode && _blockDirectives.contains(current.name)) {
      return next is! DirectiveNode;
    }

    // Handle slot spacing based on configuration
    if (config.slotSpacing != SlotSpacing.none) {
      // Spacing after a slot (slot followed by any node)
      if (current is SlotNode &&
          (config.slotSpacing == SlotSpacing.after ||
              config.slotSpacing == SlotSpacing.around)) {
        return true;
      }

      // Spacing before a slot (any node followed by slot)
      if (next is SlotNode &&
          (config.slotSpacing == SlotSpacing.before ||
              config.slotSpacing == SlotSpacing.around)) {
        return true;
      }
    }

    return false;
  }

  /// Determines if an empty element should be formatted as self-closing.
  ///
  /// Takes the original `isSelfClosing` value from the AST and applies
  /// the configured `selfClosingStyle` to decide the output format.
  bool _shouldSelfClose(bool originalIsSelfClosing) {
    switch (config.selfClosingStyle) {
      case SelfClosingStyle.preserve:
        return originalIsSelfClosing;
      case SelfClosingStyle.always:
        return true;
      case SelfClosingStyle.never:
        return false;
    }
  }

  /// Checks if a directive node is intermediate (no @end tag, aligned with parent).
  /// @empty is intermediate only inside @forelse (when it has no expression).
  bool _isIntermediateDirective(DirectiveNode node) {
    if (_intermediateDirectives.contains(node.name)) return true;
    return node.name == 'empty' && node.expression == null;
  }

  String _closingDirectiveName(String name) {
    return TokenType.closingDirectiveName(name);
  }

  /// Checks if a directive has a closing tag.
  bool _hasClosingDirective(String name, {String? expression}) {
    if (_intermediateDirectives.contains(name)) return false;
    // @empty without expression is intermediate (inside @forelse)
    // @empty with expression is standalone and needs @endempty
    if (name == 'empty' && expression == null) return false;
    // Known block directives, or unknown directives treated as blocks
    // (if we reach here with isBlock=true, it has children and needs closing)
    return true;
  }
}
