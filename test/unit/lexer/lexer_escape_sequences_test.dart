import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Comprehensive edge case tests for Blade escape sequences (@@ and @{{)
/// These tests verify correct handling of escape sequences in various contexts
void main() {
  group('Escape Sequences - @@ Tests', () {
    late BladeLexer lexer;

    test('@@ at start of input', () {
      lexer = BladeLexer('@@directive this is literal');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, equals('@directive this is literal'));

      // Should NOT be parsed as directive
      expect(
        tokens.any((t) => t.type.toString().contains('directive')),
        isFalse,
      );
    });

    test('@@ at end of input', () {
      lexer = BladeLexer('email me at admin@@');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, equals('email me at admin@'));
    });

    test('Multiple consecutive @@ (@@@@)', () {
      lexer = BladeLexer('test @@@@example');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      // @@@@ should become @@
      expect(combinedText, equals('test @@example'));
    });

    test('@@ inside verbatim blocks', () {
      lexer = BladeLexer('@verbatim\nuser@@example.com\n@endverbatim');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      // Inside verbatim, @@ should remain as @@ (literal)
      final verbatimContent = textTokens.map((t) => t.value).join('');
      expect(verbatimContent, contains('user@@example.com'));
    });

    test('@@ in script tags', () {
      lexer = BladeLexer(
        '<script>\nvar email = "user@@domain.com";\n</script>',
      );
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();

      // In raw text context (script tag), @@ should become @
      final scriptContent = textTokens
          .where((t) => t.value.contains('email'))
          .firstOrNull;
      expect(scriptContent, isNotNull);
    });

    test('@@ in style tags', () {
      lexer = BladeLexer(
        '<style>\n/* Comment with @@ */\n.class { }\n</style>',
      );
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      // Style content should be present
      final styleContent = textTokens
          .where((t) => t.value.contains('Comment'))
          .firstOrNull;
      expect(styleContent, isNotNull);
    });

    test('@{{ combined with @@', () {
      lexer = BladeLexer('@@if and @{{ \$var }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      // Both escapes should work
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains('@if'));
      expect(combinedText, contains('@{{'));

      // Should not have directive or echo tokens
      expect(tokens.any((t) => t.type == TokenType.directiveIf), isFalse);
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });
  });

  group('Escape Sequences - @{{ Tests', () {
    late BladeLexer lexer;

    test('Escaped echo at start of input', () {
      lexer = BladeLexer('@{{ \$variable }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, equals('@{{ \$variable }}'));

      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('Escaped echo at end of input', () {
      lexer = BladeLexer('Display literal: @{{ \$var }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains('@{{ \$var }}'));

      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('Multiple @{{ in sequence', () {
      lexer = BladeLexer('@{{ \$a }} @{{ \$b }} @{{ \$c }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      // All should be literal text
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains('@{{ \$a }}'));
      expect(combinedText, contains('@{{ \$b }}'));
      expect(combinedText, contains('@{{ \$c }}'));

      // Should NOT have any echo tokens
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('Escaped quotes inside @{{ ... }}', () {
      lexer = BladeLexer('@{{ "Hello \\"World\\"" }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains('\\"'));

      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('@{{ with nested braces', () {
      lexer = BladeLexer('@{{ { key: "value" } }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);

      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains('@{{'));
      expect(combinedText, contains('key:'));

      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('@{{ in HTML attribute', () {
      lexer = BladeLexer('<div title="@{{ \$tooltip }}">Content</div>');
      final tokens = lexer.tokenize();

      // Should have escaped echo in text or attribute value tokens
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final attrValueTokens = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();

      final hasEscapedEcho =
          textTokens.any((t) => t.value.contains('@{{')) ||
          attrValueTokens.any((t) => t.value.contains('@{{'));
      expect(hasEscapedEcho, isTrue);

      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('@{{ vs {{ difference', () {
      // Normal echo
      lexer = BladeLexer('{{ \$var }}');
      var tokens = lexer.tokenize();
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      // Escaped echo
      lexer = BladeLexer('@{{ \$var }}');
      tokens = lexer.tokenize();
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.any((t) => t.value.contains('@{{')), isTrue);
    });

    test('@{{ in Blade comment', () {
      lexer = BladeLexer('{{-- @{{ \$var }} is escaped --}}');
      final tokens = lexer.tokenize();

      final commentTokens = tokens
          .where((t) => t.type == TokenType.bladeComment)
          .toList();
      expect(commentTokens.length, equals(1));
      expect(commentTokens.first.value, contains('@{{'));
    });
  });
}
