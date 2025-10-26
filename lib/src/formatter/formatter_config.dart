/// Configuration for the Blade formatter.
///
/// Controls formatting behavior including indentation style, spacing rules,
/// and other formatting preferences.
class FormatterConfig {
  /// The number of spaces (or tab width) for indentation.
  final int indentSize;

  /// Whether to use spaces or tabs for indentation.
  final IndentStyle indentStyle;


  /// Whether to format PHP expressions inside Blade syntax.
  ///
  /// When `false`, preserves PHP expressions as-is inside:
  /// - Echo statements: `{{ $expr }}`
  /// - Directives: `@if($expr)`
  final bool formatPhpExpressions;

  /// Maximum line length before considering wrapping.
  ///
  /// Note: Line wrapping is not yet implemented in MVP.
  final int maxLineLength;

  /// Preferred quote style for HTML attributes.
  final QuoteStyle quoteStyle;

  /// Creates a formatter configuration.
  const FormatterConfig({
    this.indentSize = 4,
    this.indentStyle = IndentStyle.spaces,
    this.formatPhpExpressions = false,
    this.maxLineLength = 120,
    this.quoteStyle = QuoteStyle.preserve,
  });

  /// Creates a default formatter configuration.
  ///
  /// Defaults:
  /// - 4 spaces for indentation
  /// - Preserve PHP expressions as-is
  /// - 120 character line length
  /// - Preserve quote style
  factory FormatterConfig.defaults() => const FormatterConfig();

  /// Creates a compact formatter configuration.
  ///
  /// Uses 2 spaces for more compact output.
  factory FormatterConfig.compact() => const FormatterConfig(
        indentSize: 2,
      );

  /// Creates a formatter configuration from a map.
  ///
  /// Useful for loading from YAML or JSON configuration files.
  factory FormatterConfig.fromMap(Map<String, dynamic> map) {
    return FormatterConfig(
      indentSize: map['indent_size'] as int? ?? 4,
      indentStyle: map['indent_style'] == 'tabs'
          ? IndentStyle.tabs
          : IndentStyle.spaces,
      formatPhpExpressions: map['format_php_expressions'] as bool? ?? false,
      maxLineLength: map['max_line_length'] as int? ?? 120,
      quoteStyle: _parseQuoteStyle(map['quote_style'] as String?),
    );
  }

  static QuoteStyle _parseQuoteStyle(String? style) {
    switch (style) {
      case 'single':
        return QuoteStyle.single;
      case 'double':
        return QuoteStyle.double;
      default:
        return QuoteStyle.preserve;
    }
  }

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'indent_size': indentSize,
      'indent_style': indentStyle == IndentStyle.tabs ? 'tabs' : 'spaces',
      'format_php_expressions': formatPhpExpressions,
      'max_line_length': maxLineLength,
      'quote_style': _quoteStyleToString(quoteStyle),
    };
  }

  String _quoteStyleToString(QuoteStyle style) {
    switch (style) {
      case QuoteStyle.single:
        return 'single';
      case QuoteStyle.double:
        return 'double';
      case QuoteStyle.preserve:
        return 'preserve';
    }
  }

  @override
  String toString() {
    return 'FormatterConfig('
        'indentSize: $indentSize, '
        'indentStyle: $indentStyle, '
        'formatPhpExpressions: $formatPhpExpressions, '
        'maxLineLength: $maxLineLength, '
        'quoteStyle: $quoteStyle'
        ')';
  }
}

/// Style of indentation to use.
enum IndentStyle {
  /// Use spaces for indentation.
  spaces,

  /// Use tab characters for indentation.
  tabs,
}

/// Preferred quote style for HTML attributes.
enum QuoteStyle {
  /// Prefer single quotes: `<div class='foo'>`
  single,

  /// Prefer double quotes: `<div class="foo">`
  double,

  /// Preserve the original quote style used in the source.
  preserve,
}
