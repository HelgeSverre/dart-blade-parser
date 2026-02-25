import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/indent_tracker.dart';

/// A StringBuffer wrapper that tracks the last two characters written,
/// avoiding O(n) toString() calls for endsWith checks.
class _TrackedBuffer {
  final StringBuffer _buffer = StringBuffer();
  String _lastTwo = '';

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
      _lastTwo =
          (_lastTwo.isNotEmpty ? _lastTwo[_lastTwo.length - 1] : '') + s;
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
    'div', 'p', 'section', 'article', 'aside', 'header', 'footer',
    'nav', 'main', 'figure', 'figcaption', 'details', 'summary',
    'form', 'fieldset', 'table', 'blockquote', 'pre', 'address',
    'dl', 'ol', 'ul', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'hgroup', 'dialog', 'search',
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
  static const Set<String> _intermediateDirectives = {
    'elseif',
    'else',
    'case',
    'default',
    'empty',
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
    'php',
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
  };

  /// Blade directives that are inline (no children, single line).
  static const Set<String> _inlineDirectives = {
    'yield',
    'show',
    'stop',
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
    'props',
    'aware',
    'stack',
    'break',
    'continue',
    'empty', // Can be both, but often inline in context
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
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
    return '${attr.name}=${_formatAttributeValue(attr.value!)}';
  }

  /// Calculates the length of the opening tag if all attributes were on one line.
  int _calculateSingleLineTagLength(String tagName, List<AttributeNode> attributes, {bool isComponent = false, bool isSelfClosing = false}) {
    final prefix = isComponent ? '<x-$tagName' : '<$tagName';
    var length = _indent.current.length + prefix.length;

    for (final attr in attributes) {
      length += 1 + _formatAttribute(attr).length; // +1 for space
    }

    length += isSelfClosing ? 3 : 1; // ' />' or '>'
    return length;
  }

  /// Determines if attributes should be wrapped to multiple lines.
  bool _shouldWrapAttributes(String tagName, List<AttributeNode> attributes, {bool isComponent = false, bool isSelfClosing = false}) {
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

  /// Writes attributes, either inline or wrapped to multiple lines.
  void _writeAttributes(List<AttributeNode> attributes, {required bool wrap, required String closingBracket}) {
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
  String _formatAttributeValue(String value) {
    final quote = config.quoteStyle.quoteChar;

    // Escape quotes in the value if needed
    String escaped = value;
    if (config.quoteStyle == QuoteStyle.single) {
      // Escape single quotes, unescape double quotes if they were escaped
      escaped = value.replaceAll(r"\'", "'").replaceAll("'", r"\'");
    } else {
      // Escape double quotes, unescape single quotes if they were escaped
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
      if (_formattingEnabled && child is TextNode && child.content.trim().isEmpty) {
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

        if (nextMeaningful != null && _needsSpacingBetween(child, nextMeaningful)) {
          _output.writeln();
        }
      }
    }

    // Ensure file ends with newline
    final isEmpty = _output.toString().isEmpty;
    if (isEmpty) {
      // If document had children (even if just whitespace), add newline
      // If document was truly empty, keep output empty
      if (node.children.isNotEmpty) {
        _output.writeln();
      }
    } else if (!_output.endsWithNewline()) {
      _output.writeln();
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

    final isBlock = _blockDirectives.contains(node.name);

    // Write the directive opening
    _output.write(_indent.current);
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

        // Intermediate directives (@else, @elseif, @case, @default) should
        // align with the parent directive, not be indented inside it.
        if (child is DirectiveNode &&
            _intermediateDirectives.contains(child.name)) {
          _indent.decrease();
          child.accept(this);
          _indent.increase();
        } else {
          child.accept(this);
        }

        // Add spacing between children if needed
        if (i < node.children.length - 1) {
          final next = node.children[i + 1];
          if (_needsSpacingBetween(child, next)) {
            _output.writeln();
          }
        }
      }

      _indent.decrease();
    }

    // Write closing directive if this is a block directive with children
    // Inline directives (like @section('title', 'value')) don't get closing tags
    if (isBlock && node.children.isNotEmpty && _hasClosingDirective(node.name)) {
      _output.write(_indent.current);
      if (node.closedBy != null) {
        _output.write('@${node.closedBy}');
      } else {
        _output.write('@end${node.name}');
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

    _output.write(_indent.current);

    if (node.isRaw) {
      _output.write('{!! ${node.expression} !!}');
    } else {
      _output.write('{{ ${node.expression} }}');
    }

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

    // Split text by lines to handle multi-line text
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      if (trimmedLine.isNotEmpty) {
        // Check if this line should be indented
        // Don't indent if it's in the middle of inline content
        if (i == 0 && !_output.endsWithNewline()) {
          _output.write(line);
        } else {
          _output.write(_indent.current);
          _output.write(trimmedLine);
        }

        if (i < lines.length - 1) {
          _output.writeln();
        }
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
    final shouldSelfClose = !isVoid && !hasContent && _shouldSelfClose(node.isSelfClosing);

    // Write opening tag
    _output.write(_indent.current);
    _output.write('<${node.tagName}');

    // Determine if we should wrap attributes
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

    // Handle self-closing non-void elements
    if (shouldSelfClose) {
      _writeAttributes(attributes, wrap: shouldWrap, closingBracket: ' />');
      _output.writeln();
      return '';
    }

    _writeAttributes(attributes, wrap: shouldWrap, closingBracket: '>');

    // Format children
    if (node.children.isNotEmpty) {
      // Filter out whitespace-only text nodes for inline check
      final meaningfulChildren = node.children
          .where((c) => c is! TextNode || c.content.trim().isNotEmpty)
          .toList();

      // Check if we can keep content inline
      // Allow inline if: single simple child, or multiple children that are all inline-safe
      // BUT: if there are newlines in whitespace between meaningful children, don't inline
      var canKeepInline = meaningfulChildren.isNotEmpty &&
          meaningfulChildren.every((child) =>
              _isSimpleTextNode(child) || _isSimpleEchoNode(child),);

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
        // Build the inline content, preserving spaces between elements
        final inlineContent = StringBuffer();
        for (var i = 0; i < meaningfulChildren.length; i++) {
          final child = meaningfulChildren[i];
          if (child is TextNode) {
            // For text nodes, trim leading space on first, trailing on last
            var text = child.content;
            if (i == 0) {
              text = text.trimLeft();
            }
            if (i == meaningfulChildren.length - 1) {
              text = text.trimRight();
            }
            inlineContent.write(text);
          } else if (child is EchoNode) {
            if (child.isRaw) {
              inlineContent.write('{!! ${child.expression} !!}');
            } else {
              inlineContent.write('{{ ${child.expression} }}');
            }
          }
        }
        _output.write(inlineContent.toString());
        _output.write('</${node.tagName}>');
        _output.writeln();
        return '';
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

          if (nextMeaningful != null && _needsSpacingBetween(child, nextMeaningful)) {
            _output.writeln();
          }
        }
      }

      _indent.decrease();
      _output.write(_indent.current);
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
    _output.write(_indent.current);
    _output.write('<x-${node.name}');

    // Determine if we should wrap attributes
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

    // Format children
    // Check if we can keep content inline
    // If there's only a default slot with simple text, render it inline without slot tags
    final hasOnlyDefaultSlot = node.slots.length == 1 &&
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
      final meaningfulChildren = node.children.where(
        (child) => child is! TextNode || child.content.trim().isNotEmpty,
      ).toList();

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
    _output.write(_indent.current);
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
      _output.write(_indent.current);
      _formatComment(node);
      return '';
    }

    if (control == 'on') {
      // Re-enable formatting and output the comment
      _formattingEnabled = true;
      _output.write(_indent.current);
      _formatComment(node);
      _output.writeln();
      return '';
    }

    // If formatting is disabled, output raw
    if (!_formattingEnabled) {
      _outputRaw(node);
      return '';
    }

    // Normal comment formatting
    _output.write(_indent.current);
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
    _output.write(_indent.current);
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
      _output.writeln();
      return '';
    }

    // Check if we should use compact formatting
    final useCompactFormatting = config.slotFormatting == SlotFormatting.compact;

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
        _output.write(_indent.current);
        _output.write('</x-slot>');
        _output.writeln();
        return '';
      }
    }

