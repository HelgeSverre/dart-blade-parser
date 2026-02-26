import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Missing Directive Token Handling Tests', () {
    test('parses @pushOnce directive', () {
      final parser = BladeParser();
      final result = parser.parse(
          '@pushOnce("scripts") <script>alert(1)</script> @endPushOnce');
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'pushOnce'), isTrue,
          reason: '@pushOnce should be parsed as directive');
    });

    test('parses @prependOnce directive', () {
      final parser = BladeParser();
      final result = parser.parse(
          '@prependOnce("styles") <link rel="stylesheet"> @endPrependOnce');
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'prependOnce'), isTrue);
    });

    test('parses @pushIf directive', () {
      final parser = BladeParser();
      final result = parser.parse(
          '@pushIf(\$shouldPush, "scripts") <script></script> @endPushIf');
      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.any((d) => d.name == 'pushIf'), isTrue);
    });
  });
}
