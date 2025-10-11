import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Comprehensive edge case tests for whitespace handling in the lexer
/// Tests tabs, vertical tabs, form feeds, non-breaking spaces, zero-width spaces,
/// mixed line endings, and whitespace in various contexts
void main() {
  group('Whitespace - Tab Characters', () {
    late BladeLexer lexer;

    test('Tab characters in directive expressions', () {
      lexer = BladeLexer('@if(\t\$condition\t)');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('\t'));
    });

    test('Tabs for indentation with directives', () {
      lexer = BladeLexer('\t@if(\$x)\n\t\t<p>Content</p>\n\t@endif');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);

      // Tabs in text content should be preserved
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.any((t) => t.value.contains('\t')), isTrue);
    });

    test('Mixed spaces and tabs', () {
      lexer = BladeLexer('@foreach(\t \$items \t as \$item)');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveForeach), isTrue);

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      // Expression should contain both spaces and tabs
      expect(expressionTokens.first.value.length, greaterThan(0));
    });
  });

  group('Whitespace - Vertical Tabs and Form Feeds', () {
    late BladeLexer lexer;

    test('Vertical tab (U+000B) in text', () {
      final vt = '\u000B';
      lexer = BladeLexer('<p>Line1${vt}Line2</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains(vt));
    });

    test('Form feed (U+000C) in text', () {
      final ff = '\u000C';
      lexer = BladeLexer('<p>Page1${ff}Page2</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains(ff));
    });

    test('Multiple special whitespace characters', () {
      final vt = '\u000B';
      final ff = '\u000C';
      lexer = BladeLexer("{{ 'Test$vt${ff}Content' }}");
      final tokens = lexer.tokenize();

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(vt));
      expect(expressionTokens.first.value, contains(ff));
    });
  });

  group('Whitespace - Non-Breaking Spaces', () {
    late BladeLexer lexer;

    test('Non-breaking space (U+00A0) in text', () {
      final nbsp = '\u00A0';
      lexer = BladeLexer('<p>Word1${nbsp}Word2</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains(nbsp));
    });

    test('Non-breaking space in directive expression', () {
      final nbsp = '\u00A0';
      lexer = BladeLexer("@if(\$text == 'Hello${nbsp}World')");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(nbsp));
    });

    test('Non-breaking space in HTML attribute', () {
      final nbsp = '\u00A0';
      lexer = BladeLexer(
        '<div title="Value${nbsp}with${nbsp}nbsp">Content</div>',
      );
      final tokens = lexer.tokenize();

      final attributeValueTokens = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attributeValueTokens.any((t) => t.value.contains(nbsp)), isTrue);
    });
  });

  group('Whitespace - Zero-Width Spaces', () {
    late BladeLexer lexer;

    test('Zero-width space (U+200B) in text', () {
      final zwsp = '\u200B';
      lexer = BladeLexer('<p>Before${zwsp}After</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join('');
      expect(combinedText, contains(zwsp));
    });

    test('Zero-width space in directive expression', () {
      final zwsp = '\u200B';
      lexer = BladeLexer("{{ 'Test${zwsp}Value' }}");
      final tokens = lexer.tokenize();

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(zwsp));
    });

    test('Zero-width non-breaking space (U+FEFF)', () {
      // U+FEFF is also used as BOM
      final zwnbsp = '\uFEFF';
      lexer = BladeLexer("{{ '${zwnbsp}Content' }}");
      final tokens = lexer.tokenize();

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
    });
  });

  group('Whitespace - Mixed Line Endings', () {
    late BladeLexer lexer;

    test('LF line endings (Unix)', () {
      lexer = BladeLexer('@if(\$x)\n<p>Line 1</p>\n<p>Line 2</p>\n@endif');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);

      // Check line numbers are calculated correctly
      final endifToken = tokens.firstWhere(
        (t) => t.type == TokenType.directiveEndif,
      );
      expect(endifToken.startLine, equals(4));
    });

    test('CRLF line endings (Windows)', () {
      lexer = BladeLexer(
        '@if(\$x)\r\n<p>Line 1</p>\r\n<p>Line 2</p>\r\n@endif',
      );
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);

      // Check line numbers are calculated correctly
      final endifToken = tokens.firstWhere(
        (t) => t.type == TokenType.directiveEndif,
      );
      expect(endifToken.startLine, equals(4));
    });

    test('CR line endings (old Mac)', () {
      lexer = BladeLexer('@if(\$x)\r<p>Line 1</p>\r<p>Line 2</p>\r@endif');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);
    });

    test('Mixed line endings in same file', () {
      // Mix of LF, CRLF, and CR
      lexer = BladeLexer(
        '@if(\$a)\n<p>LF</p>\r\n<p>CRLF</p>\r<p>CR</p>\n@endif',
      );
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);

      // Should handle all line ending types
      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens.length, greaterThan(0));
    });
  });

  group('Whitespace - Trailing and Leading', () {
    late BladeLexer lexer;

    test('Trailing whitespace in attributes', () {
      lexer = BladeLexer('<div class="test   ">Content</div>');
      final tokens = lexer.tokenize();

      final attributeValueTokens = tokens
          .where((t) => t.type == TokenType.attributeValue)
          .toList();
      expect(attributeValueTokens, isNotEmpty);
      // Trailing spaces should be preserved in attribute value
      expect(attributeValueTokens.first.value, endsWith('   '));
    });

    test('Leading whitespace in echo expressions', () {
      lexer = BladeLexer('{{   \$variable }}');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      // Leading spaces should be preserved
      expect(expressionTokens.first.value, startsWith('   '));
    });

    test('Trailing whitespace in echo expressions', () {
      lexer = BladeLexer('{{ \$variable   }}');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      // Trailing spaces should be preserved
      expect(expressionTokens.first.value, endsWith('   '));
    });

    test('Whitespace-only text nodes', () {
      lexer = BladeLexer('<div>   </div>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      // Should have text token with only whitespace
      expect(
        textTokens.any((t) => t.value.trim().isEmpty && t.value.isNotEmpty),
        isTrue,
      );
    });

    test('Multiple consecutive whitespace types', () {
      final nbsp = '\u00A0';
      final zwsp = '\u200B';
      lexer = BladeLexer("{{ ' \t$nbsp${zwsp}test' }}");
      final tokens = lexer.tokenize();

      final expressionTokens = tokens
          .where((t) => t.type == TokenType.expression)
          .toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(' '));
      expect(expressionTokens.first.value, contains('\t'));
      expect(expressionTokens.first.value, contains(nbsp));
      expect(expressionTokens.first.value, contains(zwsp));
    });
  });
}