    // Block formatting (either SlotFormatting.block config, or complex content with compact config)
    final useBlockWithExtraNewlines = config.slotFormatting == SlotFormatting.block;

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

        if (nextMeaningful != null && _needsSpacingBetween(child, nextMeaningful)) {
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
    _output.write(_indent.current);
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
    _output.write(_indent.current);
    _output.write('<!-- ERROR: ${node.error} -->');
    _output.writeln();
    return '';
  }

  /// Checks if a node is simple text (no newlines).
  bool _isSimpleTextNode(AstNode node) {
    return node is TextNode && !node.content.contains('\n');
  }

  /// Checks if a node is a simple echo statement.
  bool _isSimpleEchoNode(AstNode node) {
    return node is EchoNode;
  }

  /// Determines if spacing is needed between two nodes.
  bool _needsSpacingBetween(AstNode current, AstNode next) {
    // Skip spacing if next is whitespace-only text
    if (next is TextNode && next.content.trim().isEmpty) {
      return false;
    }

    // Add spacing between block-level HTML elements
    if (current is HtmlElementNode && next is HtmlElementNode) {
      return _blockElements.contains(current.tagName.toLowerCase()) &&
          _blockElements.contains(next.tagName.toLowerCase());
    }

    // Add spacing between components
    if (current is ComponentNode && next is ComponentNode) {
      return true;
    }

    // Handle directive spacing based on configuration
    if (current is DirectiveNode && next is DirectiveNode) {
      // Never add blank lines before intermediate directives (@else, @elseif,
      // @case, @default) — they are branches of the same parent block.
      if (_intermediateDirectives.contains(next.name)) {
        return false;
      }

      // Check if we should add spacing between block directives
      if (config.directiveSpacing == DirectiveSpacing.betweenBlocks) {
        // Add blank line between two block-level directives
        // Current directive has just finished (including its @end tag if it has one)
        // Next directive is about to start
        final isCurrentBlock = _blockDirectives.contains(current.name);
        final isNextBlock = _blockDirectives.contains(next.name) ||
            _inlineDirectives.contains(next.name);

        if (isCurrentBlock && isNextBlock) {
          return true;
        }
      }
      // For DirectiveSpacing.none or preserve, don't add spacing
      return false;
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

  /// Checks if a directive has a closing tag.
  bool _hasClosingDirective(String name) {
    return _blockDirectives.contains(name) &&
        !_intermediateDirectives.contains(name);
  }
}
