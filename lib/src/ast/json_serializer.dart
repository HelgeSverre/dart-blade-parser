import 'node.dart';
import 'visitor.dart';

/// Visitor that serializes an AST to JSON.
/// This is an alternative to calling toJson() directly on nodes.
class JsonSerializerVisitor extends RecursiveAstVisitor<Map<String, dynamic>> {
  @override
  Map<String, dynamic> visitDocument(DocumentNode node) {
    return {
      'type': 'document',
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
      'children': node.children.map((c) => c.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitDirective(DirectiveNode node) {
    return {
      'type': 'directive',
      'name': node.name,
      if (node.expression != null) 'expression': node.expression,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
      'children': node.children.map((c) => c.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitComponent(ComponentNode node) {
    return {
      'type': 'component',
      'name': node.name,
      'attributes': node.attributes.map((k, v) => MapEntry(k, v.toJson())),
      'slots': node.slots.map((k, v) => MapEntry(k, v.accept(this))),
      'isSelfClosing': node.isSelfClosing,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
      'children': node.children.map((c) => c.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitSlot(SlotNode node) {
    return {
      'type': 'slot',
      'name': node.name,
      'attributes': node.attributes.map((k, v) => MapEntry(k, v.toJson())),
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
      'children': node.children.map((c) => c.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitEcho(EchoNode node) {
    return {
      'type': 'echo',
      'expression': node.expression,
      'isRaw': node.isRaw,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
    };
  }

  @override
  Map<String, dynamic> visitText(TextNode node) {
    return {
      'type': 'text',
      'content': node.content,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
    };
  }

  @override
  Map<String, dynamic> visitHtmlElement(HtmlElementNode node) {
    return {
      'type': 'htmlElement',
      'tagName': node.tagName,
      'attributes': node.attributes.map((k, v) => MapEntry(k, v.toJson())),
      'isSelfClosing': node.isSelfClosing,
      'isVoid': node.isVoid,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
      'children': node.children.map((c) => c.accept(this)).toList(),
    };
  }

  @override
  Map<String, dynamic> visitComment(CommentNode node) {
    return {
      'type': 'comment',
      'content': node.content,
      'isBladeComment': node.isBladeComment,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
    };
  }

  @override
  Map<String, dynamic> visitError(ErrorNode node) {
    return {
      'type': 'error',
      'error': node.error,
      if (node.partialContent != null) 'partialContent': node.partialContent,
      'position': {
        'start': node.startPosition.toJson(),
        'end': node.endPosition.toJson(),
      },
    };
  }

  @override
  Map<String, dynamic> defaultVisit(AstNode node) {
    // This should not be called for known node types
    throw UnimplementedError('Unknown node type: ${node.runtimeType}');
  }
}
