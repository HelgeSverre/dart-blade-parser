/// Configuration for the Blade formatter.
///
/// Controls formatting behavior including indentation style, spacing rules,
/// and other formatting preferences.
class FormatterConfig {
  /// The number of spaces (or tab width) for indentation.
  final int indentSize;

  /// Whether to use spaces or tabs for indentation.
  final IndentStyle indentStyle;

  /// Maximum line length before considering wrapping.
  ///
  /// When a line exceeds this length, the formatter will attempt to wrap
  /// it by breaking attributes to multiple lines.
  final int maxLineLength;

  /// Preferred quote style for HTML attributes.
  final QuoteStyle quoteStyle;

  /// Controls spacing between Blade directives.
  final DirectiveSpacing directiveSpacing;

  /// Controls formatting style for component slots.
  final SlotFormatting slotFormatting;

  /// Controls how slot names are rendered (colon vs attribute syntax).
  final SlotNameStyle slotNameStyle;

  /// Controls spacing (blank lines) around slot elements.
  final SlotSpacing slotSpacing;

  /// Controls when to wrap attributes to multiple lines.
  final WrapAttributes wrapAttributes;

  /// Controls how to sort attributes on HTML elements and components.
  final AttributeSort attributeSort;

  /// Controls where the closing bracket appears when attributes are wrapped.
  final ClosingBracketStyle closingBracketStyle;

  /// Controls how empty elements are formatted (self-closing vs explicit close).
  final SelfClosingStyle selfClosingStyle;

  /// Controls blank lines between block-level HTML element siblings.
  final HtmlBlockSpacing htmlBlockSpacing;

  /// Controls spacing inside echo braces {{ }} and {!! !!}.
  final EchoSpacing echoSpacing;

  /// Whether to add a trailing newline at the end of formatted output.
  final bool trailingNewline;

  /// Creates a formatter configuration.
  const FormatterConfig({
    this.indentSize = 4,
    this.indentStyle = IndentStyle.spaces,
    this.maxLineLength = 120,
    this.quoteStyle = QuoteStyle.preserve,
    this.directiveSpacing = DirectiveSpacing.betweenBlocks,
    this.slotFormatting = SlotFormatting.compact,
    this.slotNameStyle = SlotNameStyle.colon,
    this.slotSpacing = SlotSpacing.after,
    this.wrapAttributes = WrapAttributes.auto,
    this.attributeSort = AttributeSort.none,
    this.closingBracketStyle = ClosingBracketStyle.sameLine,
    this.selfClosingStyle = SelfClosingStyle.preserve,
    this.htmlBlockSpacing = HtmlBlockSpacing.betweenBlocks,
    this.echoSpacing = EchoSpacing.spaced,
    this.trailingNewline = true,
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
      indentStyle: IndentStyle.fromString(map['indent_style'] as String?),
      maxLineLength: map['max_line_length'] as int? ?? 120,
      quoteStyle: QuoteStyle.fromString(map['quote_style'] as String?),
      directiveSpacing:
          DirectiveSpacing.fromString(map['directive_spacing'] as String?),
      slotFormatting:
          SlotFormatting.fromString(map['slot_formatting'] as String?),
      slotNameStyle:
          SlotNameStyle.fromString(map['slot_name_style'] as String?),
      slotSpacing: SlotSpacing.fromString(map['slot_spacing'] as String?),
      wrapAttributes:
          WrapAttributes.fromString(map['wrap_attributes'] as String?),
      attributeSort: AttributeSort.fromString(map['attribute_sort'] as String?),
      closingBracketStyle: ClosingBracketStyle.fromString(
          map['closing_bracket_style'] as String?),
      selfClosingStyle:
          SelfClosingStyle.fromString(map['self_closing_style'] as String?),
      htmlBlockSpacing:
          HtmlBlockSpacing.fromString(map['html_block_spacing'] as String?),
      echoSpacing: EchoSpacing.fromString(map['echo_spacing'] as String?),
      trailingNewline: map['trailing_newline'] as bool? ?? true,
    );
  }

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'indent_size': indentSize,
      'indent_style': indentStyle.value,
      'max_line_length': maxLineLength,
      'quote_style': quoteStyle.value,
      'directive_spacing': directiveSpacing.value,
      'slot_formatting': slotFormatting.value,
      'slot_name_style': slotNameStyle.value,
      'slot_spacing': slotSpacing.value,
      'wrap_attributes': wrapAttributes.value,
      'attribute_sort': attributeSort.value,
      'closing_bracket_style': closingBracketStyle.value,
      'self_closing_style': selfClosingStyle.value,
      'html_block_spacing': htmlBlockSpacing.value,
      'echo_spacing': echoSpacing.value,
      'trailing_newline': trailingNewline,
    };
  }

  @override
  String toString() {
    return 'FormatterConfig('
        'indentSize: $indentSize, '
        'indentStyle: $indentStyle, '
        'maxLineLength: $maxLineLength, '
        'quoteStyle: $quoteStyle, '
        'directiveSpacing: $directiveSpacing, '
        'slotFormatting: $slotFormatting, '
        'slotNameStyle: $slotNameStyle, '
        'slotSpacing: $slotSpacing, '
        'wrapAttributes: $wrapAttributes, '
        'attributeSort: $attributeSort, '
        'closingBracketStyle: $closingBracketStyle, '
        'selfClosingStyle: $selfClosingStyle, '
        'htmlBlockSpacing: $htmlBlockSpacing, '
        'echoSpacing: $echoSpacing, '
        'trailingNewline: $trailingNewline'
        ')';
  }
}

