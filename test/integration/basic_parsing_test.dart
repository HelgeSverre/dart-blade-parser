import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Parsing Integration Tests', () {
    test('Parse simple text', () {
      final parser = BladeParser();
      final result = parser.parse('Hello World');

      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);
      expect(result.ast!.children.length, greaterThan(0));
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
      expect(result.ast!.children.length, greaterThan(1));
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
