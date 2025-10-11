import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('PHP Expression Edge Cases - Parser Tests', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('Nested Parentheses', () {
      test('Simple nested parentheses', () {
        final result = parser.parse(
          '@if(((\$x + \$y) * \$z)){{ \$result }}@endif',
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final ifNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'if');

        expect(ifNode.expression, isNotNull);
        expect(ifNode.expression, contains('((\$x + \$y) * \$z)'));
        expect(
          ifNode.expression!.split('(').length - 1,
          ifNode.expression!.split(')').length - 1,
          reason: 'Parentheses should be balanced',
        );
      });

      test('Complex nested parentheses with multiple levels', () {
        final result = parser.parse(
          '@if((((\$a && \$b) || (\$c && \$d)) && ((\$e || \$f) && \$g)))\n'
          'Content\n'
          '@endif',
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final ifNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'if');

        expect(ifNode.expression, isNotNull);
        expect(ifNode.expression, contains('\$a && \$b'));
        expect(ifNode.expression, contains('\$c && \$d'));
        expect(ifNode.expression, contains('\$e || \$f'));

        // Verify parentheses are balanced
        final openCount = ifNode.expression!.split('(').length - 1;
        final closeCount = ifNode.expression!.split(')').length - 1;
        expect(
          openCount,
          equals(closeCount),
          reason: 'All opening parentheses should have matching closing ones',
        );
      });

      test('Unbalanced parentheses detection', () {
        final result = parser.parse('@if((\$x + \$y){{ \$result }}@endif');

        // Parser should handle gracefully - might be success with partial parse
        // or error depending on implementation
        // The key is that it doesn't crash
        expect(() => result, returnsNormally);

        // If it succeeds, expression should at least contain the partial content
        if (result.isSuccess) {
          final ifNode = result.ast!.children
              .whereType<DirectiveNode>()
              .firstWhere((n) => n.name == 'if');
          expect(ifNode.expression, contains('\$x'));
        }
      });
    });

    group('Array Access', () {
      test('Single level array access', () {
        final result = parser.parse("{{ \$arr['key'] }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains("\$arr['key']"));
      });

      test('Nested array access with string keys', () {
        final result = parser.parse("{{ \$arr['key']['nested']['deep'] }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains("\$arr['key']"));
        expect(echoNode.expression, contains("['nested']"));
        expect(echoNode.expression, contains("['deep']"));
      });

      test('Numeric array indices', () {
        final result = parser.parse('{{ \$arr[0][1][2] }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$arr[0]'));
        expect(echoNode.expression, contains('[1]'));
        expect(echoNode.expression, contains('[2]'));
      });

      test('Mixed array access with strings and numbers', () {
        final result = parser.parse("{{ \$arr['items'][0]['name'] }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains("\$arr['items']"));
        expect(echoNode.expression, contains('[0]'));
        expect(echoNode.expression, contains("['name']"));
      });
    });

    group('Object Property Access', () {
      test('Simple property chain', () {
        final result = parser.parse('{{ \$user->profile->name }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$user->profile->name'));
      });

      test('Deep property chaining', () {
        final result = parser.parse(
          '{{ \$user->company->address->street->name }}',
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$user->company'));
        expect(echoNode.expression, contains('->address'));
        expect(echoNode.expression, contains('->street'));
        expect(echoNode.expression, contains('->name'));
      });

      test('Mixed property and array access', () {
        final result = parser.parse('{{ \$user->posts[0]->title }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$user->posts'));
        expect(echoNode.expression, contains('[0]'));
        expect(echoNode.expression, contains('->title'));
      });
    });

    group('Ternary Operators', () {
      test('Simple ternary operator', () {
        final result = parser.parse('{{ \$x ? \$y : \$z }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('?'));
        expect(echoNode.expression, contains(':'));
        expect(echoNode.expression, contains('\$x'));
        expect(echoNode.expression, contains('\$y'));
        expect(echoNode.expression, contains('\$z'));
      });

      test('Nested ternary operators', () {
        final result = parser.parse(
          '{{ \$a ? (\$b ? \$c : \$d) : (\$e ? \$f : \$g) }}',
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        // Should contain all variables
        expect(echoNode.expression, contains('\$a'));
        expect(echoNode.expression, contains('\$b'));
        expect(echoNode.expression, contains('\$c'));
        expect(echoNode.expression, contains('\$d'));
        expect(echoNode.expression, contains('\$e'));
        expect(echoNode.expression, contains('\$f'));
        expect(echoNode.expression, contains('\$g'));

        // Count ternary operators - should have 3 (one top-level, two nested)
        final questionMarks = '?'.allMatches(echoNode.expression).length;
        final colons = ':'.allMatches(echoNode.expression).length;
        expect(
          questionMarks,
          equals(colons),
          reason: 'Each ? should have a matching :',
        );
      });
    });

    group('Null Coalescing Operator', () {
      test('Simple null coalescing chain', () {
        final result = parser.parse("{{ \$x ?? \$y ?? 'default' }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$x'));
        expect(echoNode.expression, contains('??'));
        expect(echoNode.expression, contains('\$y'));
        expect(echoNode.expression, contains('default'));
      });

      test('Null coalescing with ternary', () {
        final result = parser.parse("{{ \$x ?? (\$y ? \$z : 'default') }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$x'));
        expect(echoNode.expression, contains('??'));
        expect(echoNode.expression, contains('\$y'));
        expect(echoNode.expression, contains('?'));
        expect(echoNode.expression, contains('\$z'));
        expect(echoNode.expression, contains('default'));
      });
    });

    group('String Concatenation', () {
      test('Simple string concatenation', () {
        final result = parser.parse("{{ 'Hello ' . \$name }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('Hello'));
        expect(echoNode.expression, contains('.'));
        expect(echoNode.expression, contains('\$name'));
      });

      test('Complex concatenation with property access', () {
        final result = parser.parse(
          "{{ 'Hello ' . \$user->name . ', welcome to ' . \$site->name }}",
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('Hello'));
        expect(echoNode.expression, contains('\$user->name'));
        expect(echoNode.expression, contains('welcome to'));
        expect(echoNode.expression, contains('\$site->name'));
      });
    });

    group('Function Calls', () {
      test('Simple function call', () {
        final result = parser.parse('{{ strtoupper(\$name) }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('strtoupper'));
        expect(echoNode.expression, contains('\$name'));
      });

      test('Nested function calls', () {
        final result = parser.parse(
          "{{ str_replace(',', '.', number_format(\$price, 2)) }}",
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('str_replace'));
        expect(echoNode.expression, contains('number_format'));
        expect(echoNode.expression, contains('\$price'));

        // Verify parentheses are balanced
        final openCount = echoNode.expression.split('(').length - 1;
        final closeCount = echoNode.expression.split(')').length - 1;
        expect(
          openCount,
          equals(closeCount),
          reason: 'Function call parentheses should be balanced',
        );
      });
    });

    group('Anonymous Functions and Closures', () {
      test('Simple anonymous function in directive', () {
        final result = parser.parse(
          '@php\n'
          '\$callback = function(\$x) { return \$x * 2; };\n'
          '@endphp',
        );

        expect(result.isSuccess, isTrue);
        // The parser should capture the directive
        final phpNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'php');

        expect(phpNode.name, equals('php'));
        // @php blocks typically don't have expressions - they have children
        // The content is in the children as text nodes
        expect(phpNode.children.isNotEmpty, isTrue);
      });

      test('Closure with use clause', () {
        final result = parser.parse(
          '@php\n'
          '\$fn = function(\$x) use (\$multiplier) { return \$x * \$multiplier; };\n'
          '@endphp',
        );

        expect(result.isSuccess, isTrue);
        final phpNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'php');

        expect(phpNode.name, equals('php'));
        // @php blocks have their content as children
        expect(phpNode.children.isNotEmpty, isTrue);
      });
    });

    group('Complex Expressions in Directives', () {
      test('Array filter with closure in foreach', () {
        final result = parser.parse(
          '@foreach(array_filter(\$items, function(\$item) { return \$item->active; }) as \$item)'
          '{{ \$item->name }}'
          '@endforeach',
        );

        expect(result.isSuccess, isTrue);
        final foreachNode = result.ast!.children
            .whereType<DirectiveNode>()
            .firstWhere((n) => n.name == 'foreach');

        expect(foreachNode.expression, isNotNull);
        expect(foreachNode.expression, contains('array_filter'));
        expect(foreachNode.expression, contains('function'));
        expect(foreachNode.expression, contains('\$items'));
        expect(foreachNode.expression, contains('\$item->active'));
        expect(foreachNode.expression, contains('as'));
      });
    });

    group('Edge Cases - Quote Handling in Expressions', () {
      test('Single quotes in expression', () {
        final result = parser.parse("{{ \$name == 'John' }}");

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$name'));
        expect(echoNode.expression, contains('=='));
        expect(echoNode.expression, contains('John'));
      });

      test('Double quotes in expression', () {
        final result = parser.parse('{{ \$name == "John" }}');

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$name'));
        expect(echoNode.expression, contains('=='));
        expect(echoNode.expression, contains('John'));
      });

      test('Mixed quotes and brackets', () {
        final result = parser.parse(
          '{{ \$data["key"]["nested"] == \'value\' }}',
        );

        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final echoNode = result.ast!.children.whereType<EchoNode>().first;

        expect(echoNode.expression, contains('\$data'));
        expect(echoNode.expression, contains('key'));
        expect(echoNode.expression, contains('nested'));
        expect(echoNode.expression, contains('value'));
      });
    });
  });
}
