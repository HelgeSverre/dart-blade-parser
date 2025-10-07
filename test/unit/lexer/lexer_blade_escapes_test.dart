import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for Blade escape sequences (@{{ and @@)
/// These tests EXPOSE bugs in the current implementation
void main() {
  group('Escaped Echo @{{ Tests (EXPECTED TO FAIL)', () {
    late BladeLexer lexer;

    test('Simple escaped echo should be text, not echo', () {
      lexer = BladeLexer('@{{ \$variable }}');
      final tokens = lexer.tokenize();

      // Expected: Single text token containing '@{{ $variable }}'
      // Current bug: Text '@' + echo tokens for '{{ $variable }}'
      
      // Filter out EOF token
      final nonEofTokens = tokens.where((t) => t.type != TokenType.eof).toList();
      
      // Should be exactly one text token
      expect(nonEofTokens.length, equals(1), 
        reason: 'Should be single text token, not split into @ and echo');
      expect(nonEofTokens.first.type, equals(TokenType.text));
      expect(nonEofTokens.first.value, equals('@{{ \$variable }}'));
      
      // Should NOT have any echo tokens
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse,
        reason: '@{{ should be escaped, not parsed as echo');
    });

    test('Escaped echo with nested braces', () {
      lexer = BladeLexer('@{{ \$array[\'key\'] }}');
      final tokens = lexer.tokenize();

      final nonEofTokens = tokens.where((t) => t.type != TokenType.eof).toList();
      
      expect(nonEofTokens.length, equals(1));
      expect(nonEofTokens.first.type, equals(TokenType.text));
      expect(nonEofTokens.first.value, contains('@{{'));
      
      // Should NOT be parsed as echo
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
    });

    test('Multiple escaped echoes', () {
      lexer = BladeLexer('@{{ \$a }} and @{{ \$b }}');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      
      // Should have text tokens containing the escaped echoes
      expect(textTokens.length, greaterThan(0));
      
      // Should NOT have echo tokens
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse,
        reason: 'Both @{{ should be escaped');
    });

    test('Escaped echo in mixed content', () {
      lexer = BladeLexer('Use @{{ \$var }} for literal display');
      final tokens = lexer.tokenize();

      // Should be all text, no echo parsing
      expect(tokens.any((t) => t.type == TokenType.echoOpen), isFalse);
      
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.any((t) => t.value.contains('@{{')), isTrue);
    });
  });

  group('Escaped Echo @{{ Parser Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('Escaped echo in HTML should be text', () {
      final result = parser.parse('<p>Use @{{ \$var }} for literal</p>');

      expect(result.isSuccess, isTrue);
      
      final html = result.ast!.children.first as HtmlElementNode;
      final textChildren = html.children.whereType<TextNode>();
      
      // Text should contain the literal @{{ }}
      final hasEscapedEcho = textChildren.any((t) => t.content.contains('@{{'));
      expect(hasEscapedEcho, isTrue,
        reason: '@{{ should appear literally in text, not be parsed as echo');
      
      // Should NOT have echo nodes
      final echoChildren = html.children.whereType<EchoNode>();
      expect(echoChildren, isEmpty,
        reason: '@{{ should not create EchoNode');
    });

    test('Normal echo vs escaped echo difference', () {
      // Normal echo
      final normalResult = parser.parse('{{ \$var }}');
      final normalEchoes = normalResult.ast!.children.whereType<EchoNode>();
      expect(normalEchoes.length, equals(1), 
        reason: 'Normal {{ }} should create echo');

      // Escaped echo
      final escapedResult = parser.parse('@{{ \$var }}');
      final escapedEchoes = escapedResult.ast!.children.whereType<EchoNode>();
      expect(escapedEchoes.length, equals(0),
        reason: 'Escaped @{{ }} should NOT create echo');
      
      final textNodes = escapedResult.ast!.children.whereType<TextNode>();
      expect(textNodes.any((t) => t.content.contains('@{{')), isTrue);
    });
  });

  group('Literal @@ Escape Tests (EXPECTED TO FAIL)', () {
    late BladeLexer lexer;

    test('Simple @@ should produce single @ in text', () {
      lexer = BladeLexer('Contact us at admin@@example.com');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);
      
      // The @@ should be normalized to single @
      // Current bug: likely keeps @@ as-is or has undefined behavior
      final hasNormalizedAt = textTokens.any((t) => 
        t.value.contains('admin@example.com') && !t.value.contains('@@'));
      
      expect(hasNormalizedAt, isTrue,
        reason: '@@ should be converted to single @ in output');
    });

    test('@@ before directive-like word', () {
      lexer = BladeLexer('@@if this is literal text');
      final tokens = lexer.tokenize();

      // Should be text, not an @if directive
      expect(tokens.any((t) => t.type == TokenType.directiveIf), isFalse,
        reason: '@@if should be literal @if, not a directive');
      
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);
      expect(textTokens.first.value, equals('@if this is literal text'));
    });

    test('Multiple @@ in string', () {
      lexer = BladeLexer('user@@domain.com or admin@@domain.com');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      
      // Both @@ should be normalized
      final content = textTokens.map((t) => t.value).join();
      expect(content.contains('user@domain.com'), isTrue);
      expect(content.contains('admin@domain.com'), isTrue);
      expect(content.contains('@@'), isFalse,
        reason: 'All @@ should be converted to single @');
    });

    test('@@ vs @ in email addresses', () {
      // Regular @ in email should stay as-is
      lexer = BladeLexer('Regular email: user@example.com');
      var tokens = lexer.tokenize();
      var text = tokens.where((t) => t.type == TokenType.text).first.value;
      expect(text, contains('user@example.com'));

      // @@ should be escaped to @
      lexer = BladeLexer('Escaped: user@@example.com');
      tokens = lexer.tokenize();
      text = tokens.where((t) => t.type == TokenType.text).first.value;
      expect(text, equals('Escaped: user@example.com'),
        reason: '@@ should normalize to @');
    });
  });

  group('Literal @@ Parser Tests (EXPECTED TO FAIL)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    test('@@ in content produces literal @', () {
      final result = parser.parse('<p>Email: admin@@site.com</p>');
      
      expect(result.isSuccess, isTrue);
      
      final html = result.ast!.children.first as HtmlElementNode;
      final textNodes = html.children.whereType<TextNode>();
      
      expect(textNodes, isNotEmpty);
      final textContent = textNodes.map((t) => t.content).join();
      
      // Should contain admin@site.com (single @)
      expect(textContent, contains('admin@site.com'));
      expect(textContent, isNot(contains('@@')),
        reason: '@@ should be normalized to single @');
    });
  });
}
