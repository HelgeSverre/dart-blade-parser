import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

/// Tests for Blade directives (@class, @style, etc.) used inside HTML tags.
/// These directives are valid Blade attribute directives and should NOT be
/// treated as Alpine.js shorthand events.
void main() {
  group('Blade attribute directives inside HTML tags', () {
    test('@class inside HTML tag is lexed as directive, not Alpine shorthand',
        () {
      final lexer = BladeLexer('<html @class([\'dark\' => true])>');
      final tokens = lexer.tokenize();

      // Should have a directiveClass token, NOT alpineShorthandOn
      expect(
        tokens.any((t) => t.type == TokenType.directiveClass),
        isTrue,
        reason: '@class in HTML tag should be recognized as Blade directive',
      );
      expect(
        tokens.any((t) => t.type == TokenType.alpineShorthandOn),
        isFalse,
        reason: '@class should not be treated as Alpine.js shorthand',
      );
    });

    test('@class expression is properly captured', () {
      final lexer = BladeLexer('<div @class([\'active\' => \$isActive])>');
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveClass),
        isTrue,
      );
      // The expression should be captured
      expect(
        tokens.any(
          (t) => t.type == TokenType.expression && t.value.contains('active'),
        ),
        isTrue,
        reason: '@class expression should be captured',
      );
    });

    test('@style inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<div @style([\'color: red\' => \$isError])>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveStyle),
        isTrue,
        reason: '@style should be recognized as Blade directive',
      );
      expect(
        tokens.any((t) => t.type == TokenType.alpineShorthandOn),
        isFalse,
      );
    });

    test('@checked inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<input type="checkbox" @checked(\$isChecked)>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveChecked),
        isTrue,
        reason: '@checked should be recognized as Blade directive',
      );
    });

    test('@disabled inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<button @disabled(\$isDisabled)>Submit</button>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveDisabled),
        isTrue,
        reason: '@disabled should be recognized as Blade directive',
      );
    });

    test('@selected inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<option @selected(\$isSelected)>Option</option>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveSelected),
        isTrue,
        reason: '@selected should be recognized as Blade directive',
      );
    });

    test('@readonly inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<input @readonly(\$isReadonly)>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveReadonly),
        isTrue,
        reason: '@readonly should be recognized as Blade directive',
      );
    });

    test('@required inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<input @required(\$isRequired)>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveRequired),
        isTrue,
        reason: '@required should be recognized as Blade directive',
      );
    });

    test('@class with complex expression preserves content', () {
      final lexer = BladeLexer(
        '<html lang="en" @class([\'dark\' => (\$appearance ?? \'system\') == \'dark\'])>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveClass),
        isTrue,
        reason: '@class should be a directive',
      );
      // Expression should contain the full conditional
      final expr = tokens.firstWhere(
        (t) => t.type == TokenType.expression && t.value.contains('appearance'),
        orElse: () => throw StateError('No expression token found'),
      );
      expect(expr.value, contains('dark'));
      expect(expr.value, contains('system'));
    });

    test(
        'Alpine.js @click is still treated as shorthand when not a known directive',
        () {
      final lexer = BladeLexer('<button @click="toggle">Save</button>');
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.alpineShorthandOn),
        isTrue,
        reason: '@click should still be treated as Alpine.js shorthand',
      );
    });

    test('@class and Alpine @click coexist in same tag', () {
      final lexer = BladeLexer(
        '<div @class([\'active\']) @click="toggle">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == TokenType.directiveClass),
        isTrue,
        reason: '@class should be a Blade directive',
      );
      expect(
        tokens.any((t) => t.type == TokenType.alpineShorthandOn),
        isTrue,
        reason: '@click should be Alpine.js shorthand',
      );
    });
  });
}
