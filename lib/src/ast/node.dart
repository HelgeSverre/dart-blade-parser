import 'package:blade_parser/src/ast/visitor.dart' show RecursiveAstVisitor;
import 'package:blade_parser/src/lexer/position.dart';

/// Base class for all AST (Abstract Syntax Tree) nodes.
///
/// All nodes in the parsed Blade template are represented as subclasses
/// of [AstNode]. This enables type-safe traversal and analysis of the
/// template structure using the visitor pattern.
sealed class AstNode {
  /// The starting position of this node in the source template.
  Position get startPosition;

  /// The ending position of this node in the source template.
  Position get endPosition;

  /// The parent node, or null if this is the root document node.
  AstNode? parent;

  /// Child nodes contained within this node.
  List<AstNode> get children;

  /// Accept a visitor for traversing the AST.
  ///
  /// Implements the visitor pattern to enable type-safe traversal
  /// and transformation of the AST.
  T accept<T>(AstVisitor<T> visitor);

  /// Convert this node to a JSON representation.
  ///
  /// Useful for serialization, debugging, and interoperability with
  /// other tools that process Blade templates.
  Map<String, dynamic> toJson();
}

/// Visitor pattern interface for traversing AST nodes.
///
/// Implement this interface to perform operations on AST nodes in a
/// type-safe manner. See also [RecursiveAstVisitor] for automatically
/// traversing child nodes.
///
/// Example:
/// ```dart
/// class DirectiveCounter extends RecursiveAstVisitor<void> {
///   int count = 0;
///
///   @override
///   void visitDirective(DirectiveNode node) {
///     count++;
///     super.visitDirective(node);
///   }
/// }
/// ```
abstract class AstVisitor<T> {
  /// Visit a document (root) node.
  T visitDocument(DocumentNode node);

  /// Visit a Blade directive node (@if, @foreach, etc.).
  T visitDirective(DirectiveNode node);

  /// Visit a component node (<x-component>).
  T visitComponent(ComponentNode node);

  /// Visit an echo node ({{ }} or {!! !!}).
  T visitEcho(EchoNode node);

  /// Visit a text node (plain text content).
  T visitText(TextNode node);

  /// Visit an HTML element node (<div>, <p>, etc.).
  T visitHtmlElement(HtmlElementNode node);

  /// Visit a comment node ({{-- --}} or <!-- -->).
  T visitComment(CommentNode node);

  /// Visit an error node (represents a parsing error).
  T visitError(ErrorNode node);

  /// Visit a slot node (component slot definition).
  T visitSlot(SlotNode node);

  /// Visit a PHP block node (<?php ?>, <?= ?>, <? ?>, @php/@endphp).
  T visitPhpBlock(PhpBlockNode node);
}