/// Style of indentation to use.
enum IndentStyle {
  /// Use spaces for indentation.
  spaces('spaces'),

  /// Use tab characters for indentation.
  tabs('tabs');

  final String value;
  const IndentStyle(this.value);

  static IndentStyle fromString(String? s) => switch (s) {
        'tabs' => tabs,
        _ => spaces,
      };
}

/// Preferred quote style for HTML attributes.
enum QuoteStyle {
  /// Prefer single quotes: `<div class='foo'>`
  single('single', "'"),

  /// Prefer double quotes: `<div class="foo">`
  double('double', '"'),

  /// Preserve the original quote style used in the source.
  preserve('preserve', '"');

  final String value;
  final String quoteChar;
  const QuoteStyle(this.value, this.quoteChar);

  static QuoteStyle fromString(String? s) => switch (s) {
        'single' => single,
        'double' => double,
        _ => preserve,
      };
}

/// Controls spacing between Blade directives.
enum DirectiveSpacing {
  /// No blank lines between directives (compact formatting).
  ///
  /// Example:
  /// ```blade
  /// @endforeach
  /// @while($count > 0)
  /// ```
  none('none'),

  /// Add blank line between closing and opening directives.
  ///
  /// This adds visual separation between different directive blocks,
  /// making the code more readable.
  ///
  /// Example:
  /// ```blade
  /// @endforeach
  ///
  /// @while($count > 0)
  /// ```
  betweenBlocks('between_blocks'),

  /// Preserve blank lines as written in the source.
  ///
  /// The formatter will not add or remove blank lines between directives.
  /// This option gives full control to the developer.
  preserve('preserve');

  final String value;
  const DirectiveSpacing(this.value);

  static DirectiveSpacing fromString(String? s) => switch (s) {
        'none' => none,
        'between_blocks' => betweenBlocks,
        'preserve' => preserve,
        _ => betweenBlocks,
      };
}

/// Controls formatting style for component slots.
enum SlotFormatting {
  /// Always use block formatting with newlines after opening and before closing tags.
  ///
  /// Example:
  /// ```blade
  /// <x-slot:header>
  ///
  ///     <h2>Title</h2>
  ///
  /// </x-slot>
  /// ```
  block('block'),

  /// Smart formatting - compact for simple slots, block for complex slots.
  ///
  /// Single-element slots are formatted compactly without extra newlines.
  /// Multi-element slots use block formatting.
  ///
  /// Example (simple):
  /// ```blade
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  /// ```
  ///
  /// Example (complex):
  /// ```blade
  /// <x-slot:body>
  ///     <p>First paragraph</p>
  ///     <p>Second paragraph</p>
  /// </x-slot>
  /// ```
  compact('compact');

  final String value;
  const SlotFormatting(this.value);

  static SlotFormatting fromString(String? s) => switch (s) {
        'block' => block,
        _ => compact,
      };
}

/// Controls how slot names are rendered in the output.
enum SlotNameStyle {
  /// Always use colon syntax: `<x-slot:header>`
  ///
  /// This is the most concise syntax and is the Laravel convention.
  colon('colon'),

  /// Always use attribute syntax: `<x-slot name="header">`
  ///
  /// Some teams prefer this for explicitness.
  attribute('attribute'),

  /// Preserve the original syntax from the source.
  ///
  /// If the source used `<x-slot:header>`, output colon syntax.
  /// If the source used `<x-slot name="header">`, output attribute syntax.
  preserve('preserve');

  final String value;
  const SlotNameStyle(this.value);

  static SlotNameStyle fromString(String? s) => switch (s) {
        'colon' => colon,
        'attribute' => attribute,
        'preserve' => preserve,
        _ => colon,
      };
}

/// Controls spacing (blank lines) around slot elements.
enum SlotSpacing {
  /// No extra blank lines around slots.
  none('none'),

  /// Add a blank line after each slot's closing tag.
  ///
  /// This visually separates slots from subsequent content.
  /// Example:
  /// ```blade
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  ///
  /// <p>Content after slot</p>
  /// ```
  after('after'),

  /// Add a blank line before each slot's opening tag.
  ///
  /// Example:
  /// ```blade
  /// <p>Content before slot</p>
  ///
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  /// ```
  before('before'),

