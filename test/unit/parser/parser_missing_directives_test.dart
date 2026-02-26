import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Missing Directive Token Handling Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('parses @pushOnce directive', () {
      final result = parser.parse(
          '@pushOnce("scripts") <script>alert(1)</script> @endPushOnce');
      expect(result.isSuccess, isTrue);

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));

      final directive = directives.first;
      expect(directive.name, equals('pushOnce'));
      expect(directive.expression, isNotNull);
      expect(directive.children, isNotEmpty);
    });

    test('parses @prependOnce directive', () {
      final result = parser.parse(
          '@prependOnce("styles") <link rel="stylesheet"> @endPrependOnce');
      expect(result.isSuccess, isTrue);

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));

      final directive = directives.first;
      expect(directive.name, equals('prependOnce'));
      expect(directive.expression, isNotNull);
      expect(directive.children, isNotEmpty);
    });

    test('parses @pushIf directive', () {
      final result = parser.parse(
          r'@pushIf($shouldPush, "scripts") <script></script> @endPushIf');
      expect(result.isSuccess, isTrue);

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));

      final directive = directives.first;
      expect(directive.name, equals('pushIf'));
      expect(directive.expression, isNotNull);
      expect(directive.children, isNotEmpty);
    });
  });
}
