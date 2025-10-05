import 'node.dart';

/// Base class for recursive AST visitors.
/// Provides default traversal logic for all node types.
///
/// Type parameter T should be nullable if you don't return meaningful values.
/// Override [defaultValue] to provide a safe default return value.
abstract class RecursiveAstVisitor<T> implements AstVisitor<T> {
  /// Default value returned from visit methods.
  /// Override this to provide a safe default for your visitor type.
  T get defaultValue;

  /// Default visit method called for nodes without specific handling.
  /// Note: This does NOT traverse children - override visit methods to control traversal.
  T defaultVisit(AstNode node) {
    return defaultValue;
  }

  @override
  T visitDocument(DocumentNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultValue;
  }

  @override
  T visitDirective(DirectiveNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultValue;
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
    return defaultValue;
  }

  @override
  T visitSlot(SlotNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultValue;
  }

  @override
  T visitEcho(EchoNode node) {
    // Echo nodes are leaf nodes (no children)
    return defaultValue;
  }

  @override
  T visitText(TextNode node) {
    // Text nodes are leaf nodes (no children)
    return defaultValue;
  }

  @override
  T visitHtmlElement(HtmlElementNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
    return defaultValue;
  }

  @override
  T visitComment(CommentNode node) {
    // Comment nodes are leaf nodes (no children)
    return defaultValue;
  }

  @override
  T visitError(ErrorNode node) {
    // Error nodes are typically leaf nodes
    return defaultValue;
  }
}