  /// Add blank lines both before and after slots.
  ///
  /// Example:
  /// ```blade
  /// <p>Content before</p>
  ///
  /// <x-slot:header>
  ///     <h2>Title</h2>
  /// </x-slot>
  ///
  /// <p>Content after</p>
  /// ```
  around('around');

  final String value;
  const SlotSpacing(this.value);

  static SlotSpacing fromString(String? s) => switch (s) {
        'none' => none,
        'after' => after,
        'before' => before,
        'around' => around,
        _ => after,
      };
}

/// Controls when to wrap attributes to multiple lines.
enum WrapAttributes {
  /// Always wrap attributes to multiple lines (one per line).
  ///
  /// Example:
  /// ```blade
  /// <div
  ///     class="container"
  ///     id="main"
  ///     data-value="123">
  /// ```
  always('always'),

  /// Never wrap attributes - keep on single line regardless of length.
  ///
  /// Example:
  /// ```blade
  /// <div class="container" id="main" data-value="123">
  /// ```
  never('never'),

  /// Automatically wrap when line exceeds maxLineLength.
  ///
  /// This is the default behavior. When the opening tag (including all
  /// attributes) would exceed maxLineLength, attributes are wrapped
  /// to multiple lines.
  auto('auto');

  final String value;
  const WrapAttributes(this.value);

  static WrapAttributes fromString(String? s) => switch (s) {
        'always' => always,
        'never' => never,
        _ => auto,
      };
}

/// Controls how to sort attributes on HTML elements and components.
enum AttributeSort {
  /// Do not sort attributes - preserve original order.
  none('none'),

  /// Sort attributes alphabetically by name.
  ///
  /// Example: class, data-value, id, type
  alphabetical('alphabetical'),

  /// Sort attributes by type/category:
  /// 1. Standard HTML attributes (id, class, type, name, etc.)
  /// 2. Data attributes (data-*)
  /// 3. Alpine.js attributes (x-*, @*, :*)
  /// 4. Livewire attributes (wire:*)
  /// 5. Other attributes
  ///
  /// Within each category, attributes are sorted alphabetically.
  byType('by_type');

  final String value;
  const AttributeSort(this.value);

  static AttributeSort fromString(String? s) => switch (s) {
        'alphabetical' => alphabetical,
        'by_type' => byType,
        _ => none,
      };
}

/// Controls where the closing bracket appears when attributes are wrapped.
enum ClosingBracketStyle {
  /// Closing bracket on same line as last attribute (default).
  ///
  /// Example:
  /// ```blade
  /// <div
  ///     class="container"
  ///     id="main">
  /// ```
  sameLine('same_line'),

  /// Closing bracket on its own line.
  ///
  /// Example:
  /// ```blade
  /// <div
  ///     class="container"
  ///     id="main"
  /// >
  /// ```
  newLine('new_line');

  final String value;
  const ClosingBracketStyle(this.value);

  static ClosingBracketStyle fromString(String? s) => switch (s) {
        'new_line' => newLine,
        _ => sameLine,
      };
}

/// Controls how empty elements are formatted (self-closing vs explicit close).
enum SelfClosingStyle {
  /// Preserve the original style from the source.
  ///
  /// Self-closing elements remain self-closing, explicit closes remain explicit.
  preserve('preserve'),

  /// Convert empty elements to self-closing syntax.
  ///
  /// Example: `<div></div>` becomes `<div />`
  ///
  /// Does not apply to void elements (img, br, input, etc.) which are
  /// always self-closing.
  always('always'),

  /// Convert self-closing elements to explicit close syntax.
  ///
  /// Example: `<div />` becomes `<div></div>`
  ///
  /// Does not apply to void elements (img, br, input, etc.) which are
  /// always self-closing.
  never('never');

  final String value;
  const SelfClosingStyle(this.value);

  static SelfClosingStyle fromString(String? s) => switch (s) {
        'always' => always,
        'never' => never,
        _ => preserve,
      };
}

/// Controls blank lines between block-level HTML element siblings.
enum HtmlBlockSpacing {
  /// Add blank line between block-level HTML siblings (e.g., consecutive divs).
  betweenBlocks('between_blocks'),

  /// No blank lines between HTML block elements.
  none('none'),

  /// Preserve blank lines as written in the source.
  preserve('preserve');

  final String value;
  const HtmlBlockSpacing(this.value);

  static HtmlBlockSpacing fromString(String? s) => switch (s) {
        'none' => none,
        'preserve' => preserve,
        _ => betweenBlocks,
      };
}

/// Controls spacing inside echo braces {{ }} and {!! !!}.
enum EchoSpacing {
  /// Always add spaces inside braces: `{{ $var }}`, `{!! $expr !!}`
  spaced('spaced'),

  /// No spaces inside braces: `{{$var}}`, `{!!$expr!!}`
  compact('compact'),

  /// Preserve the original spacing from the source.
  preserve('preserve');

  final String value;
  const EchoSpacing(this.value);

  static EchoSpacing fromString(String? s) => switch (s) {
        'compact' => compact,
        'preserve' => preserve,
        _ => spaced,
      };
}
