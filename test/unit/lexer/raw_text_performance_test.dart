import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Raw text lexing correctness', () {
    test('large inline script block is lexed correctly', () {
      // Generate a large script block (~50KB of JS)
      final jsLines = StringBuffer();
      for (var i = 0; i < 500; i++) {
        jsLines.writeln('    const variable$i = { key$i: "value$i", count: $i };');
        jsLines.writeln('    function handler$i(event) { return event.target.value; }');
      }
      final input = '<div>\n<script>\n$jsLines</script>\n</div>';

      final lexer = BladeLexer(input);
      final tokens = lexer.tokenize();

      // Should contain the script tag structure
      final types = tokens.map((t) => t.type).toList();
      expect(types, contains(TokenType.htmlTagName));

      // Find script tag name token
      final scriptTag = tokens.firstWhere(
        (t) => t.type == TokenType.htmlTagName && t.value == 'script',
      );
      expect(scriptTag.value, equals('script'));

      // Should have text content (the JS code)
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.any((t) => t.value.contains('variable0')), isTrue);
      expect(textTokens.any((t) => t.value.contains('variable499')), isTrue);
    });

    test('large inline SVG block is lexed correctly', () {
      // Generate a large SVG with many paths
      final svgPaths = StringBuffer();
      for (var i = 0; i < 200; i++) {
        svgPaths.writeln(
          '    <path d="M${i} ${i + 1} L${i + 10} ${i + 20} Z" '
          'fill="none" stroke="currentColor" stroke-width="2"/>',
        );
      }
      final input = '<svg xmlns="http://www.w3.org/2000/svg">$svgPaths</svg>';

      final lexer = BladeLexer(input);
      final tokens = lexer.tokenize();

      // Should parse without errors
      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      expect(errors, isEmpty);
    });

    test('script with Blade expressions inside is lexed correctly', () {
      final input = '''<script>
    const config = {!! json_encode(\$config) !!};
    const name = '{{ \$name }}';
    const items = {!! \$items !!};
</script>''';

      final lexer = BladeLexer(input);
      final tokens = lexer.tokenize();

      // Should contain Blade echo tokens inside the script
      final types = tokens.map((t) => t.type).toList();
      expect(types, contains(TokenType.rawEchoOpen));
      expect(types, contains(TokenType.echoOpen));
    });
  });
}
