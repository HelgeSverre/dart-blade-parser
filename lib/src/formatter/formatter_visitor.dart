import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/formatter/formatter_config.dart';
import 'package:blade_parser/src/formatter/indent_tracker.dart';

/// Visitor that traverses an AST and generates formatted Blade template output.
///
/// This visitor implements the formatting logic for all AST node types,
/// handling indentation, spacing, and line breaks according to the
/// formatter configuration.
class FormatterVisitor implements AstVisitor<String> {
  final FormatterConfig config;
  final IndentTracker _indent;
  final StringBuffer _output = StringBuffer();

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

  /// HTML inline elements that should not force line breaks.
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

  /// Blade directives that are ending tags (close block directives).
  static const Set<String> _endingDirectives = {
    'endif',
    'endunless',
    'endforeach',
    'endforelse',
    'endfor',
    'endwhile',
    'endswitch',
    'endauth',
    'endguest',
    'endcan',
    'endcannot',
    'endcanany',
    'endenv',
    'endproduction',
    'endsection',
    'endpush',
    'endprepend',
    'endonce',
    'endphp',
    'endverbatim',
  };

  FormatterVisitor(this.config) : _indent = IndentTracker(config);

  /// Formats the AST and returns the formatted string.
  String format(AstNode node) {
    _output.clear();
    _indent.reset();
    node.accept(this);
    return _output.toString();
  }

  /// Formats an attribute value with the appropriate quote style.
  ///
  /// Handles escaping and quote style conversion based on config.quoteStyle.
  String _formatAttributeValue(String value) {
    final quote = switch (config.quoteStyle) {
      QuoteStyle.single => "'",
      QuoteStyle.double => '"',
      QuoteStyle.preserve => '"', // Default to double quotes
    };

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
      if (child is TextNode && child.content.trim().isEmpty) {
        // Count the number of newlines in this text node
        final newlineCount = '\n'.allMatches(child.content).length;

        // If there are 2+ newlines, it represents intentional blank line(s)
        // Preserve one blank line (we already have one from previous element's writeln)
        if (newlineCount >= 2 && !_output.toString().endsWith('\n\n')) {
          _output.writeln();
        }
        continue;
      }

      child.accept(this);

      // Add spacing between top-level elements
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

    // Ensure file ends with newline
    final outputStr = _output.toString();
    if (outputStr.isEmpty) {
      // If document had children (even if just whitespace), add newline
      // If document was truly empty, keep output empty
      if (node.children.isNotEmpty) {
        _output.writeln();
      }
    } else if (!outputStr.endsWith('\n')) {
      _output.writeln();
    }

    return _output.toString();
  }

  @override
  String visitDirective(DirectiveNode node) {
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

        child.accept(this);

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
      _output.write('@end${node.name}');
      _output.writeln();
    }

    return '';
  }

  @override
  String visitEcho(EchoNode node) {
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
    // Handle text content carefully to preserve meaningful whitespace
    final content = node.content;

    // Skip empty text nodes
    if (content.trim().isEmpty && content.length < 2) {
      return '';
    }

    // If text contains only whitespace and newlines, preserve one newline
    if (content.trim().isEmpty) {
      if (!_output.toString().endsWith('\n\n')) {
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
        if (i == 0 && !_output.toString().endsWith('\n')) {
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
    final tagName = node.tagName.toLowerCase();
    final isVoid = _voidElements.contains(tagName);

    // Write opening tag
    _output.write(_indent.current);
    _output.write('<${node.tagName}');

    // Write attributes
    if (node.attributes.isNotEmpty) {
      for (final attr in node.attributes.values) {
        _output.write(' ');
        _output.write(attr.name);

        if (attr.value != null) {
          _output.write('=');
          _output.write(_formatAttributeValue(attr.value!));
        }
      }
    }

    if (isVoid) {
      _output.write('>');
      _output.writeln();
      return '';
    }

    _output.write('>');

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
              _isSimpleTextNode(child) || _isSimpleEchoNode(child));

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
    // Write opening tag
    _output.write(_indent.current);
    _output.write('<x-${node.name}');

    // Write attributes
    if (node.attributes.isNotEmpty) {
      for (final attr in node.attributes.values) {
        _output.write(' ');
        _output.write(attr.name);

        if (attr.value != null) {
          _output.write('=');
          _output.write(_formatAttributeValue(attr.value!));
        }
      }
    }

    // Check if component has content (slots or non-whitespace children)
    final hasContent = node.slots.isNotEmpty ||
        node.children.any(
          (child) => child is! TextNode || child.content.trim().isNotEmpty,
        );

    // Self-closing if no content
    if (!hasContent) {
      _output.write(' />');
      _output.writeln();
      return '';
    }

    _output.write('>');

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
    // (parser puts content in both places, but we only want to render once)
    final hasDefaultSlot = node.slots.containsKey('default');

    if (hasDefaultSlot) {
      // Render all named slots (including default)
      for (final slotEntry in node.slots.entries) {
        slotEntry.value.accept(this);
      }
    } else {
      // First, format named slots (non-default)
      for (final slotEntry in node.slots.entries) {
        slotEntry.value.accept(this);
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
          final next = node.children[i + 1];
          if (_needsSpacingBetween(child, next)) {
            _output.writeln();
          }
        }
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
    _output.write(_indent.current);

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

    _output.writeln();
    return '';
  }

  @override
  String visitSlot(SlotNode node) {
    // Write opening slot tag
    _output.write(_indent.current);

    _output.write('<x-slot:${node.name}');

    // Write attributes if present
    if (node.attributes.isNotEmpty) {
      for (final attr in node.attributes.values) {
        _output.write(' ');
        _output.write(attr.name);

        if (attr.value != null) {
          _output.write('=');
          // Always quote attribute values for consistency
          _output.write('"${attr.value}"');
        }
      }
    }

    _output.write('>');

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
      return true;
    }

    // Add spacing between components
    if (current is ComponentNode && next is ComponentNode) {
      return true;
    }

    // Handle directive spacing based on configuration
    if (current is DirectiveNode && next is DirectiveNode) {
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

    return false;
  }

  /// Checks if a directive has a closing tag.
  bool _hasClosingDirective(String name) {
    // List of directives that have @end{name} closing tags
    const closingDirectives = {
      'if',
      'unless',
      'foreach',
      'forelse',
      'for',
      'while',
      'switch',
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
    };

    return closingDirectives.contains(name);
  }
}
