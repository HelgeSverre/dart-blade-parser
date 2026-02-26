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
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.directiveClass));
      expect(types, isNot(contains(TokenType.alpineShorthandOn)));
    });

    test('@class expression is properly captured with correct value', () {
      final lexer = BladeLexer('<div @class([\'active\' => \$isActive])>');
      final tokens = lexer.tokenize();

      final classIdx =
          tokens.indexWhere((t) => t.type == TokenType.directiveClass);
      expect(classIdx, greaterThanOrEqualTo(0));
      expect(tokens[classIdx].value, equals('@class'));

      // Expression token should immediately follow the directive
      expect(tokens[classIdx + 1].type, equals(TokenType.expression));
      expect(
        tokens[classIdx + 1].value,
        equals("(['active' => \$isActive])"),
      );
    });

    test('@style inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<div @style([\'color: red\' => \$isError])>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.directiveStyle));
      expect(types, isNot(contains(TokenType.alpineShorthandOn)));

      final styleToken =
          tokens.firstWhere((t) => t.type == TokenType.directiveStyle);
      expect(styleToken.value, equals('@style'));
    });

    test('@checked inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<input type="checkbox" @checked(\$isChecked)>',
      );
      final tokens = lexer.tokenize();

      final checkedToken =
          tokens.firstWhere((t) => t.type == TokenType.directiveChecked);
      expect(checkedToken.value, equals('@checked'));

      final checkedIdx = tokens.indexOf(checkedToken);
      expect(tokens[checkedIdx + 1].type, equals(TokenType.expression));
      expect(tokens[checkedIdx + 1].value, equals('(\$isChecked)'));
    });

    test('@disabled inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<button @disabled(\$isDisabled)>Submit</button>',
      );
      final tokens = lexer.tokenize();

      final token =
          tokens.firstWhere((t) => t.type == TokenType.directiveDisabled);
      expect(token.value, equals('@disabled'));
    });

    test('@selected inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer(
        '<option @selected(\$isSelected)>Option</option>',
      );
      final tokens = lexer.tokenize();

      final token =
          tokens.firstWhere((t) => t.type == TokenType.directiveSelected);
      expect(token.value, equals('@selected'));
    });

    test('@readonly inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer('<input @readonly(\$isReadonly)>');
      final tokens = lexer.tokenize();

      final token =
          tokens.firstWhere((t) => t.type == TokenType.directiveReadonly);
      expect(token.value, equals('@readonly'));
    });

    test('@required inside HTML tag is lexed as directive', () {
      final lexer = BladeLexer('<input @required(\$isRequired)>');
      final tokens = lexer.tokenize();

      final token =
          tokens.firstWhere((t) => t.type == TokenType.directiveRequired);
      expect(token.value, equals('@required'));
    });

    test('@class with complex expression preserves full value', () {
      final lexer = BladeLexer(
        '<html lang="en" @class([\'dark\' => (\$appearance ?? \'system\') == \'dark\'])>',
      );
      final tokens = lexer.tokenize();

      final classIdx =
          tokens.indexWhere((t) => t.type == TokenType.directiveClass);
      expect(classIdx, greaterThanOrEqualTo(0));

      final expr = tokens[classIdx + 1];
      expect(expr.type, equals(TokenType.expression));
      expect(
        expr.value,
        equals("(['dark' => (\$appearance ?? 'system') == 'dark'])"),
      );
    });

    test(
        'Alpine.js @click is still treated as shorthand when not a known directive',
        () {
      final lexer = BladeLexer('<button @click="toggle">Save</button>');
      final tokens = lexer.tokenize();

      final clickToken =
          tokens.firstWhere((t) => t.type == TokenType.alpineShorthandOn);
      expect(clickToken.value, equals('@click'));
    });

    test('@class and Alpine @click coexist in same tag', () {
      final lexer = BladeLexer(
        '<div @class([\'active\']) @click="toggle">',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.directiveClass));
      expect(types, contains(TokenType.alpineShorthandOn));

      // Verify order: @class comes before @click
      final classIdx =
          tokens.indexWhere((t) => t.type == TokenType.directiveClass);
      final clickIdx =
          tokens.indexWhere((t) => t.type == TokenType.alpineShorthandOn);
      expect(classIdx, lessThan(clickIdx));
    });
  });

  group('Structural Blade directives inside HTML tags', () {
    test('@if inside HTML tag is lexed as directive token', () {
      final lexer = BladeLexer(
        '<div @if(\$closeable) @click="close" @endif>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      // @if and @endif should be proper directive tokens
      expect(types, contains(TokenType.directiveIf));
      expect(types, contains(TokenType.directiveEndif));
      // @click between @if/@endif should still be Alpine shorthand
      expect(types, contains(TokenType.alpineShorthandOn));

      // Verify @if has its expression captured
      final ifIdx =
          tokens.indexWhere((t) => t.type == TokenType.directiveIf);
      expect(tokens[ifIdx + 1].type, equals(TokenType.expression));
      expect(tokens[ifIdx + 1].value, contains('\$closeable'));
    });

    test('conditional attributes with @if parse without errors', () {
      const input = '''<div
    x-show="show"
    class="fixed inset-0"
    @if(\$closeable)
        @click="show = false"
    @endif
></div>''';

      final parser = BladeParser();
      final result = parser.parse(input);

      expect(result.errors, isEmpty,
          reason: '@if inside HTML tag should not cause parse errors');
    });

    test('complex component with conditional attributes formats correctly', () {
      const input = '''<button
    wire:click="addToCart({{ \$product->id }})"
    class="btn btn-primary"
    @if (\$product->stock === 0) disabled @endif
>
    Add to Cart
</button>''';

      final formatter = BladeFormatter();
      expect(() => formatter.format(input), returnsNormally,
          reason: '@if inside button tag should not crash formatter');
    });

    test('@class is attribute directive and @if is structural directive', () {
      final lexer = BladeLexer(
        '<div @class([\'active\']) @if(\$show) x-show="true" @endif>',
      );
      final tokens = lexer.tokenize();
      final types = tokens.map((t) => t.type).toList();

      expect(types, contains(TokenType.directiveClass));
      expect(types, contains(TokenType.directiveIf));
      expect(types, contains(TokenType.directiveEndif));
    });

    test('tagHead is populated when directives are present', () {
      const input = '<div class="base" @if(\$x) disabled @endif>';
      final parser = BladeParser();
      final result = parser.parse(input);
      final div = result.ast!.children.first as HtmlElementNode;

      expect(div.tagHead, isNotEmpty);
      // Should have: class attr, @if directive, disabled attr, @endif directive
      expect(div.tagHead.length, equals(4));
      expect(div.tagHead[0], isA<TagHeadAttribute>());
      expect((div.tagHead[0] as TagHeadAttribute).name, equals('class'));
      expect(div.tagHead[1], isA<TagHeadDirective>());
      expect((div.tagHead[1] as TagHeadDirective).name, equals('if'));
      expect(div.tagHead[2], isA<TagHeadAttribute>());
      expect((div.tagHead[2] as TagHeadAttribute).name, equals('disabled'));
      expect(div.tagHead[3], isA<TagHeadDirective>());
      expect((div.tagHead[3] as TagHeadDirective).name, equals('endif'));
    });

    test('tagHead is empty when no directives are present', () {
      const input = '<div class="base" id="el">';
      final parser = BladeParser();
      final result = parser.parse(input);
      final div = result.ast!.children.first as HtmlElementNode;

      expect(div.tagHead, isEmpty);
      expect(div.attributes, hasLength(2));
    });
  });
}
