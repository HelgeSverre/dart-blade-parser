import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for compound colon attributes like :wire:click, :x-bind:class,
/// :wire:model.live which should be lexed as a single token.
void main() {
  group('Compound colon attributes in :bind shorthand', () {
    late BladeLexer lexer;

    test(':wire:click is a single alpineShorthandBind token', () {
      lexer = BladeLexer('<div :wire:click="test">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(bindTokens.first.value, equals(':wire:click'));
    });

    test(':x-bind:class is a single alpineShorthandBind token', () {
      lexer = BladeLexer('<div :x-bind:class="foo">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(bindTokens.first.value, equals(':x-bind:class'));
    });

    test(':wire:model.live is a single alpineShorthandBind token', () {
      lexer = BladeLexer('<div :wire:model.live="bar">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(bindTokens.first.value, equals(':wire:model.live'));
    });

    test(':wire:model.live.debounce.300ms is a single token', () {
      lexer = BladeLexer('<div :wire:model.live.debounce.300ms="val">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(
          bindTokens.first.value, equals(':wire:model.live.debounce.300ms'));
    });

    test('attribute value is preserved for compound colon attributes', () {
      lexer = BladeLexer('<div :wire:click="doSomething">');
      final tokens = lexer.tokenize();

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('doSomething'));
    });

    test('simple :class still works', () {
      lexer = BladeLexer('<div :class="active">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(bindTokens.first.value, equals(':class'));
    });

    test('compound colon attribute in component tag', () {
      lexer = BladeLexer('<x-input :wire:model.live="name" />');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(1));
      expect(bindTokens.first.value, equals(':wire:model.live'));

      final attrValues = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attrValues, hasLength(1));
      expect(attrValues.first.value, equals('name'));
    });

    test('multiple compound colon attributes on same element', () {
      lexer = BladeLexer(
          '<div :wire:click="action" :x-bind:class="classes">');
      final tokens = lexer.tokenize();

      final bindTokens = tokens
          .where((t) => t.type == TokenType.alpineShorthandBind)
          .toList();
      expect(bindTokens, hasLength(2));
      expect(bindTokens[0].value, equals(':wire:click'));
      expect(bindTokens[1].value, equals(':x-bind:class'));
    });
  });
}
