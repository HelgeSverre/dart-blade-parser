import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for Blade echo expressions inside quoted HTML attribute values.
/// Quotes inside {{ }} and {!! !!} should not close the attribute value.
void main() {
  group('Echoes inside quoted attribute values', () {
    late BladeLexer lexer;

    test('simple echo in double-quoted attribute', () {
      lexer = BladeLexer('<div wire:key="{{ \$id }}">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('{{ \$id }}'));
    });

    test('echo with double-quoted string inside double-quoted attribute', () {
      lexer = BladeLexer(
          '<div wire:key="{{ isset(\$this) ? "{\$this->getId()}." : \'\' }}modal.{{ \$id }}.window">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      // The entire value between the outer quotes should be captured
      expect(attrValues.first.value, contains('isset'));
      expect(attrValues.first.value, contains('modal'));
      expect(attrValues.first.value, contains('.window'));
    });

    test('raw echo in double-quoted attribute', () {
      lexer = BladeLexer('<div data-value="{!! \$html !!}">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('{!! \$html !!}'));
    });

    test('echo with method call containing quotes', () {
      lexer = BladeLexer(
          '<input wire:key="{{ \$this->getId() }}">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('{{ \$this->getId() }}'));
    });

    test('multiple echoes in one attribute value', () {
      lexer = BladeLexer(
          '<div class="{{ \$base }}-{{ \$variant }}">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('{{ \$base }}-{{ \$variant }}'));
    });

    test('echo in single-quoted attribute', () {
      lexer = BladeLexer("<div class='{{ \$classes }}'>");
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('{{ \$classes }}'));
    });

    test('echo with ternary containing strings in attribute', () {
      lexer = BladeLexer(
          '<div class="{{ \$active ? "text-blue" : "text-gray" }}">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, contains('text-blue'));
      expect(attrValues.first.value, contains('text-gray'));
    });
  });
}
