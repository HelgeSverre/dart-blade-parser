import 'package:blade_parser/src/ast/node.dart';

List<RecoveryNode> collectRecoveryNodes(AstNode node) {
  final found = <RecoveryNode>[];

  void inspectTagHead(List<TagHeadItem> tagHead) {
    for (final item in tagHead) {
      if (item is TagHeadRecovery) {
        found.add(item.node);
      }
    }
  }

  void visit(AstNode current) {
    if (current is RecoveryNode) {
      found.add(current);
    }

    if (current is HtmlElementNode) {
      inspectTagHead(current.tagHead);
    } else if (current is ComponentNode) {
      inspectTagHead(current.tagHead);
    }

    for (final child in current.children) {
      visit(child);
    }

    if (current is ComponentNode) {
      for (final slot in current.slots.values) {
        visit(slot);
      }
    }
  }

  visit(node);
  return found;
}
