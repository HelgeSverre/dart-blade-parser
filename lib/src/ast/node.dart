import '../lexer/position.dart';

/// Base class for all AST nodes.
sealed class AstNode {
  Position get startPosition;
  Position get endPosition;
  AstNode? get parent;
  List<AstNode> get children;

  /// Accept a visitor.
  T accept<T>(AstVisitor<T> visitor);

  /// Convert to JSON representation.
  Map<String, dynamic> toJson();
}

/// Visitor pattern interface.
abstract class AstVisitor<T> {
  T visitDocument(DocumentNode node);
  T visitDirective(DirectiveNode node);
  T visitComponent(ComponentNode node);
  T visitEcho(EchoNode node);
  T visitText(TextNode node);
  T visitHtmlElement(HtmlElementNode node);
  T visitComment(CommentNode node);
  T visitError(ErrorNode node);
  T visitSlot(SlotNode node);
}

/// Root document node.
final class DocumentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent = null;
  @override
  final List<AstNode> children;

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

/// Directive node (@if, @foreach, etc.).
final class DirectiveNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children;

  final String name;
  final String? expression;

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

/// Echo node ({{ }}, {!! !!}).
final class EchoNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children = const [];

  final String expression;
  final bool isRaw;

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

/// Text node.
final class TextNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children = const [];

  final String content;

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

/// Attribute node sealed class hierarchy
sealed class AttributeNode {
  final String name;
  final String? value;

  AttributeNode({required this.name, this.value});

  Map<String, dynamic> toJson();
}

/// Standard HTML attribute
final class StandardAttribute extends AttributeNode {
  StandardAttribute({required super.name, super.value});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'standard',
        'name': name,
        if (value != null) 'value': value,
      };
}

/// Alpine.js attribute (x-data, x-show, @click, etc.)
final class AlpineAttribute extends AttributeNode {
  final String directive;

  AlpineAttribute({
    required super.name,
    required this.directive,
    super.value,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'alpine',
        'name': name,
        'directive': directive,
        if (value != null) 'value': value,
      };
}

/// Livewire attribute (wire:click, wire:model, etc.)
final class LivewireAttribute extends AttributeNode {
  final String action;
  final List<String> modifiers;

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

/// Component node (<x-component>)
final class ComponentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children;

  final String name;
  final Map<String, AttributeNode> attributes;
  final Map<String, SlotNode> slots;
  final bool isSelfClosing;

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

/// Slot node for component slots
final class SlotNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children;

  final String name;
  final Map<String, AttributeNode> attributes;

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

/// HTML element node
final class HtmlElementNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children;

  final String tagName;
  final Map<String, AttributeNode> attributes;
  final bool isSelfClosing;
  final bool isVoid;

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

/// Comment node (Blade or HTML)
final class CommentNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children = const [];

  final String content;
  final bool isBladeComment;

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

/// Error node for parse errors
final class ErrorNode extends AstNode {
  @override
  final Position startPosition;
  @override
  final Position endPosition;
  @override
  final AstNode? parent;
  @override
  final List<AstNode> children = const [];

  final String error;
  final String? partialContent;

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