/// Root document node representing the entire Blade template.
///
/// This is the top-level node in the AST and contains all other nodes
/// as its children. It has no parent.
final class DocumentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children;

  /// Creates a new document node.
  ///
  /// [startPosition] is the beginning of the template.
  /// [endPosition] is the end of the template.
  /// [children] contains all top-level nodes in the template.
  DocumentNode({
    required this.startPosition,
    required this.endPosition,
    required this.children,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDocument(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'document',
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Blade directive node representing directives like @if, @foreach, @section, etc.
///
/// Directives are special Blade syntax starting with @ that provide control
/// flow, template composition, and other functionality. Examples include
/// @if/@endif, @foreach/@endforeach, @section/@endsection.
final class DirectiveNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children;

  /// The directive name (without the @ prefix).
  ///
  /// For example, "if", "foreach", "section", "extends".
  final String name;

  /// The expression/arguments passed to the directive, if any.
  ///
  /// For example, in `@if($user->isAdmin())`, the expression would be
  /// `$user->isAdmin()`. May be null for directives without expressions.
  final String? expression;

  /// The closing directive name for block directives, if applicable.
  ///
  /// For `@section` directives, this captures how the section was closed:
  /// - `'endsection'` for standard `@endsection` closing
  /// - `'show'` for `@show` (close and immediately yield)
  /// - `'overwrite'` for legacy `@overwrite` (deprecated in Laravel 7+)
  ///
  /// Null for directives without closing tags or inline directives.
  final String? closedBy;

  /// Creates a new directive node.
  ///
  /// [startPosition] and [endPosition] define the directive's location.
  /// [name] is the directive name without the @ prefix.
  /// [expression] is the optional directive arguments/expression.
  /// [children] contains nodes within block directives (e.g., within @if/@endif).
  /// [closedBy] is the closing directive name (e.g., 'endsection', 'show') for
  /// directives like `@section` that have multiple ways to close.
  DirectiveNode({
    required this.startPosition,
    required this.endPosition,
    required this.name,
    this.expression,
    required this.children,
    this.closedBy,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDirective(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'directive',
        'name': name,
        if (expression != null) 'expression': expression,
        if (closedBy != null) 'closedBy': closedBy,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Echo node representing Blade echo statements ({{ }} and {!! !!}).
///
/// Echo statements output PHP expressions in templates. Regular echoes
/// ({{ }}) are HTML-escaped, while raw echoes ({!! !!}) output unescaped
/// content.
final class EchoNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The PHP expression to be echoed (trimmed).
  ///
  /// For example, in `{{ $user->name }}`, this would be `$user->name`.
  final String expression;

  /// The raw expression as it appeared in source (untrimmed, preserves spacing).
  final String rawExpression;

  /// Whether this is a raw (unescaped) echo.
  ///
  /// true for {!! !!} syntax, false for {{ }} syntax.
  final bool isRaw;

  /// Creates a new echo node.
  ///
  /// [expression] is the PHP expression to output.
  /// [isRaw] indicates whether this is unescaped output ({!! !!}).
  EchoNode({
    required this.startPosition,
    required this.endPosition,
    required this.expression,
    String? rawExpression,
    required this.isRaw,
  }) : rawExpression = rawExpression ?? expression;

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitEcho(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'echo',
        'expression': expression,
        'isRaw': isRaw,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// Text node representing plain text content in the template.
///
/// This includes all text that is not part of Blade directives, echo
/// statements, or component/HTML tags. Text nodes are leaf nodes with
/// no children.
final class TextNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The text content.
  final String content;

  /// Creates a new text node.
  ///
  /// [content] is the plain text content.
  TextNode({
    required this.startPosition,
    required this.endPosition,
    required this.content,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitText(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'content': content,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// An item in an HTML/component opening tag head.
///
/// The tag head is the content between the tag name and the closing `>` or `/>`.
/// It contains attributes and optionally Blade structural directives
/// (e.g., `@if`/`@endif` wrapping conditional attributes).
sealed class TagHeadItem {}

/// An attribute in the tag head.
final class TagHeadAttribute extends TagHeadItem {
  /// The attribute name (used as key in the attributes map).
  final String name;

  /// The attribute node.
  final AttributeNode attribute;

  TagHeadAttribute(this.name, this.attribute);
}

/// A Blade directive in the tag head (e.g., `@if($x)`, `@endif`).
final class TagHeadDirective extends TagHeadItem {
  /// The directive name (e.g., "if", "endif", "else").
  final String name;

  /// The directive expression, if any (e.g., `($closeable)`).
  final String? expression;

  TagHeadDirective(this.name, {this.expression});
}

/// A Blade comment in the tag head (e.g., `{{-- description --}}`).
final class TagHeadComment extends TagHeadItem {
  /// The comment content (including delimiters).
  final String content;

  TagHeadComment(this.content);
}

/// A PHP block in the tag head (e.g., `<?php if (...): ?>`, `<?php endif; ?>`).
final class TagHeadPhpBlock extends TagHeadItem {
  /// The full PHP block source (including delimiters).
  final String content;

  TagHeadPhpBlock(this.content);
}

/// Base class for HTML/component attribute nodes.
///
/// Represents different types of attributes: standard HTML, Alpine.js,
/// and Livewire. Use the sealed class hierarchy to handle each type
/// appropriately.
sealed class AttributeNode {
  /// The attribute name (e.g., "class", "x-data", "wire:click").
  final String name;

  /// The attribute value, if any.
  final String? value;

  /// The original quote character used in source (' or "), or null for
  /// boolean/unquoted attributes.
  final String? quoteChar;

  /// The source position where this attribute starts.
  final Position startPosition;

  /// The source position where this attribute ends.
  final Position endPosition;

  /// Creates a new attribute node.
  AttributeNode({
    required this.name,
    this.value,
    this.quoteChar,
    required this.startPosition,
    required this.endPosition,
  });

  /// Convert this attribute to JSON representation.
  Map<String, dynamic> toJson();
}

/// Standard HTML attribute like class, id, style, etc.
///
/// Represents regular HTML attributes that are not Alpine.js or Livewire
/// specific.
final class StandardAttribute extends AttributeNode {
  /// Creates a standard HTML attribute.
  ///
  /// [name] is the attribute name (e.g., "class", "id").
  /// [value] is the optional attribute value.
  StandardAttribute({
    required super.name,
    super.value,
    super.quoteChar,
    required super.startPosition,
    required super.endPosition,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'standard',
        'name': name,
        if (value != null) 'value': value,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// Alpine.js attribute (x-data, x-show, @click, :bind, etc.).
///
/// Represents Alpine.js directives and event handlers used for reactive
/// frontend functionality.
final class AlpineAttribute extends AttributeNode {
  /// The Alpine.js directive type (e.g., "data", "show", "click").
  final String directive;

  /// Creates an Alpine.js attribute.
  ///
  /// [name] is the full attribute name (e.g., "x-data", "@click").
  /// [directive] is the Alpine directive type (e.g., "data", "click").
  /// [value] is the optional Alpine expression.
  AlpineAttribute({
    required super.name,
    required this.directive,
    super.value,
    super.quoteChar,
    required super.startPosition,
    required super.endPosition,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'alpine',
        'name': name,
        'directive': directive,
        if (value != null) 'value': value,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// Livewire attribute (wire:click, wire:model, wire:sort:item, etc.).
///
/// Represents Livewire directives for server-side reactive components,
/// including actions, sub-actions, and modifiers.
///
/// The attribute name `wire:sort:item.foo` is parsed as:
/// - [action] = `"sort"` (the base action after `wire:`)
/// - [subAction] = `"item"` (the colon-separated sub-action, if any)
/// - [modifiers] = `["foo"]` (dot-separated modifiers)
final class LivewireAttribute extends AttributeNode {
  /// The Livewire action (e.g., "click", "model", "sort", "bind").
  final String action;

  /// The colon-separated sub-action, if any.
  ///
  /// For example, in `wire:sort:item` the sub-action is `"item"`.
  /// In `wire:bind:class` the sub-action is `"class"`.
  /// For plain attributes like `wire:click` this is `null`.
  final String? subAction;

  /// Modifiers applied to the action (e.g., "prevent", "debounce", "once").
  final List<String> modifiers;

  /// Creates a Livewire attribute.
  ///
  /// [name] is the full attribute name (e.g., "wire:click", "wire:sort:item").
  /// [action] is the Livewire action (e.g., "click", "sort").
  /// [subAction] is the optional colon sub-action (e.g., "item", "class").
  /// [modifiers] are optional dot modifiers (e.g., ["prevent", "debounce"]).
  /// [value] is the method name or expression.
  LivewireAttribute({
    required super.name,
    required this.action,
    this.subAction,
    this.modifiers = const [],
    super.value,
    super.quoteChar,
    required super.startPosition,
    required super.endPosition,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'livewire',
        'name': name,
        'action': action,
        if (subAction != null) 'subAction': subAction,
        'modifiers': modifiers,
        if (value != null) 'value': value,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// Blade component node representing `<x-component>` tags.
///
/// Components are reusable Blade template pieces defined with the x- prefix.
/// They support attributes, slots, and can be self-closing or have children.
final class ComponentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children;

  /// The component name (without the x- prefix).
  ///
  /// For example, in `<x-alert>`, the name would be "alert".
  final String name;

  /// Map of attributes passed to the component.
  final Map<String, AttributeNode> attributes;

  /// Ordered list of items in the opening tag head.
  /// Preserves the source order of attributes and structural directives
  /// (e.g., `@if`/`@endif` wrapping conditional attributes).
  /// Empty when no structural directives appear in the tag head.
  final List<TagHeadItem> tagHead;

  /// Named slots defined within the component.
  final Map<String, SlotNode> slots;

  /// Whether this component is self-closing (<x-alert />).
  final bool isSelfClosing;

  /// Creates a new component node.
  ///
  /// [name] is the component name without the x- prefix.
  /// [attributes] are the component attributes.
  /// [tagHead] preserves ordered tag head items when directives are present.
  /// [slots] are named slot definitions.
  /// [isSelfClosing] indicates if this is a self-closing tag.
  /// [children] contains the component's content.
  ComponentNode({
    required this.startPosition,
    required this.endPosition,
    required this.name,
    this.attributes = const {},
    this.tagHead = const [],
    this.slots = const {},
    this.isSelfClosing = false,
    required this.children,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitComponent(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'component',
        'name': name,
        'attributes': attributes.map((k, v) => MapEntry(k, v.toJson())),
        'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
        'isSelfClosing': isSelfClosing,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Slot node for defining named slots in Blade components.
///
/// Slots allow components to define placeholder content areas that can
/// be filled by the component consumer. Supports both default and named slots.
final class SlotNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children;

  /// The slot name (e.g., "header", "footer", or "default").
  final String name;

  /// Whether the original source used colon syntax (`<x-slot:name>`)
  /// vs attribute syntax (`<x-slot name="...">`).
  final bool useColonSyntax;

  /// Attributes passed to the slot.
  final Map<String, AttributeNode> attributes;

  /// Creates a new slot node.
  ///
  /// [name] is the slot identifier.
  /// [attributes] are optional slot attributes.
  /// [children] contains the slot's default content.
  SlotNode({
    required this.startPosition,
    required this.endPosition,
    required this.name,
    this.useColonSyntax = true,
    this.attributes = const {},
    required this.children,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitSlot(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'slot',
        'name': name,
        'useColonSyntax': useColonSyntax,
        'attributes': attributes.map((k, v) => MapEntry(k, v.toJson())),
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Standard HTML element node like `<div>`, `<p>`, `<img>`, etc.
///
/// Represents any HTML tag that is not a Blade component. Supports
/// Alpine.js and Livewire attributes, self-closing syntax, and void elements.
final class HtmlElementNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children;

  /// The HTML tag name in lowercase (e.g., "div", "p", "img").
  final String tagName;

  /// Map of attributes on this element (HTML, Alpine.js, Livewire).
  /// Contains only unconditional (top-level) attributes.
  final Map<String, AttributeNode> attributes;

  /// Ordered list of items in the opening tag head.
  /// Preserves the source order of attributes and structural directives
  /// (e.g., `@if`/`@endif` wrapping conditional attributes).
  /// Empty when no structural directives appear in the tag head.
  final List<TagHeadItem> tagHead;

  /// Whether this element uses self-closing syntax (<br />).
  final bool isSelfClosing;

  /// Whether this is a void element that cannot have children (e.g., br, img, input).
  final bool isVoid;

  /// Creates a new HTML element node.
  ///
  /// [tagName] is automatically converted to lowercase.
  /// [attributes] include all types of attributes (standard, Alpine, Livewire).
  /// [tagHead] preserves ordered tag head items when directives are present.
  /// [isSelfClosing] indicates self-closing syntax usage.
  /// [isVoid] marks void elements that cannot have closing tags.
  /// [children] contains nested content (empty for void elements).
  HtmlElementNode({
    required this.startPosition,
    required this.endPosition,
    required String tagName,
    this.attributes = const {},
    this.tagHead = const [],
    this.isSelfClosing = false,
    this.isVoid = false,
    required this.children,
  }) : tagName = tagName.toLowerCase();

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitHtmlElement(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'htmlElement',
        'tagName': tagName,
        'attributes': attributes.map((k, v) => MapEntry(k, v.toJson())),
        'isSelfClosing': isSelfClosing,
        'isVoid': isVoid,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Comment node representing Blade ({{-- --}}) or HTML (<!-- -->) comments.
///
/// Blade comments are removed during rendering, while HTML comments
/// are preserved in the output.
final class CommentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The comment text content.
  final String content;

  /// Whether this is a Blade comment ({{-- --}}) or HTML comment (<!-- -->).
  ///
  /// Blade comments are server-side only and won't appear in rendered output.
  final bool isBladeComment;

  /// Creates a new comment node.
  ///
  /// [content] is the comment text.
  /// [isBladeComment] distinguishes Blade comments from HTML comments.
  CommentNode({
    required this.startPosition,
    required this.endPosition,
    required this.content,
    required this.isBladeComment,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitComment(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'comment',
        'content': content,
        'isBladeComment': isBladeComment,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// Error node representing a parsing error in the AST.
///
/// When the parser encounters invalid syntax but continues parsing
/// (error recovery), it creates an ErrorNode to mark the problematic
/// location while preserving as much of the AST as possible.
final class ErrorNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The error message describing what went wrong.
  final String error;

  /// Partial content that was successfully parsed before the error.
  final String? partialContent;

  /// Creates a new error node.
  ///
  /// [error] describes the parsing error.
  /// [partialContent] contains any successfully parsed content before the error.
  ErrorNode({
    required this.startPosition,
    required this.endPosition,
    required this.error,
    this.partialContent,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitError(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error',
        'error': error,
        if (partialContent != null) 'partialContent': partialContent,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}

/// The syntax variant used for a PHP block.
enum PhpBlockSyntax {
  /// Standard PHP tag: `<?php ... ?>`
  phpTag,

  /// Short echo tag: `<?= ... ?>`
  shortEcho,

  /// Short open tag: `<? ... ?>` (deprecated in PHP 7.4, requires short_open_tag)
  shortTag,

  /// Blade directive: `@php ... @endphp`
  bladeDirective,
}

/// A block of raw PHP code in the template.
///
/// Represents PHP code regions that should be preserved verbatim.
/// The [code] field contains the PHP source between the delimiters
/// (not including the opening/closing tags themselves).
final class PhpBlockNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The raw PHP source code between the delimiters.
  final String code;

  /// Which PHP tag syntax was used.
  final PhpBlockSyntax syntax;

  PhpBlockNode({
    required this.startPosition,
    required this.endPosition,
    required this.code,
    required this.syntax,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitPhpBlock(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'phpBlock',
        'syntax': syntax.name,
        'code': code,
        'position': {
          'start': startPosition.toJson(),
          'end': endPosition.toJson(),
        },
      };
}
