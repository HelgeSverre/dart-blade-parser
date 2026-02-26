import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Parsing Integration Tests', () {
    test('Parse simple text', () {
      final parser = BladeParser();
      final result = parser.parse('Hello World');

      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);
      expect(result.ast!.children.length, equals(1));
      expect(result.ast!.children.first, isA<TextNode>());
      expect((result.ast!.children.first as TextNode).content, equals('Hello World'));
    });

    test('Parse simple echo', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$user }}');

      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);

      // Find echo node
      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.expression, contains('user'));
      expect(echoNodes.first.isRaw, isFalse);
    });

    test('Parse raw echo', () {
      final parser = BladeParser();
      final result = parser.parse('{!! \$html !!}');

      expect(result.isSuccess, isTrue);

      final echoNodes = result.ast!.children.whereType<EchoNode>();
      expect(echoNodes.length, equals(1));
      expect(echoNodes.first.isRaw, isTrue);
    });

    test('Parse @if directive with @endif', () {
      final parser = BladeParser();
      final result = parser.parse('@if(\$test)\n  Hello\n@endif');

      expect(result.isSuccess, isTrue);

      final directives = result.ast!.children.whereType<DirectiveNode>();
      expect(directives.length, equals(1));
      expect(directives.first.name, equals('if'));
      expect(directives.first.expression, contains('\$test'));
      expect(directives.first.children, isNotEmpty);
    });

    test('Detect unclosed @if directive', () {
      final parser = BladeParser();
      final result = parser.parse('@if(\$test)\n  Hello');

      expect(result.isSuccess, isFalse);
      expect(result.errors.length, greaterThan(0));
      expect(result.errors.first.message, contains('Unclosed @if'));
    });

    test('Parse mixed content', () {
      final parser = BladeParser();
      final result = parser.parse('Hello {{ \$name }}, welcome!');

      expect(result.isSuccess, isTrue);
      expect(result.ast!.children.length, equals(3));
      expect(result.ast!.children[0], isA<TextNode>());
      expect(result.ast!.children[1], isA<EchoNode>());
      expect((result.ast!.children[1] as EchoNode).expression, contains('\$name'));
      expect(result.ast!.children[2], isA<TextNode>());
    });

    test('JSON serialization works', () {
      final parser = BladeParser();
      final result = parser.parse('{{ \$test }}');

      expect(result.isSuccess, isTrue);

      final json = result.ast!.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['type'], equals('document'));
      expect(json['children'], isA<List>());
    });
  });
}
