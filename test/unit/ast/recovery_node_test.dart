import 'package:blade_parser/src/ast/node.dart';
import 'package:blade_parser/src/lexer/position.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryNode', () {
    test('stores content, reason, and positions', () {
      final node = RecoveryNode(
        content: '</bogus>',
        reason: 'stray closing tag',
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 8, line: 1, column: 9),
      );

      expect(node.content, '</bogus>');
      expect(node.reason, 'stray closing tag');
      expect(node.children, isEmpty);
    });

    test('accepts visitor via visitRecovery', () {
      final node = RecoveryNode(
        content: '???',
        reason: 'skipped region',
        startPosition: Position(offset: 0, line: 1, column: 1),
        endPosition: Position(offset: 3, line: 1, column: 4),
      );

      final visited = node.accept(_TestVisitor());
      expect(visited, 'recovery:???');
    });

    test('serializes to JSON', () {
      final node = RecoveryNode(
        content: '</bogus>',
        reason: 'stray closing tag',
        startPosition: Position(offset: 5, line: 1, column: 6),
        endPosition: Position(offset: 13, line: 1, column: 14),
      );

      final json = node.toJson();
      expect(json['type'], 'recovery');
      expect(json['content'], '</bogus>');
      expect(json['reason'], 'stray closing tag');
    });
  });
}

class _TestVisitor implements AstVisitor<String> {
  @override
  String visitDocument(DocumentNode n) => '';
  @override
  String visitDirective(DirectiveNode n) => '';
  @override
  String visitComponent(ComponentNode n) => '';
  @override
  String visitEcho(EchoNode n) => '';
  @override
  String visitText(TextNode n) => '';
  @override
  String visitHtmlElement(HtmlElementNode n) => '';
  @override
  String visitComment(CommentNode n) => '';
  @override
  String visitError(ErrorNode n) => '';
  @override
  String visitSlot(SlotNode n) => '';
  @override
  String visitPhpBlock(PhpBlockNode n) => '';
  @override
  String visitRecovery(RecoveryNode n) => 'recovery:${n.content}';
}
