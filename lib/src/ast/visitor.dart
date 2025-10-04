import 'node.dart';

/// Base class for recursive AST visitors.
/// Provides default traversal logic for all node types.
abstract class RecursiveAstVisitor<T> implements AstVisitor<T> {
  /// Default visit method called for nodes without specific handling.
  T defaultVisit(AstNode node) {
    // Visit all children by default
    for (final child in node.children) {
      child.accept(this);
    }
    return null as T;
  }

  @override
  T visitDocument(DocumentNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultVisit(node);
  }

  @override
  T visitDirective(DirectiveNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultVisit(node);
  }

  @override
  T visitComponent(ComponentNode node) {
    // Visit slots first
    for (final slot in node.slots.values) {
      slot.accept(this);
    }
    // Then visit children
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultVisit(node);
  }

  @override
  T visitSlot(SlotNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultVisit(node);
  }

  @override
  T visitEcho(EchoNode node) {
    // Echo nodes are leaf nodes (no children)
    return defaultVisit(node);
  }

  @override
  T visitText(TextNode node) {
    // Text nodes are leaf nodes (no children)
    return defaultVisit(node);
  }

  @override
  T visitHtmlElement(HtmlElementNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultVisit(node);
  }

  @override
  T visitComment(CommentNode node) {
    // Comment nodes are leaf nodes (no children)
    return defaultVisit(node);
  }

  @override
  T visitError(ErrorNode node) {
    // Error nodes are typically leaf nodes
    return defaultVisit(node);
  }
}
