import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for Blade echo expressions ({{ }}) inside script blocks.
/// Blade templates commonly use {{ }} inside <script> to inject PHP values.
/// The lexer should tokenize these as echo expressions, not raw text.
void main() {
  group('Blade expressions inside script blocks', () {
    test('{{ }} echo inside script block is tokenized as echo', () {
      final lexer = BladeLexer(
        '<script>\nconst x = \'{{ \$foo }}\';\n</script>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.echoOpen),
        isTrue,
        reason: '{{ inside <script> should be tokenized as echo',
      );
      expect(
        tokens.any((t) => t.type == TokenType.echoClose),
        isTrue,
        reason: '}} inside <script> should be tokenized as echo close',
      );
    });

    test('{{ }} with null coalesce inside script block', () {
      final lexer = BladeLexer(
        '<script>\nconst appearance = \'{{ \$appearance ?? "system" }}\';\n</script>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.echoOpen),
        isTrue,
        reason: '{{ inside <script> should be tokenized as echo',
      );

      // The expression should contain the null coalesce
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.expression && t.value.contains('appearance'),
        ),
        isTrue,
        reason: 'Expression content should be preserved',
      );
    });

    test('{!! !!} raw echo inside script block is tokenized', () {
      final lexer = BladeLexer(
        '<script>\nconst data = {!! \$json !!};\n</script>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.rawEchoOpen),
        isTrue,
        reason: '{!! inside <script> should be tokenized as raw echo',
      );
    });

    test('Blade comment inside script block is tokenized', () {
      final lexer = BladeLexer(
        '<script>\n{{-- This is a comment --}}\nconst x = 1;\n</script>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.bladeComment),
        isTrue,
        reason: '{{-- inside <script> should be tokenized as comment',
      );
    });

    test('script content without Blade expressions is still raw text', () {
      final lexer = BladeLexer(
        '<script>\nconst x = 1;\nif (x < 10) { alert("hi"); }\n</script>',
      );
      final tokens = lexer.tokenize();

      // Should NOT have echo tokens
      expect(
        tokens.any((t) => t.type == TokenType.echoOpen),
        isFalse,
        reason: 'Plain JS should not produce echo tokens',
      );

      // Content should be preserved as text
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
      expect(
        echoOpens.length,
        equals(2),
        reason: 'Should find two echo expressions in script',
      );
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

      // Should have echo open/close tokens
      expect(
        tokens.any((t) => t.type == TokenType.echoOpen),
        isTrue,
        reason: 'Real-world script with {{ }} should tokenize echo',
      );

      // JavaScript < and > comparisons should NOT create HTML tokens
      expect(
        tokens.where((t) => t.type == TokenType.htmlTagOpen).length,
        equals(1), // Only the <script> tag itself
        reason: 'JS comparison operators should not create HTML tag tokens',
      );
    });

    test('{{ }} in style block is tokenized as echo', () {
      final lexer = BladeLexer(
        '<style>\nbody { color: {{ \$color }}; }\n</style>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.echoOpen),
        isTrue,
        reason: '{{ inside <style> should be tokenized as echo',
      );
    });
  });
}
