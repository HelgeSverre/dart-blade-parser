import 'package:blade_parser/blade_parser.dart' show RecursiveAstVisitor;
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
  AstNode? get parent;

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
  final AstNode? parent = null;
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
  final AstNode? parent;
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

  /// Creates a new directive node.
  ///
  /// [startPosition] and [endPosition] define the directive's location.
  /// [name] is the directive name without the @ prefix.
  /// [expression] is the optional directive arguments/expression.
  /// [children] contains nodes within block directives (e.g., within @if/@endif).
  DirectiveNode({
    required this.startPosition,
    required this.endPosition,
    this.parent,
    required this.name,
    this.expression,
    required this.children,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitDirective(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'directive',
        'name': name,
        if (expression != null) 'expression': expression,
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
  final AstNode? parent;
  @override
  final List<AstNode> children = const [];

  /// The PHP expression to be echoed.
  ///
  /// For example, in `{{ $user->name }}`, this would be `$user->name`.
  final String expression;

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
    this.parent,
    required this.expression,
    required this.isRaw,
  });

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
  final AstNode? parent;
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
    this.parent,
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

  /// Creates a new attribute node.
  AttributeNode({required this.name, this.value});

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
  StandardAttribute({required super.name, super.value});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'standard',
        'name': name,
        if (value != null) 'value': value,
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
  AlpineAttribute({required super.name, required this.directive, super.value});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'alpine',
        'name': name,
        'directive': directive,
        if (value != null) 'value': value,
      };
}

/// Livewire attribute (wire:click, wire:model, etc.).
///
/// Represents Livewire directives for server-side reactive components,
/// including actions and modifiers.
final class LivewireAttribute extends AttributeNode {
  /// The Livewire action (e.g., "click", "model", "submit").
  final String action;

  /// Modifiers applied to the action (e.g., "prevent", "debounce").
  final List<String> modifiers;

  /// Creates a Livewire attribute.
  ///
  /// [name] is the full attribute name (e.g., "wire:click").
  /// [action] is the Livewire action (e.g., "click", "model").
  /// [modifiers] are optional modifiers (e.g., ["prevent", "debounce"]).
  /// [value] is the method name or expression.
  LivewireAttribute({
    required super.name,
    required this.action,
    this.modifiers = const [],
    super.value,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'livewire',
        'name': name,
        'action': action,
        'modifiers': modifiers,
        if (value != null) 'value': value,
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
  final AstNode? parent;
  @override
  final List<AstNode> children;

  /// The component name (without the x- prefix).
  ///
  /// For example, in `<x-alert>`, the name would be "alert".
  final String name;

  /// Map of attributes passed to the component.
  final Map<String, AttributeNode> attributes;

  /// Named slots defined within the component.
  final Map<String, SlotNode> slots;

  /// Whether this component is self-closing (<x-alert />).
  final bool isSelfClosing;

  /// Creates a new component node.
  ///
  /// [name] is the component name without the x- prefix.
  /// [attributes] are the component attributes.
  /// [slots] are named slot definitions.
  /// [isSelfClosing] indicates if this is a self-closing tag.
  /// [children] contains the component's content.
  ComponentNode({
    required this.startPosition,
    required this.endPosition,
    this.parent,
    required this.name,
    this.attributes = const {},
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
  final AstNode? parent;
  @override
  final List<AstNode> children;

  /// The slot name (e.g., "header", "footer", or "default").
  final String name;

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
    this.parent,
    required this.name,
    this.attributes = const {},
    required this.children,
  });

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitSlot(this);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'slot',
        'name': name,
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
  final AstNode? parent;
  @override
  final List<AstNode> children;

  /// The HTML tag name in lowercase (e.g., "div", "p", "img").
  final String tagName;

  /// Map of attributes on this element (HTML, Alpine.js, Livewire).
  final Map<String, AttributeNode> attributes;

  /// Whether this element uses self-closing syntax (<br />).
  final bool isSelfClosing;

  /// Whether this is a void element that cannot have children (e.g., br, img, input).
  final bool isVoid;

  /// Creates a new HTML element node.
  ///
  /// [tagName] is automatically converted to lowercase.
  /// [attributes] include all types of attributes (standard, Alpine, Livewire).
  /// [isSelfClosing] indicates self-closing syntax usage.
  /// [isVoid] marks void elements that cannot have closing tags.
  /// [children] contains nested content (empty for void elements).
  HtmlElementNode({
    required this.startPosition,
    required this.endPosition,
    this.parent,
    required String tagName,
    this.attributes = const {},
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
  final AstNode? parent;
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
    this.parent,
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
  final AstNode? parent;
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
    this.parent,
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
