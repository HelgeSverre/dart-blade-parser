import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Comprehensive test coverage for attribute value edge cases
void main() {
  group('Attribute Value Edge Cases', () {
    late BladeLexer lexer;

    group('URL Protocols', () {
      test('http:// protocol in unquoted value', () {
        lexer = BladeLexer('<a href=http://example.com>Link</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('http://example.com'));
      });

      test('https:// protocol in unquoted value', () {
        lexer = BladeLexer('<a href=https://example.com>Link</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('https://example.com'));
      });

      test('ftp:// protocol in unquoted value', () {
        lexer = BladeLexer('<a href=ftp://files.example.com>FTP</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('ftp://files.example.com'));
      });

      test('mailto: protocol in unquoted value', () {
        lexer = BladeLexer('<a href=mailto:user@example.com>Email</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('mailto:user@example.com'));
      });

      test('javascript: protocol in quoted value', () {
        lexer = BladeLexer('<a href="javascript:alert(\'test\')">JS</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('javascript:alert(\'test\')'));
      });

      test('data: protocol with image in quoted value', () {
        lexer = BladeLexer('<img src="data:image/png;base64,iVBORw0KGgoAAAANS">');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('data:image/png;base64,iVBORw0KGgoAAAANS'));
      });
    });

    group('URL Components', () {
      test('URL with port number', () {
        lexer = BladeLexer('<a href=https://example.com:8080>Link</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('https://example.com:8080'));
      });

      test('URL with path and fragment', () {
        lexer = BladeLexer('<a href=/docs/guide#section>Link</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('/docs/guide#section'));
      });

      test('URL with query string (must be quoted due to = character)', () {
        lexer = BladeLexer('<a href="/search?q=test&page=1">Search</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('/search?q=test&page=1'));
      });

      test('URL with path, query, and fragment', () {
        lexer = BladeLexer('<a href="/api/users?id=123&sort=name#details">Link</a>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('/api/users?id=123&sort=name#details'));
      });

      test('Complex data URI', () {
        lexer = BladeLexer('<img src="data:text/html;charset=utf-8,<h1>Hello</h1>">');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('data:text/html;charset=utf-8,<h1>Hello</h1>'));
      });
    });

    group('Special Characters in Unquoted Values', () {
      test('Unquoted value with periods (CSS classes)', () {
        lexer = BladeLexer('<div class=text.lg.bold>Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('text.lg.bold'));
      });

      test('Unquoted value with hyphens', () {
        lexer = BladeLexer('<div class=text-sm-center>Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('text-sm-center'));
      });

      test('Unquoted value with underscores', () {
        lexer = BladeLexer('<div data-test_value=some_value>Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens.length, greaterThanOrEqualTo(1));
        // Should have at least one unquoted value
        expect(attrValueTokens.any((t) => t.value.contains('_')), isTrue);
      });

      test('Mixed case attribute value', () {
        lexer = BladeLexer('<button onclick=handleClick>Click</button>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('handleClick'));
      });
    });

    group('Numeric and Boolean Values', () {
      test('Numeric value - tabindex', () {
        lexer = BladeLexer('<input tabindex=0>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('0'));
      });

      test('Numeric value - maxlength', () {
        lexer = BladeLexer('<input maxlength=100>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('100'));
      });

      test('Boolean-like value - disabled=false', () {
        lexer = BladeLexer('<button disabled=false>Click</button>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('false'));
      });

      test('Boolean-like value - checked=true', () {
        lexer = BladeLexer('<input type=checkbox checked=true>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens.length, greaterThanOrEqualTo(2));
        // Should have 'checkbox' and 'true'
        expect(attrValueTokens.any((t) => t.value == 'true'), isTrue);
      });
    });

    group('Empty and Quoted Values', () {
      test('Empty double-quoted value', () {
        lexer = BladeLexer('<div class="">Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals(''));
      });

      test('Empty single-quoted value', () {
        lexer = BladeLexer("<div class=''>Content</div>");
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals(''));
      });

      test('Single-quoted with escaped quote', () {
        lexer = BladeLexer("<div title='It\\'s working'>Content</div>");
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('It\\\'s working'));
      });

      test('Double-quoted with escaped quote', () {
        lexer = BladeLexer('<div title="Say \\"hello\\"">Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, equals('Say \\"hello\\"'));
      });
    });

    group('Alpine.js Expressions', () {
      test('Alpine x-text with template literal', () {
        lexer = BladeLexer('<div x-text="`Hello \${name}`">Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, contains('Hello'));
        expect(attrValueTokens.first.value, contains('name'));
      });

      test('Alpine x-bind with complex expression', () {
        lexer = BladeLexer('<div x-bind:class="{ active: isActive, disabled: !isEnabled }">Content</div>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, contains('active'));
        expect(attrValueTokens.first.value, contains('isActive'));
      });

      test('Alpine x-on with arrow function', () {
        lexer = BladeLexer('<button x-on:click="() => count++">Increment</button>');
        final tokens = lexer.tokenize();

        final attrValueTokens = tokens.where((t) => t.type == TokenType.attributeValue).toList();
        expect(attrValueTokens, isNotEmpty);
        expect(attrValueTokens.first.value, contains('count++'));
      });
    });
  });
}
