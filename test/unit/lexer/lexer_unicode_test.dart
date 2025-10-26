import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Comprehensive edge case tests for Unicode handling in the lexer
/// Tests emoji, RTL text, combining characters, surrogate pairs, and mixed scripts
void main() {
  group('Unicode - Emoji Tests', () {
    late BladeLexer lexer;

    test('Emoji in directive conditions', () {
      lexer = BladeLexer("@if(\$emoji == '😀')");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('😀'));
    });

    test('Emoji in echo statements', () {
      lexer = BladeLexer("{{ '🎉 Success!' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('🎉'));
    });

    test('Multiple emoji in text', () {
      lexer = BladeLexer('<p>😀😁😂🤣😃</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join();
      expect(combinedText, contains('😀'));
      expect(combinedText, contains('😂'));
      expect(combinedText, contains('😃'));
    });

    test('Emoji with skin tone modifiers', () {
      lexer = BladeLexer("{{ '👋🏽' }}");
      final tokens = lexer.tokenize();

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('👋🏽'));
    });
  });

  group('Unicode - RTL Text Tests', () {
    late BladeLexer lexer;

    test('Arabic text in directives', () {
      lexer = BladeLexer("@if(\$lang == 'مرحبا')");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('مرحبا'));
    });

    test('Hebrew text in echo', () {
      lexer = BladeLexer("{{ 'שלום' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('שלום'));
    });

    test('Mixed LTR and RTL text', () {
      lexer = BladeLexer('<p>Hello مرحبا שלום World</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join();
      expect(combinedText, contains('Hello'));
      expect(combinedText, contains('مرحبا'));
      expect(combinedText, contains('שלום'));
      expect(combinedText, contains('World'));
    });
  });

  group('Unicode - Zero-Width Characters', () {
    late BladeLexer lexer;

    test('Zero-Width Joiner (ZWJ) in text', () {
      // ZWJ is U+200D, used to combine emoji
      const zwj = '\u200D';
      lexer = BladeLexer("{{ '👨$zwj👩$zwj👧' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(zwj));
    });

    test('Zero-Width Non-Joiner (ZWNJ) in text', () {
      // ZWNJ is U+200C, used in some languages like Persian
      const zwnj = '\u200C';
      lexer = BladeLexer("{{ 'می$zwnjخواهم' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains(zwnj));
    });

    test('Zero-Width Space (U+200B) in attributes', () {
      const zws = '\u200B';
      lexer = BladeLexer('<div data-value="test${zws}value">Content</div>');
      final tokens = lexer.tokenize();

      final attributeValueTokens =
          tokens.where((t) => t.type == TokenType.attributeValue).toList();
      expect(attributeValueTokens, isNotEmpty);
      expect(attributeValueTokens.any((t) => t.value.contains(zws)), isTrue);
    });
  });

  group('Unicode - Combining Diacritics', () {
    late BladeLexer lexer;

    test('Combining diacritics in variable names', () {
      // Note: Most languages don't allow combining marks in identifiers,
      // but we should handle them in strings
      lexer = BladeLexer("{{ 'café' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('café'));
    });

    test('Vietnamese with multiple diacritics', () {
      lexer = BladeLexer("{{ 'Tiếng Việt' }}");
      final tokens = lexer.tokenize();

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('Tiếng'));
      expect(expressionTokens.first.value, contains('Việt'));
    });
  });

  group('Unicode - Surrogate Pairs', () {
    late BladeLexer lexer;

    test('Emoji as surrogate pairs', () {
      // Emoji beyond BMP are represented as surrogate pairs
      lexer = BladeLexer("{{ '𝕳𝖊𝖑𝖑𝖔' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value.isNotEmpty, isTrue);
    });

    test('Mathematical Alphanumeric Symbols', () {
      // These are in the Supplementary Multilingual Plane
      lexer = BladeLexer("{{ '𝒜𝒷𝒸' }}");
      final tokens = lexer.tokenize();

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value.isNotEmpty, isTrue);
    });
  });

  group('Unicode - BOM and Special Markers', () {
    late BladeLexer lexer;

    test('BOM (Byte Order Mark) at start', () {
      // BOM is U+FEFF
      const bom = '\uFEFF';
      lexer = BladeLexer('$bom@if(\$x)');
      final tokens = lexer.tokenize();

      // BOM should be treated as whitespace or text, directive should still be recognized
      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
    });

    test('BOM in middle of content', () {
      const bom = '\uFEFF';
      lexer = BladeLexer('<p>Hello${bom}World</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      expect(textTokens, isNotEmpty);
    });
  });

  group('Unicode - Mixed Scripts', () {
    late BladeLexer lexer;

    test('Latin + Cyrillic + CJK mixed', () {
      lexer = BladeLexer("{{ 'Hello Привет 你好 こんにちは' }}");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.echoOpen), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('Hello'));
      expect(expressionTokens.first.value, contains('Привет'));
      expect(expressionTokens.first.value, contains('你好'));
      expect(expressionTokens.first.value, contains('こんにちは'));
    });

    test('Mixed scripts in HTML content', () {
      lexer = BladeLexer('<p>English Español 中文 日本語 한국어 العربية עברית</p>');
      final tokens = lexer.tokenize();

      final textTokens = tokens.where((t) => t.type == TokenType.text).toList();
      final combinedText = textTokens.map((t) => t.value).join();
      expect(combinedText, contains('English'));
      expect(combinedText, contains('Español'));
      expect(combinedText, contains('中文'));
      expect(combinedText, contains('日本語'));
      expect(combinedText, contains('한국어'));
      expect(combinedText, contains('العربية'));
      expect(combinedText, contains('עברית'));
    });

    test('Mixed scripts in directive expressions', () {
      lexer = BladeLexer("@if(\$lang == '中文' || \$lang == 'Русский')");
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);

      final expressionTokens =
          tokens.where((t) => t.type == TokenType.expression).toList();
      expect(expressionTokens.length, equals(1));
      expect(expressionTokens.first.value, contains('中文'));
      expect(expressionTokens.first.value, contains('Русский'));
    });
  });
}
