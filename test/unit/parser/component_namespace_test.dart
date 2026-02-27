import 'package:test/test.dart';
import 'package:blade_parser/blade_parser.dart';

void main() {
  group('Component namespace support (<x-package::component>)', () {
    late BladeParser parser;

    setUp(() {
      parser = BladeParser();
    });

    group('self-closing namespaced components', () {
      test('parses <x-nightshade::calendar /> with namespace', () {
        final result = parser.parse('<x-nightshade::calendar />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('nightshade::calendar'));
        expect(comp.isSelfClosing, isTrue);
      });

      test('parses <x-dashboard::panel /> with namespace', () {
        final result = parser.parse('<x-dashboard::panel />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('dashboard::panel'));
        expect(comp.isSelfClosing, isTrue);
      });

      test('parses <x-package::nested.component /> with namespace and dot',
          () {
        final result = parser.parse('<x-package::nested.component />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('package::nested.component'));
        expect(comp.isSelfClosing, isTrue);
      });
    });

    group('namespaced components with children', () {
      test('parses opening/closing pair with namespace', () {
        final result = parser.parse(
            '<x-nightshade::layout>content</x-nightshade::layout>');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('nightshade::layout'));
        expect(comp.isSelfClosing, isFalse);
        expect(comp.slots.containsKey('default'), isTrue);
        expect(comp.slots['default']!.children, isNotEmpty);
      });

      test('parses namespaced component with attributes', () {
        final result = parser.parse(
            '<x-mail::button url="https://example.com">Click</x-mail::button>');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('mail::button'));
        expect(comp.isSelfClosing, isFalse);
      });
    });

    group('nested component names with dots', () {
      test('parses <x-accordion.item /> with dot separator', () {
        final result = parser.parse('<x-accordion.item />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('accordion.item'));
        expect(comp.isSelfClosing, isTrue);
      });

      test('parses deeply nested <x-forms.fields.input /> with multiple dots',
          () {
        final result = parser.parse('<x-forms.fields.input />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('forms.fields.input'));
        expect(comp.isSelfClosing, isTrue);
      });

      test('parses <x-namespace::deep.nested.component />', () {
        final result =
            parser.parse('<x-namespace::deep.nested.component />');
        expect(result.isSuccess, isTrue);
        expect(result.errors, isEmpty);

        final comp = result.ast!.children.whereType<ComponentNode>().first;
        expect(comp.name, equals('namespace::deep.nested.component'));
        expect(comp.isSelfClosing, isTrue);
      });
    });
  });
}
