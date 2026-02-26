import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for Blade echo expressions ({{ }}) inside script blocks.
/// Blade templates commonly use {{ }} inside <script> to inject PHP values.
/// The lexer should tokenize these as echo expressions, not raw text.
void main() {
  group('Blade expressions inside script blocks', () {
    test('{{ }} echo inside script block produces echo open/close tokens', () {
      final lexer = BladeLexer(
        '<script>\nconst x = \'{{ \$foo }}\';\n</script>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.echoOpen));
      expect(types, contains(TokenType.echoClose));

      // Verify token sequence around the echo
      final echoOpenIdx =
          tokens.indexWhere((t) => t.type == TokenType.echoOpen);
      expect(tokens[echoOpenIdx].value, equals('{{'));
      expect(tokens[echoOpenIdx + 1].type, equals(TokenType.expression));
      expect(tokens[echoOpenIdx + 1].value.trim(), equals('\$foo'));
      expect(tokens[echoOpenIdx + 2].type, equals(TokenType.echoClose));
      expect(tokens[echoOpenIdx + 2].value, equals('}}'));
    });

    test('{{ }} with null coalesce inside script block', () {
      final lexer = BladeLexer(
        '<script>\nconst appearance = \'{{ \$appearance ?? "system" }}\';\n</script>',
      );
      final tokens = lexer.tokenize();

      final exprToken = tokens.firstWhere(
        (t) =>
            t.type == TokenType.expression && t.value.contains('appearance'),
      );
      expect(exprToken.value, contains('\$appearance ?? "system"'));
    });

    test('{!! !!} raw echo inside script block is tokenized', () {
      final lexer = BladeLexer(
        '<script>\nconst data = {!! \$json !!};\n</script>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.rawEchoOpen));
      expect(types, contains(TokenType.rawEchoClose));

      final rawOpenIdx =
          tokens.indexWhere((t) => t.type == TokenType.rawEchoOpen);
      expect(tokens[rawOpenIdx + 1].type, equals(TokenType.expression));
      expect(tokens[rawOpenIdx + 1].value.trim(), equals('\$json'));
    });

    test('Blade comment inside script block is tokenized', () {
      final lexer = BladeLexer(
        '<script>\n{{-- This is a comment --}}\nconst x = 1;\n</script>',
      );
      final tokens = lexer.tokenize();

      final commentToken =
          tokens.firstWhere((t) => t.type == TokenType.bladeComment);
      expect(commentToken.value, equals('{{-- This is a comment --}}'));
    });

    test('script content without Blade expressions is still raw text', () {
      final lexer = BladeLexer(
        '<script>\nconst x = 1;\nif (x < 10) { alert("hi"); }\n</script>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, isNot(contains(TokenType.echoOpen)));

      final textTokens = tokens.where((t) => t.type == TokenType.text);
      final textContent = textTokens.map((t) => t.value).join();
      expect(textContent, contains('x < 10'));
    });

    test('multiple {{ }} expressions in script block', () {
      final lexer = BladeLexer(
        '<script>\nconst a = \'{{ \$foo }}\';\nconst b = \'{{ \$bar }}\';\n</script>',
      );
      final tokens = lexer.tokenize();

      final echoOpens =
          tokens.where((t) => t.type == TokenType.echoOpen).toList();
      expect(echoOpens.length, equals(2));

      // Verify both expressions are captured
      final expressions = tokens
          .where((t) => t.type == TokenType.expression)
          .map((t) => t.value.trim())
          .toList();
      expect(expressions, contains('\$foo'));
      expect(expressions, contains('\$bar'));
    });

    test('real-world script block with Blade expression', () {
      const input = '''<script>
    (function() {
        const appearance = '{{ \$appearance ?? "system" }}';
        if (appearance === "system") {
            const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
            if (prefersDark) {
                document.documentElement.classList.add("dark");
            }
        }
    })();
</script>''';
      final lexer = BladeLexer(input);
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.echoOpen));
      expect(types, contains(TokenType.echoClose));

      // Only one <script> HTML tag — JS comparison operators should not create more
      final htmlTagOpens =
          tokens.where((t) => t.type == TokenType.htmlTagOpen).toList();
      expect(htmlTagOpens.length, equals(1));
    });

    test('{{ }} in style block is tokenized as echo', () {
      final lexer = BladeLexer(
        '<style>\nbody { color: {{ \$color }}; }\n</style>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.echoOpen));
      expect(types, contains(TokenType.echoClose));
    });

    test('quote state persists across Blade expression in script', () {
      // The </script> inside the string should NOT close the script block
      final lexer = BladeLexer(
        "<script>\nconst str = '{{ \$val }}</script>still inside';\n</script>",
      );
      final tokens = lexer.tokenize();

      // Should have exactly one closing script tag token
      final closingTags =
          tokens.where((t) => t.type == TokenType.htmlClosingTagStart).toList();
      expect(closingTags.length, equals(1));

      // The text after the echo should include the fake </script> as content
      final textAfterEcho = tokens.where(
        (t) => t.type == TokenType.text && t.value.contains('still inside'),
      );
      expect(textAfterEcho.length, equals(1));
    });
  });
}
