import 'package:blade_parser/src/lexer/lexer.dart';
import 'package:blade_parser/src/lexer/token_type.dart';
import 'package:test/test.dart';

void main() {
  group('PHP block lexing', () {
    test('lexes <?php ... ?> as phpBlock token', () {
      final lexer = BladeLexer('<?php \$x = 1; ?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?php \$x = 1; ?>');
    });

    test('lexes <?= ... ?> as phpBlock token', () {
      final lexer = BladeLexer('<?= \$name ?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?= \$name ?>');
    });

    test('lexes <? ... ?> as phpBlock token', () {
      final lexer = BladeLexer('<? echo "hi"; ?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<? echo "hi"; ?>');
    });

    test('preserves text before and after PHP block', () {
      final lexer = BladeLexer('Hello <?php \$x = 1; ?> World');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?php \$x = 1; ?>');
      // Text before and after should be preserved
      final textTokens =
          tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.length, greaterThanOrEqualTo(1));
    });

    test('lexes multiline <?php block', () {
      final lexer = BladeLexer('<?php\n\$x = 1;\n\$y = 2;\n?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
    });

    test('lexes unclosed <?php to EOF', () {
      final lexer = BladeLexer('<?php\n\$x = 1;\necho "done";');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
    });

    test('does not confuse <?xml with PHP tag', () {
      final lexer = BladeLexer('<?xml version="1.0"?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, isEmpty);
    });

    test('lexes inline <?= inside template', () {
      final lexer = BladeLexer('Hello <?= \$greeting ?> there');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(1));
      expect(phpTokens.first.value, '<?= \$greeting ?>');
    });

    test('lexes multiple PHP blocks', () {
      final lexer = BladeLexer('<?php \$a = 1; ?> middle <?= \$a ?>');
      final tokens = lexer.tokenize();
      final phpTokens =
          tokens.where((t) => t.type == TokenType.phpBlock).toList();
      expect(phpTokens, hasLength(2));
    });
  });
}
