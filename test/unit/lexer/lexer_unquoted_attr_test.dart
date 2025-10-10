import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Test that unquoted attribute values properly stop at < character per HTML5 spec
void main() {
  group('Unquoted Attribute HTML5 Compliance', () {
    late BladeLexer lexer;

    test('Unquoted value should stop at < character', () {
      // Test that < in unquoted value properly terminates the value
      lexer = BladeLexer('<div class=foo<bar>Content</div>');
      final tokens = lexer.tokenize();

      // Find the attribute value token
      final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();

      // The value should be 'foo' and stop before '<'
      expect(attrValueTokens, isNotEmpty, reason: 'Should have attribute value');
      expect(attrValueTokens.first.value, equals('foo'),
          reason: 'Unquoted value should stop at < per HTML5 spec');
    });

    test('URL with colon still works in unquoted value', () {
      lexer = BladeLexer('<a href=https://example.com>Link</a>');
      final tokens = lexer.tokenize();

      final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();

      expect(attrValueTokens, isNotEmpty);
      expect(attrValueTokens.first.value, equals('https://example.com'),
          reason: 'Colons should be allowed in unquoted URLs');
    });

    test('Unquoted value with all valid characters', () {
      // Test various valid characters in unquoted values
      lexer = BladeLexer('<div data-test=abc123-_.xyz:8080/path>Content</div>');
      final tokens = lexer.tokenize();

      final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();

      expect(attrValueTokens, isNotEmpty);
      expect(attrValueTokens.first.value, equals('abc123-_.xyz:8080/path'),
          reason: 'Valid unquoted characters should all be accepted');
    });

    test('Multiple stop characters are handled correctly', () {
      // Test that all invalid characters properly stop unquoted values
      final testCases = [
        ('<div class=foo bar=baz>', 'foo', 'Space stops unquoted value'),
        ('<div class=foo\tbar=baz>', 'foo', 'Tab stops unquoted value'),
        ('<div class=foo\nbar=baz>', 'foo', 'Newline stops unquoted value'),
        ('<div class=foo"bar">', 'foo', 'Double quote stops unquoted value'),
        ('<div class=foo\'bar\'>', 'foo', 'Single quote stops unquoted value'),
        ('<div class=foo=bar>', 'foo', 'Equals stops unquoted value'),
        ('<div class=foo`bar`>', 'foo', 'Backtick stops unquoted value'),
        ('<div class=foo<bar>', 'foo', 'Less-than stops unquoted value'),
      ];

      for (final testCase in testCases) {
        lexer = BladeLexer(testCase.$1);
        final tokens = lexer.tokenize();
        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();

        if (attrValueTokens.isNotEmpty) {
          expect(attrValueTokens.first.value, equals(testCase.$2),
              reason: testCase.$3);
        }
      }
    });
  });
}