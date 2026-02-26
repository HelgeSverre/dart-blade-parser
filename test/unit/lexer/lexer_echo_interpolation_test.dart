import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Echo with PHP string interpolation', () {
    late BladeLexer lexer;

    test(r'handles {$var} inside double-quoted string', () {
      // This is the specific bug from docs/todo.md:
      // {{ Arr::get($foo, "key.{$bar}") }}
      lexer = BladeLexer('{{ Arr::get(\$foo, "key.{\$bar}") }}');
      final tokens = lexer.tokenize();

      // Should have: echoOpen, expression, echoClose, eof
      final echoOpen =
          tokens.where((t) => t.type == TokenType.echoOpen).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();
      final expressions =
          tokens.where((t) => t.type == TokenType.expression).toList();
      final errors = tokens.where((t) => t.type == TokenType.error).toList();

      expect(errors, isEmpty, reason: 'Should not produce any errors');
      expect(echoOpen, hasLength(1), reason: 'Should have one echo open');
      expect(echoClose, hasLength(1), reason: 'Should have one echo close');
      expect(expressions, hasLength(1), reason: 'Should have one expression');
      expect(
        expressions.first.value,
        contains('Arr::get'),
        reason: 'Expression should contain the function call',
      );
    });

    test(r'handles simple {$name} in echo', () {
      lexer = BladeLexer('{{ "hello {\$name}" }}');
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();

      expect(errors, isEmpty);
      expect(echoClose, hasLength(1));
    });

    test(r'handles multiple {$var} interpolations', () {
      lexer = BladeLexer('{{ "{\$first} and {\$second}" }}');
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();

      expect(errors, isEmpty);
      expect(echoClose, hasLength(1));
    });

    test('handles nested braces in PHP expressions', () {
      // e.g. {{ $obj->{$prop} }}
      lexer = BladeLexer('{{ \$obj->{\$prop} }}');
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();

      expect(errors, isEmpty);
      expect(echoClose, hasLength(1));
    });

    test('handles PHP array/object syntax with braces', () {
      // {{ json_encode(compact('a', 'b')) }} - no braces, should still work
      lexer = BladeLexer("{{ json_encode(compact('a', 'b')) }}");
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      expect(errors, isEmpty);
    });

    test(r'handles echo with {$key} in array index', () {
      // {{ $array["{$key}"] }}
      lexer = BladeLexer('{{ \$array["{\$key}"] }}');
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();

      expect(errors, isEmpty);
      expect(echoClose, hasLength(1));
    });

    test('still correctly handles simple echo without braces', () {
      lexer = BladeLexer('{{ \$user->name }}');
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();
      final expressions =
          tokens.where((t) => t.type == TokenType.expression).toList();

      expect(errors, isEmpty);
      expect(echoClose, hasLength(1));
      expect(expressions.first.value.trim(), equals('\$user->name'));
    });

    test('handles multiple echo statements with interpolation', () {
      lexer = BladeLexer(
        '<p>{{ "{\$greeting}" }}</p><p>{{ "{\$farewell}" }}</p>',
      );
      final tokens = lexer.tokenize();

      final errors = tokens.where((t) => t.type == TokenType.error).toList();
      final echoOpen =
          tokens.where((t) => t.type == TokenType.echoOpen).toList();
      final echoClose =
          tokens.where((t) => t.type == TokenType.echoClose).toList();

      expect(errors, isEmpty);
      expect(echoOpen, hasLength(2));
      expect(echoClose, hasLength(2));
    });
  });
}
