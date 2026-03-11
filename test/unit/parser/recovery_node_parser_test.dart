import 'package:blade_parser/blade_parser.dart';
import 'package:blade_parser/src/ast/node.dart';
import 'package:test/test.dart';

void main() {
  group('Parser RecoveryNode emission', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('stray HTML closers', () {
      test('stray closer becomes RecoveryNode child', () {
        final result = parser.parse('<div><span>Text</bogus>More</span></div>');

        expect(result.isSuccess, isFalse);
        final div = result.ast!.children[0] as HtmlElementNode;
        final span = div.children[0] as HtmlElementNode;

        final recoveryNodes = span.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
        expect(recoveryNodes.first.reason, contains('stray'));
      });

      test('top-level stray closer becomes RecoveryNode', () {
        final result = parser.parse('Hello</bogus>World');

        expect(result.isSuccess, isFalse);
        final recoveryNodes = result.ast!.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(1));
        expect(recoveryNodes.first.content, '</bogus>');
      });

      test('multiple stray closers each get their own RecoveryNode', () {
        final result = parser.parse('<div>A</foo>B</bar>C</div>');

        final div = result.ast!.children[0] as HtmlElementNode;
        final recoveryNodes = div.children.whereType<RecoveryNode>();
        expect(recoveryNodes, hasLength(2));
      });
    });
  });
}
