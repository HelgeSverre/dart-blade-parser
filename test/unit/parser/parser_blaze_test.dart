import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

/// Tests for Livewire Blaze directive support.
/// @blaze is an inline/standalone directive (no closing tag).
/// @unblaze/@endunblaze is a paired block directive.
void main() {
  late BladeParser parser;

  setUp(() {
    parser = BladeParser();
  });

  group('@blaze directive', () {
    test('bare @blaze (no parentheses)', () {
      final result = parser.parse('''@blaze

<button {{ \$attributes }}>
    {{ \$slot }}
</button>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('blaze'));
      expect(directive.expression, isNull);
      expect(directive.children, isEmpty);
    });

    test('@blaze with fold: true', () {
      final result = parser.parse('@blaze(fold: true)\n\n<div>content</div>');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('blaze'));
      expect(directive.expression, contains('fold: true'));
      expect(directive.children, isEmpty);
    });

    test('@blaze with memo: true', () {
      final result = parser.parse('@blaze(memo: true)\n\n<div>x</div>');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('blaze'));
      expect(directive.expression, contains('memo: true'));
    });

    test('@blaze with multiple parameters', () {
      final result = parser.parse(
          "@blaze(fold: true, safe: ['type'], unsafe: ['required'])");
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('blaze'));
      expect(directive.expression, contains('fold: true'));
      expect(directive.expression, contains('safe:'));
      expect(directive.expression, contains('unsafe:'));
    });

    test('@blaze does not consume following directives', () {
      final result = parser.parse('''@blaze

@props([
    'type' => 'button',
])

@php
\$classes = 'btn';
@endphp

<button class="{{ \$classes }}">{{ \$slot }}</button>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      expect(directives.where((d) => d.name == 'blaze'), hasLength(1));
      expect(directives.where((d) => d.name == 'props'), hasLength(1));
      expect(directives.where((d) => d.name == 'php'), hasLength(1));
    });

    test('@blaze at top of component file (real-world FluxUI pattern)', () {
      final result = parser.parse('''@blaze(fold: true)

{{-- Credit: Heroicons (https://heroicons.com) --}}

@props([
    'variant' => 'outline',
])

@php
\$classes = Flux::classes('shrink-0');
@endphp

<svg {{ \$attributes->class(\$classes) }} xmlns="http://www.w3.org/2000/svg">
    <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
</svg>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      expect(directives.first.name, equals('blaze'));
      expect(directives.first.expression, contains('fold: true'));
    });
  });

  group('@unblaze / @endunblaze directive', () {
    test('basic @unblaze block', () {
      final result = parser.parse('''@unblaze(scope: ['name' => \$name])
    @if (\$errors->has(\$scope['name']))
        {{ \$errors->first(\$scope['name']) }}
    @endif
@endunblaze''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('unblaze'));
      expect(directive.expression, contains('scope:'));
      expect(directive.children, isNotEmpty);
    });

    test('@unblaze inside component with @blaze', () {
      final result = parser.parse('''@blaze(fold: true)

@props(['name', 'label'])

<div>
    <label>{{ \$label }}</label>
    <input name="{{ \$name }}">

    @unblaze(scope: ['name' => \$name])
        @if (\$errors->has(\$scope['name']))
            {{ \$errors->first(\$scope['name']) }}
        @endif
    @endunblaze
</div>''');
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directives =
          result.ast!.children.whereType<DirectiveNode>().toList();
      expect(directives.where((d) => d.name == 'blaze'), hasLength(1));
    });

    test('@unblaze with multiple scope variables', () {
      final result = parser.parse(
          "@unblaze(scope: ['field' => \$field, 'label' => \$label])\n"
          "    <span>{{ \$scope['field'] }}</span>\n"
          "@endunblaze");
      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);

      final directive =
          result.ast!.children.whereType<DirectiveNode>().first;
      expect(directive.name, equals('unblaze'));
    });

    test('unclosed @unblaze produces error', () {
      final result = parser.parse('''@unblaze(scope: ['x' => \$x])
    <p>content</p>''');
      expect(result.ast, isNotNull);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first.message, contains('Unclosed'));
    });
  });
}
