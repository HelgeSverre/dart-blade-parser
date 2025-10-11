import 'package:blade_parser/blade_parser.dart';
import 'package:test/test.dart';

void main() {
  group('_isDirectiveContext behaviour', () {
    test('@if at line start is recognized as directive', () {
      final lexer = BladeLexer('@if(\$condition)');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
    });

    test('leading whitespace before directive still treated as directive', () {
      final lexer = BladeLexer('    @unless(false)');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveUnless), isTrue);
    });

    test('email address is treated as plain text', () {
      final lexer = BladeLexer('Contact user@example.com today');
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });

    test('Alpine shorthand @click stays an attribute', () {
      final lexer = BladeLexer('<button @click="toggle">Save</button>');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.alpineShorthandOn), isTrue);
      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });
  });

  group('Enhanced _isDirectiveContext - Quoted attribute values', () {
    test('@ inside double-quoted attribute value is treated as text', () {
      final lexer = BladeLexer(
        '<input type="email" placeholder="user@example.com">',
      );
      final tokens = lexer.tokenize();

      // Should not have any directive tokens
      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      // Should have the attribute value with @ as text
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.attributeValue &&
              t.value == 'user@example.com',
        ),
        isTrue,
      );
    });

    test('@ inside single-quoted attribute value is treated as text', () {
      final lexer = BladeLexer(
        "<input type='email' placeholder='admin@site.org'>",
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.attributeValue && t.value == 'admin@site.org',
        ),
        isTrue,
      );
    });

    test('@ in Alpine.js :class with object syntax stays as text', () {
      final lexer = BladeLexer(
        '<div :class="{\'bg-red\': user@admin, \'bg-blue\': !user@admin}">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      expect(
        tokens.any((t) => t.type == TokenType.alpineShorthandBind),
        isTrue,
      );
    });

    test('Escaped quote in attribute value with @ is handled correctly', () {
      final lexer = BladeLexer(
        '<input value="Say \\"hello\\" to user@example.com">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });

    test('@ in data-* attribute with JSON stays as text', () {
      final lexer = BladeLexer(
        '<div data-user=\'{"email": "test@example.com", "id": 123}\'>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });
  });

  group('Enhanced _isDirectiveContext - Raw text elements', () {
    test('@ inside <script> tag is treated as literal JavaScript', () {
      final lexer = BladeLexer(
        '<script>const email = "admin@site.com"; alert(email);</script>',
      );
      final tokens = lexer.tokenize();

      // Should not trigger directive parsing
      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      // The @ should be part of text content
      expect(
        tokens.any(
          (t) => t.type == TokenType.text && t.value.contains('admin@site.com'),
        ),
        isTrue,
      );
    });

    test('@ inside <style> tag is treated as literal CSS', () {
      final lexer = BladeLexer(
        '<style>@media screen { body { color: red; } }</style>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      expect(
        tokens.any(
          (t) => t.type == TokenType.text && t.value.contains('@media'),
        ),
        isTrue,
      );
    });

    test('@ inside <textarea> is treated as text content', () {
      final lexer = BladeLexer(
        '<textarea>Contact: user@example.com</textarea>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });

    test('@keyframes in <style> tag should not trigger directive', () {
      final lexer = BladeLexer(
        '<style>@keyframes fade { from { opacity: 0; } to { opacity: 1; } }</style>',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });
  });

  group('Enhanced _isDirectiveContext - Complex quote scenarios', () {
    test('Multiple attributes with @ in values are all treated as text', () {
      final lexer = BladeLexer(
        '<input data-email="user@site.com" placeholder="admin@example.org">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.attributeValue && t.value == 'user@site.com',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.attributeValue &&
              t.value == 'admin@example.org',
        ),
        isTrue,
      );
    });

    test('@ in wire:model with @ modifiers stays in attribute context', () {
      final lexer = BladeLexer(
        '<input wire:model.debounce.500ms="email@field">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
      expect(tokens.any((t) => t.type == TokenType.livewireModel), isTrue);
    });

    test(
      '@ after tag close but before next tag is recognized as directive',
      () {
        final lexer = BladeLexer('<div>Test</div>@if(true)');
        final tokens = lexer.tokenize();

        expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      },
    );

    test('Tag with < in quoted attribute value does not confuse parser', () {
      final lexer = BladeLexer(
        '<input value="a < b" data-test="x@example.com">',
      );
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });
  });

  group('Enhanced _isDirectiveContext - Edge cases', () {
    test('@ immediately after closing > should be recognized as directive', () {
      final lexer = BladeLexer('<div>content</div>@foreach(\$items as \$item)');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveForeach), isTrue);
    });

    test('@ in unquoted attribute value (should be rare but handle it)', () {
      // Note: unquoted attributes with @ are technically invalid HTML
      // but we should handle them gracefully
      final lexer = BladeLexer('<div data-value=test@here>');
      final tokens = lexer.tokenize();

      // The @ in unquoted attribute should be treated as part of the value
      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });

    test('@ in Alpine.js x-on:@custom-event should stay in attribute', () {
      final lexer = BladeLexer('<div x-on:@custom-event="handler()">');
      final tokens = lexer.tokenize();

      expect(
        tokens.where((t) => t.type.toString().contains('directive')),
        isEmpty,
      );
    });

    test('@ before tag opener is recognized as directive', () {
      final lexer = BladeLexer('@if(true)<div>content</div>');
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
    });

    test('Mixed: directive before tag with @ in attribute', () {
      final lexer = BladeLexer(
        '@if(\$show)<input placeholder="user@example.com">@endif',
      );
      final tokens = lexer.tokenize();

      expect(tokens.any((t) => t.type == TokenType.directiveIf), isTrue);
      expect(tokens.any((t) => t.type == TokenType.directiveEndif), isTrue);
      expect(
        tokens.any(
          (t) =>
              t.type == TokenType.attributeValue &&
              t.value == 'user@example.com',
        ),
        isTrue,
      );
    });
  });
}
