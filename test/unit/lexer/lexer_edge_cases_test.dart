import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Lexer Edge Cases (from research.md)', () {
    late BladeLexer lexer;

    test('Email address @ handling (user@example.com)', () {
      lexer = BladeLexer('Contact us at user@example.com for support');
      final tokens = lexer.tokenize();

      // Email should be treated as text, not a directive
      expect(tokens.any((t) => t.value.contains('user@example.com')), isTrue);
      expect(
          tokens.any((t) => t.type.toString().contains('directive')), isFalse);
    });

    test('@verbatim with {{ }} inside', () {
      lexer = BladeLexer('@verbatim\n{{ notAnEcho }}\n@endverbatim');
      final tokens = lexer.tokenize();

      // Find verbatim directive
      final verbatimTokens = tokens
          .where((t) =>
              t.type == TokenType.directiveVerbatim ||
              t.type == TokenType.directiveEndverbatim)
          .toList();

      expect(verbatimTokens.length,
          greaterThanOrEqualTo(2)); // @verbatim and @endverbatim

      // Content inside verbatim should be text, not echo tokens
      final hasEchoToken = tokens.any(
          (t) => t.type == TokenType.echoOpen || t.type == TokenType.echoClose);
      expect(hasEchoToken, isFalse);
    });

    test('Blade comments with content', () {
      lexer = BladeLexer('{{-- This is a comment --}}');
      final tokens = lexer.tokenize();

      final commentTokens =
          tokens.where((t) => t.type == TokenType.bladeComment).toList();
      expect(commentTokens.length, equals(1));
      expect(commentTokens.first.value, contains('This is a comment'));
    });

    test('Alpine.js @ vs Blade @ disambiguation', () {
      // Blade directive at start of line
      lexer = BladeLexer('@if(\$condition)');
      var tokens = lexer.tokenize();
      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      // Alpine.js @click in attribute context (would need HTML parsing)
      // For now, this is recognized as text
      lexer = BladeLexer('<button @click="toggle">Click</button>');
      tokens = lexer.tokenize();
      // In current implementation, this would be text or component tokens
      expect(tokens, isNotEmpty);
    });

    test('UTF-8 characters', () {
      lexer = BladeLexer("{{ 'Héllo Wörld 你好' }}");
      final tokens = lexer.tokenize();

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('Héllo'));
      expect(expressionTokens.first.value, contains('你好'));
    });

    test('CRLF line endings', () {
      final templateLF = "@if(\$x)\n  <p>Test</p>\n@endif";
      final templateCRLF = "@if(\$x)\r\n  <p>Test</p>\r\n@endif";

      final lexerLF = BladeLexer(templateLF);
      final lexerCRLF = BladeLexer(templateCRLF);

      final tokensLF = lexerLF.tokenize();
      final tokensCRLF = lexerCRLF.tokenize();

      // Should produce same token types
      expect(tokensLF.map((t) => t.type).toList(),
          equals(tokensCRLF.map((t) => t.type).toList()));

      // Line numbers should be correct
      final endifLF =
          tokensLF.firstWhere((t) => t.type == TokenType.directiveEndif);
      final endifCRLF =
          tokensCRLF.firstWhere((t) => t.type == TokenType.directiveEndif);

      expect(endifLF.startLine, equals(endifCRLF.startLine));
    });

    test('Ternary with "or" keyword edge case', () {
      lexer = BladeLexer("{{ \$x ? 'or' : 'other' }}");
      final tokens = lexer.tokenize();

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains("'or'"));
    });

    test('Component with multiple attributes', () {
      lexer = BladeLexer('<x-alert type="error" dismissible>Message</x-alert>');
      final tokens = lexer.tokenize();

      // Should have component open and close tokens
      expect(tokens.any((t) => t.type == TokenType.componentTagOpen), isTrue);
      expect(tokens.any((t) => t.type == TokenType.componentTagClose), isTrue);
    });

    test('Nested directives (20 levels)', () {
      final nested = List.generate(20, (i) => '@if(\$x$i)').join('\n') +
          '\n<p>Deep</p>\n' +
          List.generate(20, (_) => '@endif').join('\n');

      lexer = BladeLexer(nested);
      final tokens = lexer.tokenize();

      final ifTokens =
          tokens.where((t) => t.type == TokenType.directiveIf).toList();
      final endifTokens =
          tokens.where((t) => t.type == TokenType.directiveEndif).toList();

      expect(ifTokens.length, equals(20));
      expect(endifTokens.length, equals(20));
    });

    test('Self-closing component', () {
      lexer = BladeLexer('<x-icon name="star" />');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.componentTagOpen), isTrue);
      expect(tokens.any((t) => t.type == TokenType.componentSelfClose), isTrue);
    });

    test('Multiple echo types', () {
      lexer = BladeLexer('{{ \$escaped }} {!! \$raw !!} {{{ \$legacy }}}');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);
      expect(tokens.any((t) => t.type == TokenType.rawEchoOpen), isTrue);
      expect(tokens.any((t) => t.type == TokenType.legacyEchoOpen), isTrue);
    });

    test('Inline directive with condition', () {
      lexer = BladeLexer('@continue(\$user->type == 1)');
      final tokens = lexer.tokenize();

      final continueTokens =
          tokens.where((t) => t.type == TokenType.directiveContinue).toList();
      expect(continueTokens.length, equals(1));

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('->type'));
    });
  });
}
