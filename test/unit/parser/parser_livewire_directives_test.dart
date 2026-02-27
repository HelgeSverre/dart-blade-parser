import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Livewire and Volt directive parsing', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('@livewire inline directive', () {
      test('parses @livewire with component name', () {
        final result = parser.parse("@livewire('counter')");
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('livewire'));
        expect(directive.expression, contains('counter'));
      });

      test('parses @livewire with component name and params', () {
        final result = parser.parse(
            "@livewire('user-profile', ['user' => \$user])");
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('livewire'));
        expect(directive.expression, contains('user-profile'));
      });

      test('parses @livewire with key parameter', () {
        final result =
            parser.parse("@livewire('counter', key(\$id))");
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('livewire'));
      });

      test('parses @livewire with lazy parameter', () {
        final result =
            parser.parse("@livewire('revenue', lazy: true)");
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('livewire'));
      });

      test('@livewire is an inline directive (no closing tag)', () {
        final result = parser.parse('''
<div>
    @livewire('notifications')
    <p>Other content</p>
</div>
''');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final div = result.ast!.children.whereType<HtmlElementNode>().first;
        final directives =
            div.children.whereType<DirectiveNode>().toList();
        expect(directives.length, equals(1));
        expect(directives.first.name, equals('livewire'));
        // Should have sibling content after it, not nested inside
        final pTags = div.children.whereType<HtmlElementNode>().toList();
        expect(pTags, isNotEmpty);
      });
    });

    group('@volt / @endvolt paired directive', () {
      test('parses @volt with content', () {
        final result = parser.parse('''@volt
<div>
    <h1>Counter: {{ \$count }}</h1>
    <button wire:click="increment">+</button>
</div>
@endvolt''');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('volt'));
        expect(directive.children, isNotEmpty);
      });

      test('parses @volt with name argument', () {
        final result = parser.parse('''@volt('counter')
<div>
    <span>{{ \$count }}</span>
</div>
@endvolt''');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final directive =
            result.ast!.children.whereType<DirectiveNode>().first;
        expect(directive.name, equals('volt'));
        expect(directive.expression, contains('counter'));
      });

      test('@endvolt closes the @volt block', () {
        final result = parser.parse('''<div>
    @volt
        <span>volt content</span>
    @endvolt
    <p>after volt</p>
</div>''');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final div = result.ast!.children.whereType<HtmlElementNode>().first;
        final voltDirective =
            div.children.whereType<DirectiveNode>().firstWhere(
                  (d) => d.name == 'volt',
                );
        expect(voltDirective.children, isNotEmpty);

        // <p> should be sibling of @volt, not child
        final pTags = div.children
            .whereType<HtmlElementNode>()
            .where((e) => e.tagName == 'p')
            .toList();
        expect(pTags, isNotEmpty);
      });

      test('unclosed @volt reports error', () {
        final result = parser.parse('''@volt
<div>content</div>
''');
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.any((e) => e.message.contains('volt')),
          isTrue,
        );
      });
    });

    group('lexer produces correct token types', () {
      test('@livewire produces directiveLivewire token', () {
        final lexer = BladeLexer("@livewire('counter')");
        final tokens = lexer.tokenize();

        final directiveToken = tokens.firstWhere(
          (t) => t.type == TokenType.directiveLivewire,
          orElse: () => throw StateError(
              'No directiveLivewire token found in: ${tokens.map((t) => "${t.type}:${t.value}").toList()}'),
        );
        expect(directiveToken.type, equals(TokenType.directiveLivewire));
      });

      test('@volt produces directiveVolt token', () {
        final lexer = BladeLexer('@volt');
        final tokens = lexer.tokenize();

        final directiveToken = tokens.firstWhere(
          (t) => t.type == TokenType.directiveVolt,
          orElse: () => throw StateError(
              'No directiveVolt token found in: ${tokens.map((t) => "${t.type}:${t.value}").toList()}'),
        );
        expect(directiveToken.type, equals(TokenType.directiveVolt));
      });

      test('@endvolt produces directiveEndvolt token', () {
        final lexer = BladeLexer('@endvolt');
        final tokens = lexer.tokenize();

        final directiveToken = tokens.firstWhere(
          (t) => t.type == TokenType.directiveEndvolt,
          orElse: () => throw StateError(
              'No directiveEndvolt token found in: ${tokens.map((t) => "${t.type}:${t.value}").toList()}'),
        );
        expect(directiveToken.type, equals(TokenType.directiveEndvolt));
      });
    });
  });
}
